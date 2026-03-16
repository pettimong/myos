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
; DS/ESの状態に依存しない。cursor_posの位置に描画してカーソルを進める。
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
    add di, 4                   ; 2文字分進める
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

    cmp al, 'a'
    je .auto_add
    cmp al, 'x'
    je .auto_xor
    cmp al, 'n'
    je .auto_not
    cmp al, 's'
    je .auto_shl
    cmp al, 'r'
    je .auto_shr

    jmp .normal_input

.auto_add:
    mov si, cmd_add_str
    call print_vram
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 'a'
    mov byte [SHELL_BUFFER_ADDR + bx + 1], 'd'
    mov byte [SHELL_BUFFER_ADDR + bx + 2], 'd'
    add word [buffer_ptr], 3
    jmp .pop_done

.auto_xor:
    mov si, cmd_xor_str
    call print_vram
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 'x'
    mov byte [SHELL_BUFFER_ADDR + bx + 1], 'o'
    mov byte [SHELL_BUFFER_ADDR + bx + 2], 'r'
    add word [buffer_ptr], 3
    jmp .pop_done

.auto_not:
    mov si, cmd_not_str
    call print_vram
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 'n'
    mov byte [SHELL_BUFFER_ADDR + bx + 1], 'o'
    mov byte [SHELL_BUFFER_ADDR + bx + 2], 't'
    add word [buffer_ptr], 3
    jmp .pop_done

.auto_shl:
    mov si, cmd_shl_str
    call print_vram
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 's'
    mov byte [SHELL_BUFFER_ADDR + bx + 1], 'h'
    mov byte [SHELL_BUFFER_ADDR + bx + 2], 'l'
    add word [buffer_ptr], 3
    jmp .pop_done

.auto_shr:
    mov si, cmd_shr_str
    call print_vram
    mov bx, [buffer_ptr]
    mov byte [SHELL_BUFFER_ADDR + bx], 's'
    mov byte [SHELL_BUFFER_ADDR + bx + 1], 'h'
    mov byte [SHELL_BUFFER_ADDR + bx + 2], 'r'
    add word [buffer_ptr], 3
    jmp .pop_done

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

    ; -------------------------------------------------------
    ; DS=0, ES=0 に統一する
    ;
    ; repe cmpsb は DS:SI と ES:DI を比較する。
    ; SHELL_BUFFER_ADDR(0x9000) は物理アドレスそのままなので
    ; DS=0 のとき DS:0x9000 = 物理0x9000 で正しく届く。
    ; cmd_add_str 等は org 0x8000 のオフセット値なので
    ; ES=0 のとき ES:offset = 物理offset で正しく届く。
    ; -------------------------------------------------------
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 空打ちチェック（Enter だけ押した場合）
    mov si, SHELL_BUFFER_ADDR
    cmp byte [si], 0
    je .show_result

.try_g:
    mov si, SHELL_BUFFER_ADDR
    cmp byte [si], 'g'
    jne .try_add

    ; --- g コマンド: スタート値を設定してゴール値を生成 ---
    mov ax, [timer_count]
    mov [START_VAL], al
    mov [CURRENT_VAL], al

    call generate_goal      ; GOAL_VAL を6ステップのランダム演算で生成

    mov byte [TRIES_LEFT], 5    ; 残り回数をリセット

    call clear_screen

    mov al, [START_VAL]
    mov di, 0
    call draw_binary
    mov al, [GOAL_VAL]
    mov di, 160
    call draw_binary

    mov word [cursor_pos], 320
    call update_cursor
    call draw_prompt
    jmp .done

.try_add:
    ; repe cmpsb: DS:SI(バッファ) と ES:DI(コマンド文字列) を比較
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_add_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_xor

    inc byte [CURRENT_VAL]
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_xor:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_xor_str
    mov cx, 3
    cld
    repe cmpsb
    jne .try_not

    xor byte [CURRENT_VAL], 0x0F
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
    jne .try_shr

    shl byte [CURRENT_VAL], 1
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
    jne .try_cls

    shr byte [CURRENT_VAL], 1
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory_early
    dec byte [TRIES_LEFT]
    call draw_tries
    cmp byte [TRIES_LEFT], 0
    je .game_over
    jmp .show_result

.try_cls:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_cls
    mov cx, 3
    cld
    repe cmpsb
    jne .try_exit
    cmp byte [si], 0
    jne .try_exit
    jmp .match_cls

.try_exit:
    mov si, SHELL_BUFFER_ADDR
    mov di, cmd_exit
    mov cx, 4
    cld
    repe cmpsb
    jne .not_match
    cmp byte [si], 0
    jne .not_match
    call qemu_exit
    jmp .done

.victory_early:
    ; 最後の1手で正解した場合 — TRIES_LEFT を消費せずに勝利処理へ
    ; show_result の描画だけ先に行ってから victory へ飛ぶ
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_early_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_early_line

    mov al, [CURRENT_VAL]
    mov di, 480
    call draw_binary

    jmp .victory

.show_result:
    ; --- A. 入力行(3行目)を掃除 ---
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_input_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_input_line

    ; --- B. 演算結果(4行目)を描画 ---
    mov al, [CURRENT_VAL]
    mov di, 480
    call draw_binary

    ; --- C. カーソルを3行目に戻してプロンプト表示 ---
    mov word [cursor_pos], 320
    call update_cursor
    call draw_prompt

    ; --- D. バッファリセット ---
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0

    ; --- E. 勝利判定 ---
    mov al, [CURRENT_VAL]
    cmp al, [GOAL_VAL]
    je .victory
    jmp .done

.victory:
    ; 入力行(3行目)だけ掃除する（数値はそのまま残す）
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_victory_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_victory_line

    ; 勝利メッセージを5行目に表示
    mov word [cursor_pos], 640
    call update_cursor
    mov si, msg_win
    call print_vram

    mov byte [START_VAL], 0
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0
    jmp .done

.game_over:
    ; 入力行(3行目)を掃除
    mov ax, 0xB800
    mov es, ax
    mov di, 320
    mov cx, 80
.clear_gameover_line:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_gameover_line

    ; Game Over メッセージを5行目に表示
    mov word [cursor_pos], 640
    call update_cursor
    mov si, msg_gameover
    call print_vram

    mov byte [START_VAL], 0
    mov word [buffer_ptr], 0
    mov byte [SHELL_BUFFER_ADDR], 0
    jmp .done

.match_cls:
    call clear_screen
    mov si, msg_title
    call print_vram
    mov si, msg_start
    call print_vram
    jmp .done

.not_match:
    cmp byte [START_VAL], 0
    je .standard_unknown
    jmp .reset_input_only

.reset_input_only:
    ; ESを0xB800に設定してからVRAMに書き込む
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

.standard_unknown:
    mov si, msg_unknown
    call print_vram
    mov si, msg_newline
    call print_vram

.done:
    pop es
    pop ds
    popa
    ret

qemu_exit:
    mov ax, 0x00
    mov dx, 0xf4
    out dx, ax
    ret

cmd_hello    db "hello", 0
msg_fine     db "Fine!", 0
cmd_cls      db "cls", 0
msg_unknown  db "Unknown", 0
msg_newline  db 13, 10, 0
msg_prompt   db "> ", 0
cmd_exit     db "exit", 0

cmd_add_str  db "add", 0
cmd_xor_str  db "xor", 0
cmd_not_str  db "not", 0
cmd_shl_str  db "shl", 0
cmd_shr_str  db "shr", 0
msg_win      db "=== YOU WIN! ===", 13, 10, "Press 'g' to start again.", 0
msg_gameover db "=== GAME OVER ===", 13, 10, "Press 'g' to try again.", 0
