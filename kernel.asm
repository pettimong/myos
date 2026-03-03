; kernel.asm
org 0x8000
bits 16

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; --- スタックの初期化 ---
    mov ss, ax          ; SS を 0 に設定
    mov sp, 0x7C00      ; SP を 0x7C00 に設定 (ブートセクタが使っていた場所の下など)
    sti                 ; スタック設定が終わってから割り込みを許可
 
    mov si, msg_vram
    call print_vram

main_loop:
    call get_key
    jmp main_loop

; ここで職人たちを呼び出す
%include "vga.asm"
%include "keyboard.asm"

msg_vram db "System Divided & Ready!", 13, 10, 0
