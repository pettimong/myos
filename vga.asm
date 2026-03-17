; vga.asm
timer_count dw 0  ; カウント用変数

; --- 8bitの数値を2進数で描画する (例: 01101010) ---
; 入力: AL = 表示したい数値, DI = VRAMオフセット
draw_binary:
    pusha
    push es
    mov bx, 0xB800
    mov es, bx
    mov cx, 8           ; 8ビット分繰り返す

.loop:
    rol al, 1           ; 最上位ビットをキャリーフラグへ送り出しつつ回転
    jc .print_one       ; キャリーが1なら '1' を表示
    
    ; '0' を表示
    mov byte [es:di], '0'
    jmp .next
    
.print_one:
    mov byte [es:di], '1'
    
.next:
    mov byte [es:di+1], 0x0E ; 黄色属性
    add di, 2
    loop .loop

    pop es
    popa
    ret

; --- 新設: 数値を描画する関数 ---
; 入力: AX = 表示したい数値, DI = 表示開始のVRAMオフセット
draw_number:
    pusha
    push es
    mov bx, 0xB800
    mov es, bx
    
    mov bx, 10          ; 除数
    mov cx, 0           ; 桁数カウンタ

.loop_div:
    xor dx, dx
    div bx              ; AX / 10 (商はAX, 余りはDX)
    add dl, '0'         ; 余りをASCII文字に
    push dx             ; スタックに保存
    inc cx
    test ax, ax
    jnz .loop_div       ; 商が0になるまで繰り返す

.loop_print:
    pop ax              ; スタックから1桁取り出す
    mov [es:di], al     ; 文字を書き込む
    mov byte [es:di+1], 0x0E ; 属性（黄色）
    add di, 2
    loop .loop_print

    ; 残りの古い文字を消すための空白埋め（必要に応じて）
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07

    pop es
    popa
    ret

; 割り込みから呼ばれる描画関数
; タイマーカウントは内部で継続するが、表示は「Tries: X」に変更

draw_timer:
    pusha
    inc word [timer_count]
    call draw_tries
    popa
    ret

; --- Tries: X を画面右上(di=140)に描画する ---
; keyboard.asm からも呼べる独立関数
draw_tries:
    pusha
    push es
    push ds

    xor ax, ax
    mov ds, ax
    mov es, ax

    ; START_VAL が 0 のとき（ゲーム未開始）は表示しない
    cmp byte [START_VAL], 0
    je .dt_skip

    mov bx, 0xB800
    mov es, bx

    ; "Tries: " を di=140 から書く
    mov di, 140
    mov si, msg_tries
.dt_label:
    lodsb
    cmp al, 0
    je .dt_num
    mov [es:di], al
    mov byte [es:di+1], 0x07
    add di, 2
    jmp .dt_label

.dt_num:
    ; 残り回数を1桁で表示
    xor ax, ax
    mov ds, ax
    mov al, [TRIES_LEFT]
    add al, '0'
    mov [es:di], al
    mov byte [es:di+1], 0x0E   ; 黄色

.dt_skip:
    pop ds
    pop es
    popa
    ret

msg_tries db "Tries: ", 0

cursor_pos dw 0

clear_screen:
    pusha
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov word [cursor_pos], 0
    call update_cursor
    popa
    ret

print_vram:
    push ax
    push bx
    push dx
    push es
	push ds
    push si

	xor ax, ax
	mov ds, ax

    mov ax, 0xB800
    mov es, ax
    mov di, [cursor_pos]
.next_char:
    lodsb
    cmp al, 0
    je .vram_done
    cmp al, 10
    je .handle_lf
    cmp al, 13
    je .handle_cr
    mov [es:di], al
    mov byte [es:di+1], 0x07
    add di, 2
    jmp .next_char
.handle_cr:
    mov ax, di
    mov bl, 160
    div bl
    movzx bx, ah
    sub di, bx
    jmp .next_char
.handle_lf:
    add di, 160
    jmp .next_char
.vram_done:
    mov [cursor_pos], di 
    call update_cursor
	pop si
	pop ds
    pop es
    pop dx
    pop bx
    pop ax
    ret

update_cursor:
    push ax
    push dx
    push bx
    mov bx, [cursor_pos]
    shr bx, 1
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    mov al, 0x0E
    out dx, al
    inc dx
    mov al, bh
    out dx, al
    pop bx
    pop dx
    pop ax
    ret

do_backspace:
    push es
    push di
    push cx
    push bx
    push ax
    mov ax, 0xB800
    mov es, ax
    mov di, [cursor_pos]
    cmp di, 0
    je .done
    mov ax, di
    mov bl, 160
    div bl
    cmp ah, 0
    jne .normal_bs
.prev_line_scan:
    sub di, 2
    mov cx, 80
.scan_loop:
    cmp byte [es:di], ' '
    jne .found_char
    cmp cx, 1
    je .found_char
    sub di, 2
    loop .scan_loop
.found_char:
    cmp byte [es:di], ' '
    je .update
    add di, 2
    jmp .update
.normal_bs:
    sub di, 2
.update:
    mov [cursor_pos], di
    mov word [es:di], 0x0720
    call update_cursor
.done:
    pop ax
    pop bx
    pop cx
    pop di
    pop es
    ret

; print_prompt は削除（msg_prompt を keyboard.asm から除去したため）

; --- ラベル文字列をVRAMに書き込む ---
; 入力: SI = 文字列ポインタ, DI = VRAMオフセット
; 出力: DI = 書き込み後のオフセット（draw_binaryにそのまま渡せる）
; 注意: ES=0xB800 にセットしてから呼ぶこと
draw_label:
    push ax
.dl_loop:
    lodsb
    cmp al, 0
    je .dl_done
    mov [es:di], al
    mov byte [es:di+1], 0x07
    add di, 2
    jmp .dl_loop
.dl_done:
    pop ax
    ret

lbl_start   db "start:   ", 0
lbl_goal    db "goal:    ", 0
lbl_current db "current: ", 0
