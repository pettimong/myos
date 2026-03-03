; keyboard.asm
last_key db 0
msg_key db 0, 0, 0

; keyboard.asm の key_table 修正版
; 0x00, 0x01(Esc), 0x02('1')... 0x0E(BS)
key_table db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8
          db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 13, 0
          db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
          db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' '

get_key:
    in al, 0x60
    cmp al, [last_key]
    je .get_key_exit
    mov [last_key], al
    test al, 0x80
    jnz .get_key_exit

    push bx
    movzx bx, al
    mov al, [key_table + bx]
    cmp al, 0
    je .pop_done
    cmp al, 13
    je .is_enter
	cmp al, 8
	je .is_backspace

    mov [msg_key], al
    mov byte [msg_key + 1], 0
    mov si, msg_key
    call print_vram
    jmp .pop_done

.is_enter:
    mov word [msg_key], 0x0A0D
    mov byte [msg_key + 2], 0
    mov si, msg_key
    call print_vram
	jmp .pop_done

.is_backspace:
	call do_backspace
	jmp .pop_done

.pop_done:
    pop bx
.get_key_exit:
    ret
