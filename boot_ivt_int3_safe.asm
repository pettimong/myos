; boot_ivt_int3_safe.asm
; 16bit real mode ブートローダ
; IVT先頭16エントリをシリアルに出力
; INT3ハンドラでターミナルにメッセージ
; 安全な停止ループを追加（Ctrl+Cで終了可能）

org 0x7C00          ; ブートセクタロード位置

start:
    cli              ; 割り込み禁止

    ; -----------------------
    ; INT3ハンドラ登録（IVT[3]）
    mov ax, cs
    mov word [0x0E], ax       ; セグメント
    mov word [0x0C], int3_handler ; オフセット

    sti              ; 割り込み許可

    ; -----------------------
    ; IVT先頭16エントリをシリアル出力
    mov si, 0x0000
    mov cx, 16
print_loop:
    push cx
    mov ax, [si+2]    ; セグメント
    call print_hex16
    mov al, ':'
    call print_char_serial
    mov ax, [si]      ; オフセット
    call print_hex16
    call print_newline_serial
    add si, 4
    pop cx
    loop print_loop

    ; -----------------------
    ; INT3をテスト
    int 3

; -----------------------
; 安全停止ループ
halt_loop:
    cli
    hlt
    jmp halt_loop

; -----------------------
; INT3 ハンドラ
int3_handler:
    pusha
    mov si, msg
print_msg:
    lodsb
    cmp al, 0
    je done
    call print_char_serial
    jmp print_msg
done:
    popa
    iret

; -----------------------
; メッセージ
msg db "INT3 triggered! Hello terminal.",0

; -----------------------
; サブルーチン：16bit値を16進表示
; 入力: AX
print_hex16:
    push ax
    push cx
    mov cx, 4
    mov bx, ax
print_hex_loop:
    rol bx, 4
    mov dl, bl
    and dl, 0x0F
    cmp dl, 10
    jl .digit
    add dl, 'A' - 10
    jmp .out
.digit:
    add dl, '0'
.out:
    mov al, dl
    call print_char_serial
    loop print_hex_loop
    pop cx
    pop ax
    ret

; -----------------------
; サブルーチン：1文字をCOM1に出力
print_char_serial:
    mov dx, 0x3F8
    out dx, al      ; 送信バッファ待ちなし（学習用）
    ret

; -----------------------
; サブルーチン：改行を出力
print_newline_serial:
    mov al, 0x0D
    call print_char_serial
    mov al, 0x0A
    call print_char_serial
    ret

; -----------------------
times 510-($-$$) db 0
dw 0xAA55           ; ブート署名
