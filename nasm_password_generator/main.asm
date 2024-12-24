global _start

section .data
    charset db "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", 0
    charset_len equ $ - charset - 1
    prompt db "Введите длину пароля: "    ; промпт для пользователя
    prompt_len equ $ - prompt
    newline db 0xA

section .bss
    input_buffer resb 16    ; буфер для ввода
    password resb 256       ; увеличим буфер для пароля

section .text
_start:
    ; Выводим приглашение
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov ecx, prompt         ; текст приглашения
    mov edx, prompt_len     ; длина приглашения
    int 0x80

    ; Читаем ввод пользователя
    mov eax, 3              ; sys_read
    mov ebx, 0              ; stdin
    mov ecx, input_buffer   ; куда читать
    mov edx, 16             ; максимальная длина
    int 0x80

    ; Преобразуем ASCII в число
    xor ecx, ecx            ; обнуляем счетчик (будет длина пароля)
    mov esi, input_buffer   ; указатель на введенную строку
    
convert_loop:
    movzx eax, byte [esi]   ; берем символ
    cmp al, 0xA             ; проверяем на перевод строки
    je generate_start       ; если нашли - начинаем генерацию
    sub al, '0'             ; конвертируем ASCII в число
    imul ecx, 10            ; умножаем предыдущее значение на 10
    add ecx, eax            ; добавляем новую цифру
    inc esi                 ; следующий символ
    jmp convert_loop

generate_start:
    mov edi, password       ; адрес буфера для пароля

generate_password:
    ; Получаем случайное число
    rdrand eax         ; генерируем случайное число в eax
    
    ; Получаем остаток от деления на длину charset
    xor edx, edx
    mov ebx, charset_len
    div ebx            ; делим eax на charset_len, остаток в edx
    
    ; Получаем символ из charset
    mov al, [charset + edx]
    
    ; Сохраняем символ в буфер пароля
    stosb             ; сохраняем AL в [EDI] и инкрементируем EDI
    
    loop generate_password
    
    ; Добавляем завершающий нуль
    mov byte [edi], 0

    ; Выводим пароль
    mov eax, 4          ; системный вызов write
    mov ebx, 1          ; stdout
    mov ecx, password   ; адрес строки для вывода
    mov edx, 15         ; длина пароля
    int 0x80

    ; Выводим перевод строки
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; Завершаем программу
    mov eax, 1
    xor ebx, ebx
    int 0x80
    
    