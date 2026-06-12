[org 0x1000]

start:
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ax, 0x0003
    int 0x10

show_main_menu:
    ; Очищаем экран динамическим цветом из памяти!
    mov ax, 0x0600
    mov bh, [menu_color]  ; Читаем цвет из настроек
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10

menu_loop:
    call draw_menu      

    mov ah, 0x00
    int 0x16            

    ; Проверка динамического конфига стрелочек
    cmp byte [cfg_arrows], 1
    jne check_ws        
    cmp ah, 0x48        
    je move_up
    cmp ah, 0x50        
    je move_down

check_ws:
    ; Проверка динамического конфига W/S
    cmp byte [cfg_ws], 1
    jne check_enter     
    cmp al, 'w'
    je move_up
    cmp al, 'W'
    je move_up
    cmp al, 's'
    je move_down
    cmp al, 'S'
    je move_down

check_enter:
    cmp al, 0x0D        
    je item_selected
    jmp menu_loop       

move_up:
    mov al, [current_item]
    cmp al, 0           
    je menu_loop        
    dec byte [current_item]
    jmp show_main_menu  

move_down:
    mov al, [current_item]
    cmp al, 3           ; Теперь у нас 4 пункта меню (0, 1, 2, 3)
    je menu_loop        
    inc byte [current_item]
    jmp show_main_menu  

item_selected:
    mov al, [current_item]
    cmp al, 0
    je do_exit
    cmp al, 1
    je .open_help
    cmp al, 2
    je .open_notepad
    cmp al, 3
    je .open_settings   ; Переход в настройки
    jmp menu_loop

.open_help:
    call do_help         
    jmp show_main_menu   

.open_notepad:
    call run_notepad     
    jmp show_main_menu   

.open_settings:
    call run_settings    ; Вызываем наше новое приложение настроек
    jmp show_main_menu

do_exit:
    int 0x19            

; --- СЕРВИСНЫЕ ФУНКЦИИ ИНТЕРФЕЙСА ---

draw_menu:
    ; Пункт 0: Exit
    mov dh, 9
    mov dl, 35
    call move_cursor
    cmp byte [current_item], 0
    je .draw_sel_0
    mov si, text_exit_normal
    call print_string
    jmp .item_1
.draw_sel_0:
    mov si, text_exit_sel
    call print_string

.item_1:
    ; Пункт 1: Help
    mov dh, 11
    mov dl, 35
    call move_cursor
    cmp byte [current_item], 1
    je .draw_sel_1
    mov si, text_help_normal
    call print_string
    jmp .item_2
.draw_sel_1:
    mov si, text_help_sel
    call print_string

.item_2:
    ; Пункт 2: Notepad
    mov dh, 13
    mov dl, 35
    call move_cursor
    cmp byte [current_item], 2
    je .draw_sel_2
    mov si, text_notepad_normal
    call print_string
    jmp .item_3
.draw_sel_2:
    mov si, text_notepad_sel
    call print_string
    
.item_3:
    ; Пункт 3: Settings (Новый!)
    mov dh, 15
    mov dl, 35
    call move_cursor
    cmp byte [current_item], 3
    je .draw_sel_3
    mov si, text_settings_normal
    call print_string
    ret
.draw_sel_3:
    mov si, text_settings_sel
    call print_string
    ret

move_cursor:
    push ax
    push bx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

print_string:
    push ax
    push bx
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    pop bx
    pop ax
    ret

; --- ПОДКЛЮЧЕНИЕ ВНЕШНИХ ФАЙЛОВ ПРИЛОЖЕНИЙ ---
%include "help.asm"
%include "notepad.asm"
%include "settings.asm"  ; Подключили настройки!

; --- ГЛОБАЛЬНЫЕ ДАННЫЕ И ПЕРЕМЕННЫЕ ЯДРА ---
cfg_arrows    db 1      
cfg_ws        db 1      
menu_color    db 0x17   ; Переменная цвета! По умолчанию: 0x17 (Белый текст на синем)
current_item  db 1      

text_exit_normal     db " <exit>     ", 0
text_help_normal     db " <help>     ", 0
text_notepad_normal  db " <notepad>  ", 0  
text_settings_normal db " <settings> ", 0  ; Строка для нового пункта

text_exit_sel        db "!<exit>!    ", 0
text_help_sel        db "!<help>!    ", 0
text_notepad_sel     db "!<notepad>! ", 0
text_settings_sel    db "!<settings>!", 0

; Выравнивание под размер диска (разрослось, сделаем 3 сектора — 1536 байт)
times 2560-($-$$) db 0