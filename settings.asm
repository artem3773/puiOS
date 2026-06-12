run_settings:
    mov byte [settings_item], 0

settings_screen:
    ; ТЕПЕРЬ НАСТРОЙКИ ТОЖЕ КРАСЯТСЯ В ЦВЕТ ТЕМЫ!
    ; Берем цвет напрямую из [menu_color]
    mov ax, 0x0600
    mov bh, [menu_color]  
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10

    ; Заголовок окна настроек
    mov dh, 2
    mov dl, 30
    call move_cursor
    mov si, msg_settings_title
    call print_string

    ; --- БЛОК ИНФОРМАЦИИ О ПК ---
    int 0x12            ; Опрашиваем BIOS об ОЗУ
    call ram_to_string  

    mov dh, 4
    mov dl, 5
    call move_cursor
    mov si, msg_pc_info
    call print_string

    mov si, ram_buffer
    call print_string

    mov si, msg_kb
    call print_string

    ; Горизонтальная линия-разделитель
    mov dh, 5
    mov dl, 5
    mov cx, 70
.line:
    call move_cursor
    push dx
    mov ah, 0x0E
    mov al, '-'
    int 0x10
    pop dx
    inc dl
    loop .line

settings_loop:
    call draw_settings_menu

    mov ah, 0x00
    int 0x16

    cmp al, 0x1B        ; ESC -> выход в главное меню
    je .exit_settings

    cmp ah, 0x48        ; Вверх
    je .set_up
    cmp al, 'w'
    je .set_up
    cmp ah, 0x50        ; Вниз
    je .set_down
    cmp al, 's'
    je .set_down

    cmp al, 0x0D        ; Enter -> переключить
    je .set_toggle

    jmp settings_loop

.set_up:
    cmp byte [settings_item], 0
    je settings_loop
    dec byte [settings_item]
    jmp settings_screen ; Перерисовываем весь экран, чтобы обновить фон

.set_down:
    cmp byte [settings_item], 4  
    je settings_loop
    inc byte [settings_item]
    jmp settings_screen ; Перерисовываем весь экран, чтобы обновить фон

.set_toggle:
    mov al, [settings_item]
    cmp al, 0
    je .toggle_color
    cmp al, 1
    je .toggle_arrows
    cmp al, 2
    je .toggle_ws
    jmp settings_loop

.toggle_color:
    cmp byte [menu_color], 0x17
    je .set_green
    cmp byte [menu_color], 0x02
    je .set_red
    mov byte [menu_color], 0x17
    jmp settings_screen ; Экран сразу перекрасится в синий!
.set_green:
    mov byte [menu_color], 0x02
    jmp settings_screen ; Экран сразу перекрасится в зеленый!
.set_red:
    mov byte [menu_color], 0x4F
    jmp settings_screen ; Экран сразу перекрасится в красный!

.toggle_arrows:
    xor byte [cfg_arrows], 1
    jmp settings_screen

.toggle_ws:
    xor byte [cfg_ws], 1
    jmp settings_screen

.exit_settings:
    ret

; --- Перевод числа AX в строку ---
ram_to_string:
    pusha
    mov di, ram_buffer + 4 
    mov cx, 10
.loop:
    xor dx, dx
    div cx              
    add dl, '0'         
    dec di
    mov [di], dl
    test ax, ax
    jnz .loop
    popa
    ret

; --- Отрисовка пунктов подменю ---
draw_settings_menu:
    ; 0. Цвет
    mov dh, 7
    mov dl, 5
    call move_cursor
    cmp byte [settings_item], 0
    je .sel_0
    mov si, text_set_color
    jmp .print_0
.sel_0:
    mov si, text_set_color_sel
.print_0:
    call print_string
    
    cmp byte [menu_color], 0x17
    je .c_blue
    cmp byte [menu_color], 0x02
    je .c_green
    mov si, val_red
    jmp .print_v0
.c_blue:
    mov si, val_blue
    jmp .print_v0
.c_green:
    mov si, val_green
.print_v0:
    call print_string

    ; 1. Стрелочки
    mov dh, 9
    mov dl, 5
    call move_cursor
    cmp byte [settings_item], 1
    je .sel_1
    mov si, text_set_arrows
    jmp .print_1
.sel_1:
    mov si, text_set_arrows_sel
.print_1:
    call print_string
    cmp byte [cfg_arrows], 1
    je .arr_on
    mov si, val_off
    jmp .print_v1
.arr_on:
    mov si, val_on
.print_v1:
    call print_string

    ; 2. Клавиши W/S
    mov dh, 11
    mov dl, 5
    call move_cursor
    cmp byte [settings_item], 2
    je .sel_2
    mov si, text_set_ws
    jmp .print_2
.sel_2:
    mov si, text_set_ws_sel
.print_2:
    call print_string
    cmp byte [cfg_ws], 1
    je .ws_on
    mov si, val_off
    jmp .print_v2
.ws_on:
    mov si, val_on
.print_v2:
    call print_string

    ; 3. GitHub
    mov dh, 14
    mov dl, 5
    call move_cursor
    cmp byte [settings_item], 3
    je .sel_3
    mov si, text_github
    jmp .print_3
.sel_3:
    mov si, text_github_sel
.print_3:
    call print_string

    ; 4. Соцсети
    mov dh, 16
    mov dl, 5
    call move_cursor
    cmp byte [settings_item], 4
    je .sel_4
    mov si, text_social
    jmp .print_4
.sel_4:
    mov si, text_social_sel
.print_4:
    call print_string
    ret

; Данные приложения
settings_item       db 0
msg_settings_title  db "=== SYSTEM INFO & SETTINGS ===", 0
msg_pc_info         db "CPU: x86 Real Mode | Detected Base RAM: ", 0
msg_kb              db " KB", 0
ram_buffer          db "     ", 0 

text_set_color      db "  [ ] Menu Color:    ", 0
text_set_color_sel  db "  [*] Menu Color:    ", 0
text_set_arrows     db "  [ ] Enable Arrows: ", 0
text_set_arrows_sel db "  [*] Enable Arrows: ", 0
text_set_ws         db "  [ ] Enable W/S:    ", 0
text_set_ws_sel     db "  [*] Enable W/S:    ", 0

text_github         db "  [ ] GitHub: github.com/artem3773 (My Custom ASM OS v1.2)", 0
text_github_sel     db "  [*] GitHub: github.com/artem3773 (My Custom ASM OS v1.2)", 0
text_social         db "  [ ] Telegram: @Ctafan37", 0
text_social_sel     db "  [*] Telegram: @Ctafan37", 0

val_blue            db "< Standard Blue >", 0
val_green           db "< Hacker Green  >", 0
val_red             db "< Danger Red    >", 0
val_on              db "< ENABLED  >", 0
val_off             db "< DISABLED >", 0