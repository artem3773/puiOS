; =================================================================
; SETTINGS.ASM - Стабильная английская версия (Обновленная для Paint)
; =================================================================

run_settings:
    mov byte [settings_item], 0
    int 0x12
    call ram_to_string

settings_loop:
    call draw_settings_ui

    mov ah, 0x00
    int 0x16

    cmp al, 0x1B
    je .exit_settings

    cmp ah, 0x48        ; Вверх
    je .set_up
    cmp al, 'w'
    je .set_up
    
    cmp ah, 0x50        ; Вниз
    je .set_down
    cmp al, 's'
    je .set_down
    
    cmp al, 0x0D        ; Enter
    je .set_toggle

    jmp settings_loop

.set_up:
    cmp byte [settings_item], 0
    je settings_loop
    dec byte [settings_item]
    jmp settings_loop

.set_down:
    cmp byte [settings_item], 5  ; Теперь 6 пунктов (0-5)
    je settings_loop
    inc byte [settings_item]
    jmp settings_loop

.set_toggle:
    mov al, [settings_item]
    cmp al, 0
    je .toggle_color     ; Тема Меню
    cmp al, 1
    je .toggle_paint_col ; Тема Холста (Новое!)
    cmp al, 2
    je .toggle_arrows
    cmp al, 3
    je .toggle_ws
    jmp settings_loop

.toggle_color:
    cmp byte [menu_color], 0x17
    je .set_green
    cmp byte [menu_color], 0x02
    je .set_red
    mov byte [menu_color], 0x17
    jmp settings_loop
.set_green:
    mov byte [menu_color], 0x02
    jmp settings_loop
.set_red:
    mov byte [menu_color], 0x4F
    jmp settings_loop

; =================================================================
; --- ПЕРЕКЛЮЧЕНИЕ ТЕМЫ ХОЛСТА (Новое!) ---
; =================================================================
.toggle_paint_col:
    cmp byte [paint_color], 0x0F  ; White
    je .set_p_cyan
    cmp byte [paint_color], 0x3F  ; Cyan
    je .set_p_green
    cmp byte [paint_color], 0x2F  ; Green
    je .set_p_red
    
    mov byte [paint_color], 0x0F  ; Сброс на белый
    jmp settings_loop
.set_p_cyan:
    mov byte [paint_color], 0x3F
    jmp settings_loop
.set_p_green:
    mov byte [paint_color], 0x2F
    jmp settings_loop
.set_p_red:
    mov byte [paint_color], 0x4F
    jmp settings_loop
; =================================================================

.toggle_arrows:
    xor byte [cfg_arrows], 1
    jmp settings_loop

.toggle_ws:
    xor byte [cfg_ws], 1
    jmp settings_loop

.exit_settings:
    ret

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

draw_settings_ui:
    mov ch, 2           
    mov cl, 0           
    mov dh, 23         
    mov dl, 79          
    mov al, 1           
    call UI_Pole

    mov dh, 0
    mov si, msg_settings_title
    mov al, 0           
    call UI_Panel

    mov dh, 24
    mov si, msg_settings_tip
    mov al, 0           
    call UI_Panel

    mov dh, 4
    mov dl, 5
    call move_cursor
    mov si, msg_pc_info
    call print_string
    mov si, ram_buffer
    call print_string
    mov si, msg_kb
    call print_string

    ; --- Рендеринг пунктов ---
    
    ; 0: Тема Меню
    mov dh, 7
    mov dl, 5
    mov si, text_set_color
    xor ah, ah
    cmp byte [settings_item], 0
    sete ah
    
    mov di, val_blue
    cmp byte [menu_color], 0x17
    je .p0_c
    mov di, val_green
    cmp byte [menu_color], 0x02
    je .p0_c
    mov di, val_red
.p0_c:
    call UI_Menu

    ; 1: Тема Холста (Новое!)
    mov dh, 9
    mov dl, 5
    mov si, text_set_paint_col
    xor ah, ah
    cmp byte [settings_item], 1
    sete ah
    
    mov di, val_white
    cmp byte [paint_color], 0x0F
    je .p1_c
    mov di, val_p_cyan
    cmp byte [paint_color], 0x3F
    je .p1_c
    mov di, val_p_green
    cmp byte [paint_color], 0x2F
    je .p1_c
    mov di, val_p_red
.p1_c:
    call UI_Menu

    ; 2: Стрелки
    mov dh, 11
    mov dl, 5
    mov si, text_set_arrows
    xor ah, ah
    cmp byte [settings_item], 2
    sete ah
    mov di, cfg_arrows
    call UI_Bool

    ; 3: W/S
    mov dh, 13
    mov dl, 5
    mov si, text_set_ws
    xor ah, ah
    cmp byte [settings_item], 3
    sete ah
    mov di, cfg_ws
    call UI_Bool

    ; 4: GitHub
    mov dh, 16
    mov dl, 5
    mov si, text_github
    xor ah, ah
    cmp byte [settings_item], 4
    sete ah
    call UI_MenuButton

    ; 5: Telegram
    mov dh, 18
    mov dl, 5
    mov si, text_social
    xor ah, ah
    cmp byte [settings_item], 5
    sete ah
    call UI_MenuButton

    ret

; --- Данные settings.asm ---
settings_item       db 0
msg_settings_title  db " puiOS Control Panel - System Settings ", 0
msg_settings_tip    db " Nav: Arrows / W,S | Select: Enter | Exit: ESC ", 0
msg_pc_info         db "CPU: x86 Real Mode | Detected Base RAM: ", 0
msg_kb              db " KB", 0
ram_buffer          db "     ", 0

text_set_color      db " Menu Theme:   ", 0
text_set_paint_col  db " Paint Theme:  ", 0  ; (Новое!)
text_set_arrows     db " Enable Arrows:", 0
text_set_ws         db " Enable W/S:   ", 0
text_github         db " GitHub: github.com/artem3773 ", 0
text_social         db " Telegram: @Ctafan37 ", 0

val_blue            db "< Standard Blue >", 0
val_green           db "< Hacker Green  >", 0
val_red             db "< Danger Red    >", 0

val_white           db "< Clean White >", 0    ; (Темы холста)
val_p_cyan          db "< Light Cyan  >", 0
val_p_green         db "< Light Green >", 0
val_p_red           db "< Light Red   >", 0