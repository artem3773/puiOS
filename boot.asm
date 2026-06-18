[org 0x7c00]

KERNEL_OFFSET equ 0x1000

mov [BOOT_DRIVE], dl

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

; Читаем стандартные 5 секторов
mov bx, KERNEL_OFFSET
mov dh, 7            
mov dl, [BOOT_DRIVE]
call disk_load

jmp KERNEL_OFFSET

%include "disk.asm"     ; Возвращаем твой disk.asm на место

BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xaa55