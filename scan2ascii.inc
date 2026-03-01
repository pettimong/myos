section .data

scan_table:
    db 0           ; 0x00
    db 27          ; Esc
    db '1','2','3','4','5','6','7','8','9','0','-','='
    db 8           ; Backspace
    db 9           ; Tab
    db 'q','w','e','r','t','y','u','i','o','p','[',']'
    db 10          ; Enter
    db 0           ; Ctrl
    db 'a','s','d','f','g','h','j','k','l',';','''','`'
    db 0           ; LShift
    db '\\','z','x','c','v','b','n','m',',','.','/'
    db 0           ; RShift
    db '*'         ; Keypad *
    db 0           ; Alt
    db ' '         ; Space
