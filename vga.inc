bits 16

vga_putc:
    push ax
    push bx
    push es

    mov bx, [cursor]

    mov ax, 0xB800
    mov es, ax

    mov ah, 0x07      ; attribute
    mov [es:bx], ax

    add word [cursor], 2

    pop es
    pop bx
    pop ax
    ret

section .data
cursor dw 0
