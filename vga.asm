; vga.asm
cursor_pos dw 0

clear_screen:
    pusha
    mov ax, 0x0600    ; 全画面消去
    mov bh, 0x07      ; 白文字/黒背景
    mov cx, 0x0000    ; 左上
    mov dx, 0x184F    ; 右下
    int 0x10
    
    ; カーソル位置を0にリセット
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

    ; 現在の列位置をチェック
    mov ax, di
    mov bl, 160
    div bl
    cmp ah, 0
    jne .normal_bs

.prev_line_scan:
    ; 行頭にいるので1行上へ
    sub di, 2
    mov cx, 80
.scan_loop:
    cmp byte [es:di], ' '
    jne .found_char    ; 空白以外を見つけた
    cmp cx, 1
    je .found_char     ; 行頭まで来た
    sub di, 2
    loop .scan_loop
.found_char:
    ; 文字の直後を消去対象にする
    cmp byte [es:di], ' '
    je .update
    add di, 2
    jmp .update

.normal_bs:
    sub di, 2
.update:
    mov [cursor_pos], di
    mov word [es:di], 0x0720 ; 消去
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

