; vga.asm
timer_count dw 0  ; カウント用変数

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

draw_timer:
    pusha
    push es
    
    inc word [timer_count]

    ; 秒数の計算 (timer_count / 18)
    mov ax, [timer_count]
    xor dx, dx
    mov bx, 18
    div bx              ; AX = 秒数

    ; 画面右上の適当な位置 (例: 140バイト目あたりから) に表示
    mov di, 140         
    call draw_number

    pop es
    popa
    ret

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
    push di
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
    pop di
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

print_prompt:
    push si
    mov si, msg_prompt
    call print_vram
    pop si
    ret
