; boot_int3.asm
; 16bit real mode ブートローダ
; IVTの3番目(INT3)を自作ハンドラに書き換え
; INT3を実行するとターミナルにメッセージを出力

org 0x7C00          ; ブートセクタのロード位置

start:
    cli              ; 割り込み禁止

    ; -----------------------
    ; IVT[3] に自作ハンドラを登録
    mov ax, cs       ; ハンドラのセグメント
    mov word [0x0E], ax   ; IVT[3]セグメント（0x0E = 3*4+2）
    mov word [0x0C], int3_handler  ; IVT[3]オフセット（0x0C = 3*4）

    sti              ; 割り込み許可

    ; -----------------------
    ; INT 3 を呼んで自作ハンドラをテスト
    int 3

    hlt              ; 停止

; -----------------------
; INT 3 ハンドラ
int3_handler:
    pusha

    ; ターミナルにメッセージ
    mov si, msg
print_loop:
    lodsb
    cmp al, 0
    je done
    call print_char_serial
    jmp print_loop
done:
    popa
    iret

; -----------------------
; メッセージ
msg db "INT3 triggered! Hello terminal.",0

; -----------------------
; サブルーチン：1文字をCOM1に出力
print_char_serial:
    mov dx, 0x3F8
    out dx, al        ; 学習用: 送信バッファ確認なし
    ret

; -----------------------
times 510-($-$$) db 0
dw 0xAA55           ; ブート署名
