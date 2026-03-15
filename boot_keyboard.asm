org 0x7C00
bits 16

start:
    cli

    ; -----------------------------
    ; セグメント初期化
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; -----------------------------
    ; シリアル初期化 (COM1 = 0x3F8)
    call serial_init

    ; -----------------------------
    ; PIC マスク解除（IRQ1有効化）
    in   al, 0x21
    and  al, 0xFD        ; 11111101b → IRQ1許可
    out  0x21, al

    ; -----------------------------
    ; INT9 ハンドラ登録
    mov word [9*4], keyboard_handler
    mov word [9*4+2], 0x0000

    sti

.hang:
    hlt
    jmp .hang

; =====================================
; INT9 ハンドラ（実IRQ版）
; =====================================
keyboard_handler:
    push ax
    push dx

    ; ★ 8042からスキャンコード取得
    in al, 0x60

    ; 16進表示
    call print_hex

    ; ★ PICへEOI送信
    mov al, 0x20
    out 0x20, al

    pop dx
    pop ax
    iret

; =====================================
; シリアル初期化
; =====================================
serial_init:
    mov dx, 0x3F8 + 1
    mov al, 0x00
    out dx, al

    mov dx, 0x3F8 + 3
    mov al, 0x80
    out dx, al

    mov dx, 0x3F8 + 0
    mov al, 0x03
    out dx, al

    mov dx, 0x3F8 + 1
    mov al, 0x00
    out dx, al

    mov dx, 0x3F8 + 3
    mov al, 0x03
    out dx, al

    mov dx, 0x3F8 + 2
    mov al, 0xC7
    out dx, al

    mov dx, 0x3F8 + 4
    mov al, 0x0B
    out dx, al

    ret

; =====================================
; ALを16進表示
; =====================================
print_hex:
    push ax
    push bx

    mov bl, al
    shr al, 4
    call print_nibble

    mov al, bl
    and al, 0x0F
    call print_nibble

    mov al, 13
    call serial_out
    mov al, 10
    call serial_out

    pop bx
    pop ax
    ret

print_nibble:
    cmp al, 9
    jbe .num
    add al, 7
.num:
    add al, '0'
    call serial_out
    ret

; =====================================
; AL保護済み serial_out
; =====================================
serial_out:
    push ax

.wait:
    mov dx, 0x3F8 + 5
    in al, dx
    test al, 0x20
    jz .wait

    pop ax
    mov dx, 0x3F8
    out dx, al
    ret

times 510-($-$$) db 0
dw 0xAA55
