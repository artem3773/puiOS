; =================================================================
; UI.ASM - Модуль интерфейса (Обновленный: CanvasCreate)
; =================================================================

; --- 1. UI_Panel (Узкая полоса на всю ширину экрана) ---
; Вход: DH = строка (Y), SI = текст, AL = флаг темы (1 - тема, 0 - серый)
UI_Panel:
    pusha
    mov bh, 0x70        ; Дефолт: серый
    cmp al, 1
    jne .apply_p
    mov bh, [menu_color] ; Цвет темы из ядра
.apply_p:
    mov ax, 0x0600      ; Функция заливки строки
    mov ch, dh          ; Верх строка
    mov cl, 0           ; Лево
    push dx
    mov dl, 79          ; Право
    int 0x10
    pop dx
    
    mov dl, 2           ; Отступ текста
    call move_cursor
    call print_string
    popa
    ret

; --- 2. UI_Pole (Для блокнота/меню) ---
; Вход: CH, CL, DH, DL (координаты), AL=1 (тема меню), 0 (тема редактора)
UI_Pole:
    pusha
    cmp al, 1
    je .theme_m
    mov bh, 0x70        ; Тема редактора: серый
    jmp .apply_po
.theme_m:
    mov bh, [menu_color] ; Тема меню
.apply_po:
    mov ax, 0x0600
    int 0x10
    popa
    ret

; --- 3. UI_MenuButton (Кнопка меню) ---
UI_MenuButton:
    pusha
    call move_cursor
    cmp ah, 1
    je .selected
    
    mov al, ' '
    mov ah, 0x0E
    int 0x10
    call print_string
    jmp .done
    
.selected:
    mov al, '!'
    mov ah, 0x0E
    int 0x10
    call print_string
    mov al, '!'
    mov ah, 0x0E
    int 0x10
.done:
    popa
    ret

; --- 4. UI_Bool (Переключатель флага) ---
UI_Bool:
    pusha
    call UI_MenuButton
    
    add dl, 22
    call move_cursor
    
    mov al, [di]
    cmp al, 1
    je .checked
    
    mov si, .str_off
    call print_string
    jmp .end
.checked:
    mov si, .str_on
    call print_string
.end:
    popa
    ret
.str_off db "[DISABLED]", 0
.str_on  db "[ ENABLED]", 0

; --- 5. UI_Menu (Выбор опций) ---
UI_Menu:
    pusha
    call UI_MenuButton
    
    add dl, 22
    call move_cursor
    
    push si
    mov si, di
    call print_string
    pop si
    popa
    ret

; =================================================================
; --- 6. CanvasCreate (СОЗДАНИЕ ХОЛСТА ДЛЯ РИСОВАНИЯ) ---
; Вход: CH, CL, DH, DL (координаты), AL=1 (использовать тему), 0 (белый)
; =================================================================
CanvasCreate:
    pusha
    
    mov bh, 0x0F        ; По умолчанию: белый холст
    cmp al, 1
    jne .apply_c
    mov bh, [paint_color] ; Или берем из темы рисования
.apply_c:
    mov ax, 0x0600      ; Функция заливки окна
    int 0x10
    popa
    ret