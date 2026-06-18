; =================================================================
; NOTEPAD.ASM - Текстовый редактор на базе UI.asm
; =================================================================

run_notepad:
    ; Очищаем внутренний буфер текста перед открытием
    mov di, notepad_buffer
    mov cx, 512
    xor al, al
    rep stosb
    mov word [notepad_ptr], 0

.redraw:
    ; 1. Рисуем рабочую область (светло-серое поле, строки 2-23)
    mov ch, 2
    mov cl, 0
    mov dh, 23
    mov dl, 79
    mov al, 0           ; Код стиля: классический серый блокнот
    call UI_Pole

    ; 2. Верхняя панель
    mov dh, 0
    mov si, msg_note_title
    mov al, 1           ; В цвет системной темы
    call UI_Panel

    ; 3. Нижняя панель подсказок
    mov dh, 24
    mov si, msg_note_tip
    mov al, 1           ; В цвет системной темы
    call UI_Panel

    ; 4. Выводим текст из буфера на рабочее поле
    mov dh, 3
    mov dl, 2
    call move_cursor
    mov si, notepad_buffer
    call print_string

.loop:
    mov ah, 0x00
    int 0x16            ; Ждем символ

    cmp al, 0x1B        ; ESC — безопасный выход
    je .exit

    cmp al, 0x08        ; Backspace — удаление
    je .backspace

    cmp al, 0x0D        ; Enter — новая строка
    je .enter

    ; Проверяем лимит буфера (512 байт)
    mov bx, [notepad_ptr]
    cmp bx, 511
    jae .loop

    ; Фильтруем мусорные управляющие символы
    cmp al, ' '
    jb .loop

    ; Записываем символ в память
    mov [notepad_buffer + bx], al
    inc word [notepad_ptr]
    jmp .redraw

.backspace:
    mov bx, [notepad_ptr]
    cmp bx, 0
    je .loop            
    
    dec word [notepad_ptr]
    dec bx
    mov byte [notepad_buffer + bx], 0  ; Затираем символ нулем
    jmp .redraw

.enter:
    mov bx, [notepad_ptr]
    cmp bx, 510
    jae .loop
    
    ; Записываем стандартный DOS-перенос строки CR+LF
    mov byte [notepad_buffer + bx], 0x0D
    mov byte [notepad_buffer + bx + 1], 0x0A
    add word [notepad_ptr], 2
    jmp .redraw

.exit:
    ret                 ; Возврат в ядро оболочки

; --- Данные блокнота ---
notepad_ptr     dw 0
msg_note_title  db " puiOS Text Editor - v1.0 ", 0
msg_note_tip    db " Type text... | Backspace: Delete character | Exit: ESC ", 0

notepad_count   dw 0
notepad_buffer  times 512 db 0