; =================================================================
; PAINT.ASM - Модернизированный графический редактор для puiOS
; =================================================================

run_paint:
    ; Инициализация начальных настроек кисти
    mov byte [paint_cur_y], 12     ; Курсор в центр экрана
    mov byte [paint_cur_x], 40
    mov byte [current_brush], '#'  ; Дефолтная кисть
    mov byte [brush_color], 0x0C   ; Дефолтный цвет: Светло-красный
    mov byte [brush_size], 1       ; Дефолтный размер: 1 (1х1)

.redraw_all:
    ; 1. Создаем белый холст (строки 2-23)
    mov ch, 2           
    mov cl, 0           
    mov dh, 23          
    mov dl, 79          
    mov al, 1           
    call CanvasCreate   

    ; 2. Отрисовка панелей интерфейса
    mov dh, 0
    mov si, msg_paint_title
    mov al, 0           
    call UI_Panel

    mov dh, 24
    mov si, msg_paint_tip
    mov al, 0           
    call UI_Panel

.paint_loop:
    call update_paint_status

    ; Перемещаем курсор в рабочую позицию
    mov dh, [paint_cur_y]
    mov dl, [paint_cur_x]
    call move_cursor

    ; Ждем ввод
    mov ah, 0x00
    int 0x16

    ; Выход
    cmp al, 0x1B        ; ESC
    je exit_paint

    ; Рисование
    cmp al, ' '         ; SPACE
    je .draw_logic

    ; Смена цвета (Клавиша 'c' или 'C')
    cmp al, 'c'
    je .next_color
    cmp al, 'C'
    je .next_color

    ; Смена размера кисти по кругу (1 -> 2 -> 3)
    cmp al, 'b'
    je .toggle_size
    cmp al, 'B'
    je .toggle_size

    ; Выбор кистей кнопками 1-8 и 0
    cmp al, '1'
    je .set_brush_smile
    cmp al, '2'
    je .set_brush_hash
    cmp al, '3'
    je .set_brush_amp
    cmp al, '4'
    je .set_brush_dollar
    cmp al, '5'
    je .set_brush_at
    cmp al, '6'
    je .set_brush_percent
    cmp al, '7'
    je .set_brush_star
    cmp al, '8'
    je .set_brush_cent
    cmp al, '0'
    je .set_brush_eraser

    ; Движение стрелочками
    cmp ah, 0x48        ; Вверх
    je .cur_up
    cmp ah, 0x50        ; Вниз
    je .cur_down
    cmp ah, 0x4B        ; Влево
    je .cur_left
    cmp ah, 0x4D        ; Вправо
    je .cur_right

    jmp .paint_loop

; --- Выбор символа кисти ---
.set_brush_smile:   mov byte [current_brush], 0x01 
jmp .paint_loop
.set_brush_hash:    mov byte [current_brush], '#' 
jmp .paint_loop
.set_brush_amp:     mov byte [current_brush], '&'  
jmp .paint_loop
.set_brush_dollar:  mov byte [current_brush], '$' 
jmp .paint_loop
.set_brush_at:      mov byte [current_brush], '@'  
jmp .paint_loop
.set_brush_percent: mov byte [current_brush], '%'  
jmp .paint_loop
.set_brush_star:    mov byte [current_brush], ''  
jmp .paint_loop
.set_brush_cent:    mov byte [current_brush], 0x9B 
jmp .paint_loop ; Цент '¢' в CP437
.set_brush_eraser:  mov byte [current_brush], ' '  
jmp .paint_loop ; Пробел = Ластик

; --- Переключение размера кисти (1 -> 2 -> 3) ---
.toggle_size:
    inc byte [brush_size]
    cmp byte [brush_size], 4
    jne .paint_loop
    mov byte [brush_size], 1    ; Сброс на 1х1
    jmp .paint_loop

; --- Логика движения ---
.cur_up:
    cmp byte [paint_cur_y], 3
    je .paint_loop
    dec byte [paint_cur_y] 
    jmp .paint_loop
.cur_down:
    cmp byte [paint_cur_y], 22
    je .paint_loop
    inc byte [paint_cur_y]
    jmp .paint_loop
.cur_left:
    cmp byte [paint_cur_x], 1
    je .paint_loop
    dec byte [paint_cur_x] 
    jmp .paint_loop
.cur_right:
    cmp byte [paint_cur_x], 78
    je .paint_loop
    inc byte [paint_cur_x] 
    jmp .paint_loop

; --- Ротация цветов Радуги ---
.next_color:
    mov al, [brush_color]
    cmp al, 0x0C 
    je .to_orange
    cmp al, 0x06 
    je .to_yellow
    cmp al, 0x0E 
    je .to_green
    cmp al, 0x0A 
    je .to_cyan
    cmp al, 0x0B 
    je .to_blue
    cmp al, 0x09 
    je .to_purple
    mov byte [brush_color], 0x0C
    jmp .paint_loop
.to_orange: mov byte [brush_color], 0x06
jmp .paint_loop
.to_yellow: mov byte [brush_color], 0x0E 
jmp .paint_loop
.to_green:  mov byte [brush_color], 0x0A 
jmp .paint_loop
.to_cyan:   mov byte [brush_color], 0x0B 
jmp .paint_loop
.to_blue:   mov byte [brush_color], 0x09 
jmp .paint_loop
.to_purple: mov byte [brush_color], 0x05 
jmp .paint_loop

; --- Логика прорисовки кистей ---
.draw_logic:
    cmp byte [brush_size], 1
    je .draw_single
    cmp byte [brush_size], 2
    je .draw_3x3

    ; Если размер = 3 (5x5), проверяем символ. 
    ; Если выбрана звезда '', рисуем ромбом, иначе — сплошным квадратом.
    cmp byte [current_brush], '*'
    je .draw_rhombus_5x5

; --- Сплошной квадрат 5х5 ---
.draw_square_5x5:
    mov dh, [paint_cur_y]
    sub dh, 2                   ; Старт на 2 строки выше центра
    mov ch, 5                   ; 5 строк в высоту
.sq_row:
    push cx
    mov dl, [paint_cur_x]
    sub dl, 2                   ; Старт на 2 символа левее центра
    mov cl, 5                   ; 5 пикселей в ширину
.sq_col:
    push cx
    call .put_p
    inc dl
    pop cx
    loop .sq_col
    
    inc dh                      ; На строку ниже
    pop cx
    dec ch
    jnz .sq_row
    jmp .paint_loop

; --- Ромб 5х5 ---
.draw_rhombus_5x5:
    mov dh, [paint_cur_y]
    mov dl, [paint_cur_x]

    ; Строка 1 (Топ)
    sub dh, 2 
    call .put_p 
    add dh, 2
    
    ; Строка 2
    dec dh
    dec dl 
    call .put_p
    inc dl 
    call .put_p
    inc dl 
    call .put_p
    dec dl 
    inc dh
    
    ; Строка 3 (Центр во всю ширину)
    sub dl, 2
    mov cl, 5
.rh_center:
    push cx
    call .put_p 
    inc dl 
    pop cx 
    loop .rh_center
    sub dl, 3                   ; Возврат к центру X

    ; Строка 4
    inc dh
    dec dl 
    call .put_p
    inc dl 
    call .put_p
    inc dl 
    call .put_p
    dec dl 
    dec dh
    
    ; Строка 5 (Дно)
    add dh, 2 
    call .put_p 
    sub dh, 2
    jmp .paint_loop

; --- Крест 3х3 ---
.draw_3x3:
    mov dh, [paint_cur_y]
    mov dl, [paint_cur_x]
    dec dh 
    call .put_p 
    inc dh 
    dec dl 
    call .put_p 
    inc dl 
    call .put_p 
    inc dl 
    call .put_p 
    dec dl
    inc dh 
    call .put_p
    jmp .paint_loop

.draw_single:
    mov dh, [paint_cur_y]
    mov dl, [paint_cur_x]
    call .put_p
    jmp .paint_loop

; --- Вспомогательный «умный» вывод пикселя со слиянием фона ---
.put_p:
    ; Проверка границ холста, чтобы жирные кисти не вылезали на панели
    cmp dh, 2
    jl .skip_put
    cmp dh, 23
    jg .skip_put
    cmp dl, 0
    jl .skip_put
    cmp dl, 79
    jg .skip_put

    call move_cursor
    
    ; Считываем текущий цвет фона на экране под курсором
    mov ah, 0x08        
    mov bh, 0           
    int 0x10            
    
    mov bl, ah          
    and bl, 0xF0        ; Оставляем только "родной" фон холста
    
    mov al, [brush_color]
    and al, 0x0F        ; Оставляем цвет текста нашей кисти
    or bl, al           ; BL = Фон экрана + Текст кисти
    
    mov bh, 0           
    mov al, [current_brush] 
    mov ah, 0x09        ; Функция вывода BIOS
    mov cx, 1           
    int 0x10
.skip_put:
    ret

; --- Живой апдейт индикаторов в шапке ---
update_paint_status:
    pusha
    mov dh, 0
    mov dl, 45
    call move_cursor
    
    mov si, status_text
    call print_string
    
    ; Выводим символ текущей кисти
    mov ah, 0x0E
    mov al, [current_brush]
    int 0x10
    popa
    ret

; --- Данные модуля Paint ---

exit_paint:
    ret

paint_cur_x         db 0
paint_cur_y         db 0
current_brush       db '#'
brush_color         db 0x0C
brush_size          db 1

msg_paint_title     db " puiOS Art Studio v1.8 ", 0
msg_paint_tip       db " Space:Draw | C:Color | B:Size | 1-8:Brushes | 0:Eraser | ESC:Exit ", 0
status_text         db "Active Brush: ",