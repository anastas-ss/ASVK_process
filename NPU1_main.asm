.parser
    store PHV, HEADER+28, 16        ;копируем в область PHV заголовок с DST MAC до Payload (не вкл)
    mov r1, PHV, 6
    cmpje r1, 0xffffffffffff, halt ;проверка на дейст-ть адреса
        mov r1, PHV+12, 2          ;копируем 2 первых байта VLAN (?)
        cmpjn r1, 0x8100, halt

.match_action 1 ;check multi + no name SRC MAC
    mov r1, PHV, 1                 ;берём первый байт DST MAC
    and r1, 0x1
    cmpje r1, 1, multi             ;отправить на все порты, кроме управления
    mov r1, PHV+6, 6               ;копируем SRC MAC
    call exact_match
    ;в r1 - возвращаемое значение
    ;в r2 - 0/1 - успех/печаль
    cmpje r2, 1, not_found         ;неуспех(печаль)

.match_action 2 ;exact match DST MAC + VLAN
    mov r1, PHV, 6                 ;положили DST MAC, надо ещё VLAN
    shl r1, 4                      ;на 4 байта сдвиг влево
    mov r3, PHV+12, 4
    or r1, r3                      ;в r1 DST MAC + VLAN - 10 байтов
    call exact_match               ;проверяем по 2-ой таблице
    ;в r1 - возвращаемое значение
    ;в r2 - 0/1 - успех/печаль
    cmpje r2, 1, not_found             
        mov r3, r1, 5                 
        shr r3, 1                 ;VLAN
        and r1, 0xff              ;PORTMASK 
        ;если я считаю, что PM - младший байт 
        mov PHV+12, r3, 4
        or PORTMASK, r1 
        j done
    
not_found: ;отправить на порт управления
    or PORTMASK, 0x80
    j done

multi: ;отправить на все порты, кроме порта управления
     or PORTMASK, 0x7f 
     
done:
    
.deparser
    load HEADER+28, PHV, 16
