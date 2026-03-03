; vga.asm
cursor_pos dw 0

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
    push ax
    push di
    mov di, [cursor_pos]
    cmp di, 0
    je .done          ; 左端なら何もしない
    
    sub di, 2         ; 1文字分戻る
    mov [cursor_pos], di
    
    ; VRAM上の文字を消去（黒背景にスペース）
    mov ax, 0xB800
    mov es, ax
    mov word [es:di], 0x0720 ; 0x07(白) + 0x20(スペース)
    
    call update_cursor
.done:
    pop di
    pop ax
    ret
