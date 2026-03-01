org 0x7C00
bits 16

start:
    mov [BOOT_DRIVE], dl

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    call load_kernel

    ; ★ ここが最重要
    jmp 0x0000:0x8000

hang:
    hlt
    jmp hang

load_kernel:
    mov ah, 0x02
    mov al, 4          ; 読み込むセクタ数
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    mov bx, 0x8000
    int 0x13
    ret

BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xAA55
