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
buffer_ptr   dw 0

%include "vga.asm"
%include "keyboard.asm"
