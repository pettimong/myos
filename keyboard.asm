; keyboard.asm
last_key db 0
msg_key  db 0, 0, 0

; 0x0E(BS)を8に、0x01(ESC)を27に配置
key_table db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8
          db 9, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 13, 0
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

    ; --- 通常文字の処理 ---
    mov [msg_key], al
    mov byte [msg_key+1], 0
    mov si, msg_key
    call print_vram         ; 1. 画面に文字を表示

    ; --- バッファへ保存 ---
    mov bx, [buffer_ptr]
    cmp bx, SHELL_BUFFER_SIZE
    jae .pop_done
    
    mov [SHELL_BUFFER_ADDR + bx], al  ; 2. メモリに保存
    
    ; --- デバッグ表示：読み直して確認 ---
    push ax
    mov al, [SHELL_BUFFER_ADDR + bx]
    mov ah, 0
    call print_hex          ; 3. メモリから読み直した値を表示
    pop ax
    
    inc word [buffer_ptr]
    jmp .pop_done

.is_enter:
    ; 1. バッファの末尾に0を書き込んで文字列を完成させる
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 0
    
    ; 2. 改行を表示
    mov si, msg_newline
    call print_vram
    
    ; 3. 【重要】バッファの中身を「復唱」させる
    ; 0x9000番地から0（終端）までを文字列として一気に表示します
    mov si, SHELL_BUFFER_ADDR
    call print_vram
    
    ; 4. ポインタをリセットして次の入力に備える
    mov word [buffer_ptr], 0 
    
    ; 5. 再び改行（見やすくするため）
    mov si, msg_newline
    call print_vram
    jmp .pop_done

.is_backspace:
    call do_backspace
    mov bx, [buffer_ptr]
    cmp bx, 0
    je .pop_done
    dec word [buffer_ptr]
    jmp .pop_done

.pop_done:
    pop bx
.get_key_exit:
    ret

msg_newline db 13, 10, 0
