; kernel.asm
org 0x8000
bits 16

; --- 定数定義 ---
SHELL_BUFFER_ADDR equ 0x9000  ; バッファの開始位置
SHELL_BUFFER_SIZE equ 80      ; 最大80文字

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; スタックの設定
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    mov si, msg_ready
    call print_vram

main_loop:
    call get_key
    jmp main_loop

%include "vga.asm"
%include "keyboard.asm"

; --- データ領域 ---
msg_ready  db "Memory Buffer Ready at 0x9000", 13, 10, 0
buffer_ptr dw 0  ; 現在バッファの何文字目に書き込むか
