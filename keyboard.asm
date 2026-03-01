bits 16

%include "scan2ascii.inc"
%include "vga.inc"

irq1_handler:
    push ax
    push bx

    in al, 0x60

    test al, 0x80
    jnz done          ; releaseは無視

    xor bx, bx
    mov bl, al
    mov al, [scan_table + bx]

    cmp al, 0
    je done

    call vga_putc

done:
    mov al, 0x20
    out 0x20, al      ; EOI

    pop bx
    pop ax
    iret
