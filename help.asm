do_help:
    ; Читаем текущий цвет темы из памяти ядра
    mov ax, 0x0600
    mov bh, [menu_color]  ; <-- ТЕПЕРЬ ЦВЕТ ДИНАМИЧЕСКИЙ!
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10

    mov dh, 10
    mov dl, 22
    call move_cursor
    mov si, msg_help_screen
    call print_string

    mov dh, 12
    mov dl, 26
    call move_cursor
    mov si, msg_press_esc
    call print_string

help_wait_esc:
    mov ah, 0x00
    int 0x16
    cmp al, 0x1B        
    je .exit_help       
    jmp help_wait_esc

.exit_help:
    ret                 

; Данные приложения
msg_help_screen  db "Use Arrows or W/S to select programs", 0
msg_press_esc    db "Press ESC to return to Menu", 0