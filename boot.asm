[org 0x7c00]

KERNEL_OFFSET equ 0x1000 ; Адрес в памяти для загрузки ядра

mov [BOOT_DRIVE], dl    ; BIOS передает номер загрузочного диска в DL

; Настройка сегментов памяти и стека
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00          ; Стек растет вниз от адреса загрузчика

; Загружаем ядро (возьмем с запасом 5 секторов)
mov bx, KERNEL_OFFSET   ; Куда загружать (ES:BX)
mov dh, 5               ; Количество секторов для чтения
mov dl, [BOOT_DRIVE]    ; Номер диска
call disk_load

; Передаем управление ядру
jmp KERNEL_OFFSET

%include "disk.asm"     ; Подключаем логику чтения диска

BOOT_DRIVE db 0

times 510-($-$$) db 0   ; Заполняем нулями до 510 байт
dw 0xaa55               ; Сигнатура загрузочного сектора