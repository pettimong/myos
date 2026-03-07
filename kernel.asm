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

; --- 画面消去 (BIOS中断 0x10, AH=0x06 を使用) ---
    mov ax, 0x0600    ; AH=06h(スクロールアップ), AL=00h(全画面消去)
    mov bh, 0x07      ; 属性: 黒背景 / 白文字 (0x07)
    mov cx, 0x0000    ; 左上座標 (行:0, 列:0)
    mov dx, 0x184F    ; 右下座標 (行:24, 列:79) ※標準的な80x25画面
    int 0x10          ; BIOS呼び出し

    ; --- カーソル位置を左上(0,0)に戻す ---
    mov ah, 0x02      ; AH=02h(カーソル設定)
    mov bh, 0x00      ; ページ番号
    mov dx, 0x0000    ; DH=0(行), DL=0(列)
    int 0x10
    
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
