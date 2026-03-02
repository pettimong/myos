org 0x8000
bits 16

start:
	
	; --- VRAM直接書き込みテスト ---
    mov ax, 0xB800      ; VRAMのセグメント開始地点
    mov es, ax          ; ESレジスタにセット
    
    mov al, 'A'         ; 表示したい文字
    mov ah, 0x0C        ; 属性：黒背景(0) + 明るい赤(C)
    
    mov [es:0], ax      ; 画面の左上（0番目）に書き込む！
    ; ---------------------------

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

    cmp al, 13
	jne .not_enter
	call print_char
	mov al, 10
	call print_char
    jmp .done            ; 非ASCIIは無視

.not_enter:
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
