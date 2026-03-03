; kernel.asm
org 0x8000
bits 16

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov si, msg_vram
    call print_vram

main_loop:
    call get_key
    jmp main_loop

; ここで職人たちを呼び出す
%include "vga.asm"
%include "keyboard.asm"

msg_vram db "System Divided & Ready!", 13, 10, 0
