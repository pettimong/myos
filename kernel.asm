org 0x8000
bits 16

start:
    cli
    cld                 ; ★ 方向フラグを必ずクリア

    ; セグメント初期化
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 起動メッセージ表示
    mov si, msg
    call print_string

main_loop:
    call get_key
    jmp main_loop


; ----------------------------------
; BIOS キーボード入力 (int 16h)
; ----------------------------------
get_key:
    mov ah, 0x00
    int 0x16            ; キー待ち

    ; AL = ASCII
    ; AH = スキャンコード

    cmp al, 0
    je .done            ; 非ASCIIは無視

    call print_char

.done:
    ret


; ----------------------------------
; BIOS TTY 出力 (int 10h)
; ----------------------------------
print_char:
    push ax
    push bx

    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10

    pop bx
    pop ax
    ret


print_string:
.next:
    lodsb               ; AL ← [DS:SI], SI++
    cmp al, 0
    je .done
    call print_char
    jmp .next
.done:
    ret


; ----------------------------------
; データ
; ----------------------------------
msg db "BIOS keyboard mode ready",13,10,0
