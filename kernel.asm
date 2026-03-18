; kernel.asm
org 0x8000
bits 16

; --- 定数定義 ---
SHELL_BUFFER_ADDR equ 0x9000
SHELL_BUFFER_SIZE equ 80

start:
    cli                 ; 割り込み禁止
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; スタックの設定
    mov ss, ax
    mov sp, 0x7C00

    ; --- IVTの書き換え (INT 0x08 = 0x0000:0x0020) ---
    mov word [es:0x0020], timer_handler ; オフセット
    mov word [es:0x0022], cs            ; セグメント
    
    sti                 ; 割り込み開始

    ; --- 画面初期化 (BIOS) ---
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10

    ; --- タイトル画面表示 ---
    mov si, msg_title
    call print_vram
    mov si, msg_start
    call print_vram

main_loop:
    call get_key
    jmp main_loop

; --- タイマー割り込みハンドラ ---
; BIOSへ飛ばさず、自前でEOIを出して復帰する最小構成

timer_handler:
    push ax
    push ds
    
    xor ax, ax          ; データセグメントを0に固定（変数アクセス用）
    mov ds, ax
    
    pusha               ; 全レジスタ保存
    call draw_timer     ; vga.asm内の描画処理
    popa
    
    ; PIC (割り込みコントローラ) に終了を通知 (EOI)
    mov al, 0x20
    out 0x20, al
    
    pop ds
    pop ax
    iret                ; 割り込みから復帰



; --- データ領域 ---
msg_title  db "=== Binary Puzzle Game ===", 13, 10, 0
msg_start  db "Hit 'g' key to start...", 13, 10, 0

old_timer_off dw 0
old_timer_seg dw 0

; 変数
START_VAL    db 0
CURRENT_VAL  db 0
GOAL_VAL     db 0
TRIES_LEFT   db 5       ; 残り回答数（初期値5）
buffer_ptr   dw 0
lcg_state    dw 0       ; LCG乱数の状態（generate_goal用）

; --- ゴール値生成関数 ---
; プレイヤーが使える命令のみを使ってゴール値を作る
; 使用命令: xor(START_VALと), not, shl, shr, ror, rol の6種
; 演算コード: 0=xor, 1=not, 2=shl, 3=shr, 4=ror, 5=rol
;
; 禁止パターン（同じ演算の連続 + 意味のない逆操作の連続）:
;   同じ演算の連続禁止（全6種）
;   shl→shr, shr→shl（打ち消し合い）禁止
;   ror→rol, rol→ror（打ち消し合い）禁止
;   not→not（打ち消し合い）は同じ演算連続禁止でカバー済み
generate_goal:
    pusha
    push ds
    xor ax, ax
    mov ds, ax

    ; LCG乱数の初期シードをタイマーから設定
    mov ax, [timer_count]
    mov [lcg_state], ax

    mov al, [START_VAL]     ; AL = 現在の計算値
    mov cl, 0xFF            ; CL = 前の演算コード（0xFF=無効）
    mov ch, 4               ; CH = 残りステップ数（4ステップ→5手以内で解ける）

.step_loop:
    cmp ch, 0
    je .step_done

.pick_op:
    ; LCG: state = state * 25173 + 13849  (mod 65536)
    mov ax, [lcg_state]
    mov bx, 25173
    mul bx                  ; DX:AX = ax * 25173
    add ax, 13849
    mov [lcg_state], ax
    ; AX mod 6 → BL = 演算コード (0=xor, 1=not, 2=shl, 3=shr, 4=ror, 5=rol)
    xor dx, dx
    mov bx, 6
    div bx                  ; AX=商, DX=余り(0〜5)
    mov bl, dl              ; BL = 今回の演算コード

    ; --- 禁止チェック ---
    ; 同じ演算の連続禁止
    cmp bl, cl
    je .pick_op

    ; shl(2)→shr(3) 禁止（打ち消し）
    cmp cl, 2
    jne .check_shr_shl
    cmp bl, 3
    je .pick_op
.check_shr_shl:
    ; shr(3)→shl(2) 禁止（打ち消し）
    cmp cl, 3
    jne .check_ror_rol
    cmp bl, 2
    je .pick_op
.check_ror_rol:
    ; ror(4)→rol(5) 禁止（打ち消し）
    cmp cl, 4
    jne .check_rol_ror
    cmp bl, 5
    je .pick_op
.check_rol_ror:
    ; rol(5)→ror(4) 禁止（打ち消し）
    cmp cl, 5
    jne .op_ok
    cmp bl, 4
    je .pick_op

.op_ok:
    mov cl, bl              ; prev_op を更新

    ; --- 演算実行 ---
    ; 0=xor(START_VALと), 1=not, 2=shl, 3=shr, 4=ror, 5=rol
    cmp bl, 0
    je .do_xor
    cmp bl, 1
    je .do_not
    cmp bl, 2
    je .do_shl
    cmp bl, 3
    je .do_shr
    cmp bl, 4
    je .do_ror
    ; bl=5: rol
    rol al, 1
    dec ch
    jmp .step_loop
.do_xor:
    ; プレイヤーのxorコマンドと同じ: START_VALとXOR
    push bx
    mov bl, [START_VAL]
    xor al, bl
    pop bx
    dec ch
    jmp .step_loop
.do_not:
    not al
    dec ch
    jmp .step_loop
.do_shl:
    shl al, 1
    dec ch
    jmp .step_loop
.do_shr:
    shr al, 1
    dec ch
    jmp .step_loop
.do_ror:
    ror al, 1
    dec ch
    jmp .step_loop

.step_done:
    mov [GOAL_VAL], al

    pop ds
    popa
    ret

%include "vga.asm"
%include "keyboard.asm"
