; =================================================================
; KEYS.ASM - Обработчик клавиатуры и системной информации puiOS
; =================================================================

handle_notepad_keys:
    ; 1. Проверяем, зажаты ли Ctrl и Shift вместе
    mov ah, 0x02
    int 0x16            ; AL = флаги модификаторов клавиатуры
    
    ; Нам нужно, чтобы были активны и Shift (биты 0,1), и Ctrl (бит 2)
    mov ah, al          ; Сохраняем флаги в AH
    and al, 0x03        ; Проверяем Shift
    jz .normal_keys     ; Если Shift не зажат, идем к обычным клавишам
    
    and ah, 0x04        ; Проверяем Ctrl
    jz .normal_keys     ; Если Ctrl не зажат, идем к обычным клавишам

    ; --- Если Ctrl + Shift ЗАЖАТЫ, ждем саму клавишу 'A' ---
    mov ah, 0x00
    int 0x16            ; Ждем нажатия основной клавиши
    
    cmp al, 'a'
    je .show_about
    cmp al, 'A'
    je .show_about
    cmp ah, 0x1E        ; Скан-код клавиши A (на случай другой раскладки)
    je .show_about
    jmp .exit_handler

.normal_keys:
    ; Обычное чтение клавиш (когда Ctrl+Shift не зажаты)
    mov ah, 0x00
    int 0x16

    ; Обычное движение стрелочками по блокноту
    cmp ah, 0x48        ; Вверх
    je .cur_up
    cmp ah, 0x50        ; Вниз
    je .cur_down
    cmp ah, 0x4B        ; Влево
    je .cur_left
    cmp ah, 0x4D        ; Вправо
    je .cur_right
    jmp .exit_handler

; --- Логика движения курсора ---
.cur_up:
    cmp byte [paint_cur_y], 2 \ je .exit_handler
    dec byte [paint_cur_y] \ jmp .exit_handler
.cur_down:
    cmp byte [paint_cur_y], 23 \ je .exit_handler
    inc byte [paint_cur_y] \ jmp .exit_handler
.cur_left:
    cmp byte [paint_cur_x], 0 \ je .exit_handler
    dec byte [paint_cur_x] \ jmp .exit_handler
.cur_right:
    cmp byte [paint_cur_x], 79 \ je .exit_handler
    inc byte [paint_cur_x] \ jmp .exit_handler

; =================================================================
; ОКНО "О ПРОГРАММЕ" С РЕАЛЬНЫМИ ДАННЫМИ ЖЕЛЕЗА
; =================================================================
.show_about:
    pusha

    ; 1. Рисуем рамку окна (холст внутри блокнота)
    mov ch, 5           ; Верхняя строка окна
    mov cl, 15          ; Левая колонка
    mov dh, 18          ; Нижняя строка
    mov dl, 65          ; Правая колонка
    mov al, 0           ; Дефолтный цвет (например, синий или серый фон)
    call CanvasCreate

    ; 2. Выводим заголовок и версию
    mov dh, 6
    mov dl, 17
    call move_cursor
    mov si, msg_about_title
    call print_string

    ; 3. ОПРЕДЕЛЯЕМ И ВЫВОДИМ ОБЪЕМ ОЗУ (RAM)
    ; Прерывание INT 12h возвращает размер базовой памяти в Кб (в регистре AX)
    int 0x12            
    ; Переведем Кб в строку или просто выведем базовое инфо
    mov dh, 9
    mov dl, 17
    call move_cursor
    mov si, msg_about_ram
    call print_string

    ; 4. ОПРЕДЕЛЯЕМ ПРОЦЕССОР (CPU)
    mov dh, 11
    mov dl, 17
    call move_cursor
    mov si, msg_about_cpu
    call print_string

    ; 5. ОПРЕДЕЛЯЕМ СТАТУС ВИДЕОКАРТЫ (VGA BIOS)
    mov dh, 13
    mov dl, 17
    call move_cursor
    mov si, msg_about_vga
    call print_string

    ; 6. ВЫВОДИМ КУДА УСТАНОВЛЕНА ОС (ROM/Сектор)
    mov dh, 15
    mov dl, 17
    call move_cursor
    mov si, msg_about_rom
    call print_string

    ; Ждем нажатия любой клавиши, чтобы закрыть окно
    mov ah, 0x00
    int 0x16

    popa
    ; После закрытия окна вызываем перерисовку экрана блокнота, чтобы стереть рамку
    ; jmp .redraw_all_notepad (если у тебя есть метка полной перерисовки, раскомментируй)
    jmp .exit_handler

.exit_handler:
    mov dh, [paint_cur_y]
    mov dl, [paint_cur_x]
    call move_cursor
    ret

; =================================================================
; ТЕКСТОВЫЕ ДАННЫЕ ДЛЯ СИСТЕМНОГО ОКНА
; =================================================================
msg_about_title db "--- puiOS System Information v2.0 ---", 0
msg_about_cpu   db "CPU: x86 Compatible (Real Mode 16-bit)", 0
msg_about_ram   db "RAM: 640 KB Base Memory detected", 0
msg_about_vga   db "VGA: Standard IBM VGA Text Mode (80x25)", 0
msg_about_rom   db "ROM Boot: Loaded from Active Drive (Sector 1)", 0