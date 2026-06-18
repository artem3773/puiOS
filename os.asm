; =================================================================
; OS.ASM - Главное ядро puiOS v1.6 (Полная версия)
; =================================================================
[org 0x1000]

start:
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; Устанавливаем стандартный текстовый видеорежим 80x25
    mov ax, 0x0003
    int 0x10

show_main_menu:
    ; Очищаем экран под цвет текущей темы меню
    mov ax, 0x0600
    mov bh, [menu_color]  
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10

menu_loop:
    call draw_menu      ; Рисуем главное меню
    call draw_clock     ; Выводим живые часы в угол экрана

    ; Опрос клавиатуры без ожидания (чтобы часы тикали)
    mov ah, 0x01
    int 0x16
    jz menu_loop        ; Если клавиша не нажата — крутим цикл и обновляем часы

    ; Если клавиша нажата — забираем её из буфера
    mov ah, 0x00
    int 0x16

    ; Навигация (Стрелочки или W/S)
    cmp ah, 0x48        ; Вверх
    je .move_up
    cmp al, 'w'
    je .move_up
    
    cmp ah, 0x50        ; Вниз
    je .move_down
    cmp al, 's'
    je .move_down

    cmp al, 0x0D        ; Enter — запуск выбранного пункта
    je execute_item

    jmp menu_loop

.move_up:
    cmp byte [current_item], 1
    je menu_loop
    dec byte [current_item]
    jmp show_main_menu

.move_down:
    cmp byte [current_item], 4 ; Теперь у нас 4 пункта меню!
    je menu_loop
    inc byte [current_item]
    jmp show_main_menu

; --- Обработка запуска приложений ---
execute_item:
    mov al, [current_item]
    cmp al, 1
    je .open_notepad
    cmp al, 2
    je .open_paint
    cmp al, 3
    je .open_settings
    cmp al, 4
    je .exit_system
    jmp menu_loop

.open_notepad:
    call run_notepad
    jmp show_main_menu

.open_paint:
    call run_paint      ; Запуск нашей новой рисовалки!
    jmp show_main_menu

.open_settings:
    call run_settings
    jmp show_main_menu

.exit_system:
    ; Мягкое тушение экрана
    mov ax, 0x0600
    mov bh, 0x07        ; Серый текст на черном фоне
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10
    
    mov dh, 12
    mov dl, 30
    call move_cursor
    mov si, msg_goodbye
    call print_string
    
    cli                 ; Отключаем прерывания
    hlt                 ; Останавливаем процессор
    jmp $

; --- Отрисовка элементов главного меню ---
draw_menu:
    ; Заголовок системы
    mov dh, 2
    mov dl, 25
    call move_cursor
    mov si, msg_main_title
    call print_string

    ; Пункт 1: Текстовый редактор
    mov dh, 6
    mov dl, 26
    call move_cursor
    cmp byte [current_item], 1
    je .sel_1
    mov si, text_m_notepad
    call print_string
    jmp .item_2
.sel_1:
    mov si, text_m_notepad_s
    call print_string

.item_2:
    ; Пункт 2: Рисовалка (Paint)
    mov dh, 8
    mov dl, 26
    call move_cursor
    cmp byte [current_item], 2
    je .sel_2
    mov si, text_m_paint
    call print_string
    jmp .item_3
.sel_2:
    mov si, text_m_paint_s
    call print_string

.item_3:
    ; Пункт 3: Настройки
    mov dh, 10
    mov dl, 26
    call move_cursor
    cmp byte [current_item], 3
    je .sel_3
    mov si, text_m_settings
    call print_string
    jmp .item_4
.sel_3:
    mov si, text_m_settings_s
    call print_string

.item_4:
    ; Пункт 4: Выход
    mov dh, 12
    mov dl, 26
    call move_cursor
    cmp byte [current_item], 4
    je .sel_4
    mov si, text_m_exit
    call print_string
    ret
.sel_4:
    mov si, text_m_exit_s
    call print_string
    ret

; --- Живые часы из RTC (Real Time Clock) ---
draw_clock:
    pusha
    mov ah, 0x02        
    int 0x1A
    jc .done            
    
    push dx
    push cx

    mov dh, 0
    mov dl, 71
    call move_cursor

    pop cx
    push cx
    mov al, ch
    call .print_bcd
    
    mov al, ':'
    call .print_char
    
    pop cx
    mov al, cl
    call .print_bcd
    
    mov al, ':'
    call .print_char
    
    pop dx
    mov al, dh
    call .print_bcd

.done:
    popa
    ret

.print_bcd:
    push ax
    shr al, 4           
    add al, '0'
    call .print_char
    pop ax
    and al, 0x0F        
    add al, '0'
    call .print_char
    ret

.print_char:
    mov ah, 0x0E
    int 0x10
    ret

; --- Базовые системные функции вывода ---
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

move_cursor:
    pusha
    mov ah, 0x02
    mov bh, 0
    int 0x10
    popa
    ret

; --- ГЛОБАЛЬНЫЕ ДАННЫЕ И ПЕРЕМЕННЫЕ ЯДРА ---
cfg_arrows      db 1
cfg_ws          db 1
menu_color      db 0x17   ; Тема меню (Синяя)
paint_color     db 0x0F   ; Тема холста по умолчанию (Белая)
current_item    db 1

msg_main_title    db "=== puiOS Main Shell v1.6 ===", 0
text_m_notepad    db "  1. Text Editor (Notepad) ", 0
text_m_notepad_s  db "->1. Text Editor (Notepad) ", 0
text_m_paint      db "  2. Paint Studio (Art)    ", 0
text_m_paint_s    db "->2. Paint Studio (Art)    ", 0
text_m_settings   db "  3. System Control Panel  ", 0
text_m_settings_s db "->3. System Control Panel  ", 0
text_m_exit       db "  4. Shutdown puiOS        ", 0
text_m_exit_s     db "->4. Shutdown puiOS        ", 0
msg_goodbye       db "Goodbye from puiOS!", 0

; --- ПОДКЛЮЧЕНИЕ МОДУЛЕЙ ПРИЛОЖЕНИЙ ---
%include "notepad.asm"
%include "paint.asm"
%include "settings.asm"
%include "UI.asm"

; Выравнивание строго под 5 секторов диска (2560 байт)
times 3584-($-$$) db 0