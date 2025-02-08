; Простой http сервер на NASM
; Роутов (endpoints) тут нет, просто отправляется любой запрос на любой url
; и получается ответ в духе json "Hello World!"
;
; Может быть я когда-нибудь добавлю проверку на роуты и методы запроса =(
; Но, думаю, что и этого для newbiew сойдет

section .data
    ; Ответ на запрос
    response db "HTTP/1.1 200 OK", 0x0D, 0x010A
             db "Content-Type: application/json", 0x0D, 0x0A
             db "Connection: close", 0x0D, 0x0A
             db 0x0D, 0x0A
             db '{"message": "Hello World!"}', 0x0D, 0x0A
    response_len equ $ - response

    ; Текст ошибки в консоли
    error_text db "Ошибка", 0
    error_text_len equ $ - error_text

    ; Порт и адрес
    sockaddr:
        dw 2              ; AF_INET
        dw 0x901F         ; Порт 8080
        dd 0              ; INADDR_ANY (0.0.0.0)
        dd 0              ; Заполнитель (Как я понял в Linux sockaddr должен быть 16 байт)
        dd 0              ; Заполнитель

    enable dd 1

section .bss align=4      ; выравнивание на 4 байта (честно, я не до конца понимаю, но видимо для x86_64 это важно)
    sock resq 1           ; 8 байт для дескриптора
    client_sock resq 1    ; 8 байт для дескриптора клиента
    buffer resb 1024      ; буфер для запроса

section .text
    global _start

_start:
    ; Создаем сокет
    mov rax, 41          ; sys_socket
    mov rdi, 2           ; AF_INET
    mov rsi, 1           ; SOCK_STREAM
    mov rdx, 0           ; Protocol
    syscall
    cmp rax, 0          ; проверяем, возникла ли ошибка при создании сокета
    jl error            ; если rax < 0, произошла ошибка
    mov [sock], rax     ; сохраняем дескриптор

    ; Устанавливаем кофигурацию сокету
    mov rax, 54          ; sys_setsockopt
    mov rdi, [sock]      ; дескриптор сокета
    mov rsi, 1           ; SOL_SOCKET
    mov rdx, 2           ; SO_REUSEADDR
    mov r10, enable      ; указатель на значение
    mov r8, 4            ; размер значения
    syscall
    cmp rax, 0          ; проверяем, возникла ли ошибка при setsockopt
    jl error

    ; Привязка сокета
    mov rax, 49         ; sys_bind
    mov rdi, [sock]     ; дескриптор сокета
    mov rsi, sockaddr   ; адрес структуры
    mov rdx, 16         ; размер структуры
    syscall
    cmp rax, 0          ; проверяем, возникла ли ошибка при bind
    jl error            ; если ошибка, переходим к обработке

    ; Слушаем сокет
    mov rax, 50         ; sys_listen
    mov rdi, [sock]     ; дескриптор сокета
    mov rsi, 5          ; максимум подключений
    syscall
    cmp rax, 0          ; проверяем, возникла ли ошибка при listen
    jl error

listen_loop:
    ; Принятие подключения
    mov rax, 43          ; sys_accept
    mov rdi, [sock]      ; Дескриптор сокета
    mov rsi, 0           ; Адрес клиента (NULL)
    mov rdx, 0           ; Длина адреса клиента (NULL)
    syscall
    cmp rax, 0          ; проверяем, возникла ли ошибка при accept
    jl error
    mov [client_sock], rax ; Сохраняем дескриптор клиента

    ; Чтение запроса
    mov rax, 0           ; sys_read
    mov rdi, [client_sock] ; Дескриптор клиента
    mov rsi, buffer       ; Буфер для данных
    mov rdx, 1024         ; Размер буфера
    syscall
    cmp rax, 0          ; проверяем успешность read
    jl error

    ; Отправка ответа
    mov rax, 1           ; sys_write
    mov rdi, [client_sock] ; Дескриптор клиента
    mov rsi, response     ; Данные для отправки
    mov rdx, response_len ; Длина данных
    syscall
    cmp rax, 0          ; проверяем успешность write
    jl error

    ; Закрытие клиентского сокета
    mov rax, 3           ; sys_close
    mov rdi, [client_sock] ; Дескриптор клиента
    syscall

    jmp listen_loop

error:
    ; Выводим текст ошибки в консоль
    mov rdi, error_text
    mov rsi, rax
    mov rdx, error_text_len
    mov rax, 1
    syscall

    ; Завершаем работу
    xor rdi, rdi        ; код ошибки
    mov rax, 60         ; sys_exit
    syscall
