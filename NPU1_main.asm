.parser
    store PHV, HEADER+28, 16        ;�������� � ������� PHV ��������� � DST MAC �� Payload (�� ���)
    mov r1, PHV, 6
    cmpje r1, 0xffffffffffff, halt ;�������� �� �����-�� ������
        mov r1, PHV+12, 2          ;�������� 2 ������ ����� VLAN (?)
        cmpjn r1, 0x8100, halt

.match_action 1 ;check multi + no name SRC MAC
    mov r1, PHV, 1                 ;���� ������ ���� DST MAC
    and r1, 0x1
    cmpje r1, 1, multi             ;��������� �� ��� �����, ����� ����������
    mov r1, PHV+6, 6               ;�������� SRC MAC
    call exact_match
    ;� r1 - ������������ ��������
    ;� r2 - 0/1 - �����/������
    cmpje r2, 1, not_found         ;�������(������)

.match_action 2 ;exact match DST MAC + VLAN
    mov r1, PHV, 6                 ;�������� DST MAC, ���� ��� VLAN
    shl r1, 4                      ;�� 4 ����� ����� �����
    mov r3, PHV+12, 4
    or r1, r3                      ;� r1 DST MAC + VLAN - 10 ������
    call exact_match               ;��������� �� 2-�� �������
    ;� r1 - ������������ ��������
    ;� r2 - 0/1 - �����/������
    cmpje r2, 1, not_found             
        mov r3, r1, 5                 
        shr r3, 1                 ;VLAN
        and r1, 0xff              ;PORTMASK 
        ;���� � ������, ��� PM - ������� ���� 
        mov PHV+12, r3, 4
        or PORTMASK, r1 
        j done
    
not_found: ;��������� �� ���� ����������
    or PORTMASK, 0x80
    j done

multi: ;��������� �� ��� �����, ����� ����� ����������
     or PORTMASK, 0x7f 
     
done:
    
.deparser
    load HEADER+28, PHV, 16
