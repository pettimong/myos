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

; --- プロンプト "> " を直接VRAMに書き込む ---
draw_prompt:
    push ax
    push es
    push di
    mov ax, 0xB800
    mov es, ax
    mov di, [cursor_pos]
    mov byte [es:di],   '>'
    mov byte [es:di+1], 0x07
    mov byte [es:di+2], ' '
    mov byte [es:di+3], 0x07
    add di, 4
    mov [cursor_pos], di
    call update_cursor
    pop di
    pop es
    pop ax
    ret

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

    ; --- ゲーム未開始時は 'g' のみ受け付ける ---
    push ax
    push ds
    xor ax, ax
    mov ds, ax
    cmp byte [START_VAL], 0
    pop ds
    pop ax
    jne .accept_key
    cmp al, 'g'
    je .accept_key
    jmp .pop_done

.accept_key:
.normal_input:
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
    mov word [buffer_ptr], 0
    call check_command
    jmp .pop_done

.is_backspace:
    mov bx, [buffer_ptr]
    cmp bx, 0
    je .pop_done

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
    push ds
    push es

    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 空打ちチェック
    mov si, SHELL_BUFFER_ADDR
    cmp byte [si], 0
    je .done

.try_g:
    mov si, SHELL_BUFFER_ADDR
    cmp byte [si], 'g'
    jne .try_xor

    mov ax, [timer_count]
    mov [START_VAL], al
    mov [CURRENT_VAL], al

    call generate_goal

    mov byte [TRIES_LEFT], 5

    call clear_screen

    ; ES=0xB800 をセットしてラベル+バイナリを描画
    push es
    mov ax, 0xB800
    mov es, ax

    mov di, 0
    mov si, lbl_start
    call draw_label
    mov al, [START_VAL]
    call draw_binary

    mov di, 160
    mov si, lbl_goal
    call draw_label
    mov al, [GOAL_VAL]
    call draw_binary

    pop es

    call draw_help

    mov word [cursor_pos], 320
    call update_cursor
    call draw_prompt
    jmp .done

.try_xor:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_xor_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_not

    mov al, [START_VAL]
    xor [CURRENT_VAL], al
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_not:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_not_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_shl

    not byte [CURRENT_VAL]
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_shl:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_shl_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_ror

    shl byte [CURRENT_VAL], 1
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_ror:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_ror_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_rol

    ror byte [CURRENT_VAL], 1
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_rol:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_rol_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_shr

    rol byte [CURRENT_VAL], 1
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_shr:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_shr_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_exit

    shr byte [CURRENT_VAL], 1
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_exit:
    ; "exit" → スタート画面に戻る（QEMUは終了しない）
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_exit
    mov cx, 4
    cld
    repe cmpsb
    jne .not_match
    cmp byte [si], 0
    jne .not_match
    jmp .go_to_start

.victory_early:
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_early_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_early_line

    push es
    mov ax, 0xB800
    mov es, ax
    mov di, 480
    mov si, lbl_current
    call draw_label
    mov al, [CURRENT_VAL]
    call draw_binary
    pop es

    jmp .victory

.show_result:
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_input_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_input_line

    push es
    mov ax, 0xB800
    mov es, ax
    mov di, 480
    mov si, lbl_current
    call draw_label
    mov al, [CURRENT_VAL]
    call draw_binary
    pop es

    mov word [cursor_pos], 320
    call update_cursor
    call draw_prompt

    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0

    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory
    jmp .done

.victory:
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_victory_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_victory_line

    mov word [cursor_pos], 640
    call update_cursor
    mov si, msg_win
    call print_vram

    mov byte [START_VAL], 0
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0
    jmp .done

.game_over:
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_gameover_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_gameover_line

    mov word [cursor_pos], 640
    call update_cursor
    mov si, msg_gameover
    call print_vram

    mov byte [START_VAL], 0
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0
    jmp .done

.go_to_start:
    ; スタート画面に戻る（exit コマンド / cls の共通処理）
    mov byte [START_VAL], 0
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0
    call clear_screen
    mov si, msg_title
    call print_vram
    mov si, msg_start
    call print_vram
    jmp .done

.not_match:
    cmp byte [START_VAL], 0
    je .done
    jmp .reset_input_only

.reset_input_only:
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_line_loop:
    mov byte [es:di], 0x20
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_line_loop

    mov word [cursor_pos], 320
    call update_cursor
    mov word [buffer_ptr], 0
    jmp .done

.done:
    pop es
    pop ds
    popa
    ret

cmd_exit     db "exit", 0

cmd_xor_str  db "xor", 0
cmd_not_str  db "not", 0
cmd_shl_str  db "shl", 0
cmd_shr_str  db "shr", 0
cmd_ror_str  db "ror", 0
cmd_rol_str  db "rol", 0
msg_win      db "=== YOU WIN! ===", 13, 10, "Press 'g' to start again.", 0
msg_gameover db "=== GAME OVER ===", 13, 10, "Press 'g' to try again.", 0

; --- コマンド説明を画面下部に描画 ---
; 行6(di=800)から固定表示。ゲーム開始時に一度だけ呼ぶ。
draw_help:
    pusha
    push ds
    push es
    xor ax, ax
    mov ds, ax
    mov ax, 0xB800
    mov es, ax

    ; 行8: タイトル行（2行分下げてWIN/GAMEOVERと被らないように）
    mov di, 1120
    mov si, msg_help_title
    call .write_line

    ; 行9: xor / not
    mov di, 1280
    mov si, msg_help_xor
    call .write_line

    ; 行10: shl / shr
    mov di, 1440
    mov si, msg_help_shift
    call .write_line

    ; 行11: ror / rol
    mov di, 1600
    mov si, msg_help_rotate
    call .write_line

    ; 行12: exit / g(giveup)
    mov di, 1760
    mov si, msg_help_misc
    call .write_line

    ; 行13: 空行（空けて視覚的に分離）

    ; 行14: ゲーム説明
    mov di, 2080
    mov si, msg_help_goal
    call .write_line

    pop es
    pop ds
    popa
    ret

.write_line:
    ; SI から NULL までを ES:DI に白色(0x07)で書き込む
    push ax
    push si
    push di
.wl_loop:
    lodsb
    cmp al, 0
    je .wl_done
    mov [es:di], al
    mov byte [es:di+1], 0x07
    add di, 2
    jmp .wl_loop
.wl_done:
    pop di
    pop si
    pop ax
    ret

msg_help_title  db "--- Commands ---", 0
msg_help_xor    db "xor: XOR with start value  |  not: Bitwise NOT", 0
msg_help_shift  db "shl: Shift left (x2)       |  shr: Shift right (div2)", 0
msg_help_rotate db "rol: Rotate left           |  ror: Rotate right", 0
msg_help_misc   db "g: New game / Give up      |  exit: Return to title", 0
msg_help_goal   db "Goal: Transform start value into goal value within 5 moves!", 0
