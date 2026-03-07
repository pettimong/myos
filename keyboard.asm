; keyboard.asm
last_key db 0
msg_key  db 0, 0, 0

key_table:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '^' ; 0x00-0x0D
    db 0  ; 0x0E (Delete)
    db 9, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '@', '[', 13 ; 0x0F-0x1C
    db 0  ; 0x1D
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', ':', ']', 0
    db 0
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' '

get_key:
    in al, 0x60
    cmp al, [last_key]
    je .get_key_exit
    mov [last_key], al
    test al, 0x80
    jnz .get_key_exit

    push bx

    cmp al, 0x0E
    je .is_backspace

    movzx bx, al
    cmp bx, 0x3F
    ja .pop_done_simple

    mov al, [key_table + bx]
    cmp al, 0
    je .pop_done
    cmp al, 13
    je .is_enter

    ; 通常文字入力
    mov [msg_key], al
    mov byte [msg_key+1], 0
    mov si, msg_key
    call print_vram

    mov bx, [buffer_ptr]
    cmp bx, SHELL_BUFFER_SIZE
    jae .pop_done
    mov [SHELL_BUFFER_ADDR + bx], al
    inc word [buffer_ptr]
    jmp .pop_done

.is_enter:
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 0
    mov si, msg_newline
    call print_vram
    call check_command
    mov word [buffer_ptr], 0  ; バッファリセット
    mov si, msg_newline
    call print_vram
    jmp .pop_done

.is_backspace:
    ; --- ここがシェルの境界線 ---
    mov bx, [buffer_ptr]
    cmp bx, 0
    je .pop_done       ; バッファが0ならシステム出力を守るために戻らない

    call do_backspace 
    dec word [buffer_ptr]
    jmp .pop_done

.pop_done:
.pop_done_simple:
    pop bx
.get_key_exit:
    ret

check_command:
    pusha
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_hello
    mov cx, 5
    repe cmpsb
    jne .not_match
    cmp byte [si], 0
    jne .not_match
.match:
    mov si, msg_fine
    call print_vram
    jmp .done
.not_match:
    mov si, msg_unknown
    call print_vram
.done:
    popa
    ret

cmd_hello    db "hello", 0
msg_fine     db "Fine!", 0
msg_unknown  db "Unknown", 0
msg_newline  db 13, 10, 0
