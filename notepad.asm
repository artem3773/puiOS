run_notepad:
    ; Основное текстовое поле оставляем светлым для удобства чтения (0x70 - серый/белый фон)
    mov ax, 0x0600
    mov bh, 0x70        
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10

    ; А вот статус-бар внизу сделаем зависимым от выбранной темы!
    mov ax, 0x0600
    mov bh, [menu_color]  ; <-- Статус-бар окрасится в цвет текущей темы!
    mov cx, 0x1800      
    mov dx, 0x184f      
    int 0x10

    mov dh, 24
    mov dl, 2
    call move_cursor
    mov si, msg_notepad_bar
    call print_string

    ; Сбрасываем курсор в начало (0, 0)
    mov dh, 0
    mov dl, 0
    call move_cursor

notepad_loop:
    mov ah, 0x00
    int 0x16            

    cmp al, 0x1B        
    je .exit_notepad

    cmp al, 0x0D        
    je .notepad_enter

    cmp al, 0x08        
    je .notepad_backspace

    cmp al, 0x20        
    jl notepad_loop     

    push ax
    mov ah, 0x03
    mov bh, 0
    int 0x10            
    pop ax
    cmp dl, 79
    je notepad_loop     

    ; Печать символа. Чтобы буквы в Блокноте тоже выглядели красиво, 
    ; сделаем их всегда черными на нашем сером фоне (атрибут 0x70)
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp notepad_loop

.notepad_enter:
    mov ah, 0x03
    mov bh, 0
    int 0x10            
    cmp dh, 23          
    jge notepad_loop    
    inc dh              
    mov dl, 0           
    mov ah, 0x02        
    int 0x10
    jmp notepad_loop

.notepad_backspace:
    mov ah, 0x03
    mov bh, 0
    int 0x10            
    cmp dh, 0
    jne .check_column
    cmp dl, 0
    je notepad_loop
.check_column:
    cmp dl, 0
    je .move_to_prev_line
    dec dl              
    mov ah, 0x02
    int 0x10            
    mov ah, 0x0A
    mov al, ' '         
    mov cx, 1
    int 0x10
    jmp notepad_loop
.move_to_prev_line:
    dec dh              
    mov dl, 79          
    mov ah, 0x02
    int 0x10
    jmp notepad_loop

.exit_notepad:
    ret

; Данные блокнота
msg_notepad_bar db " ASM NOTEPAD v1.2   |   Enter = New Line  |  ESC = Exit ", 0