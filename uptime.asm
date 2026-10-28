; * Утилита "uptime"
; * *************************
; * Данная программа показывает дату запуска текущего сеанса ЭВМ.
; * Программа остаётся резидентной и вызывается пользователем через
; * комбинацию клавиш LCtrl+LAlt+I.
; *
; * Формат компиляции: ".com"-файл.
; * Язык программирования: Turbo Assembler, ver. 2.0.
; * Кодировки исходного кода: CP866.
; * Размер исполнительного файла: 504 байта.
; * Размер TSR-части в ОЗУ: 448 байт.
; * Системные требования:
; * 1) IBM PC AT;
; * 2) реальный режим работы ЦП;
; * 3) операционная система DOS.
; * Компиляция программы:
; * tasm.exe uptime.asm
; * tlink.exe /x /t uptime.obj
; * del uptime.obj
; *
; * @author Ефремов А. В., 28.10.2026

.MODEL TINY
.CODE

DOS_API      EQU 21h
BIOS_API     EQU 10h
ROM_BIOS     EQU 40h; адрес сегмента ROM-BIOS
FL_CTRL      EQU 4h; флаг LCtrl в ROM-BIOS (в [0040h:0017h])
FL_ALT       EQU 8h; флаг LAlt в ROM-BIOS (в [0040h:0017h])
SC_I         EQU 23; скан-код клавиши I
TO_DIGIT     EQU '0'
OFFSET_YYYY  EQU 0; год (1980 - 2099)
OFFSET_M     EQU 5; месяц (1 - 12)
OFFSET_D     EQU 8; день (1 - 31)
OFFSET_HH    EQU 11; часы (0 - 23)
OFFSET_MI    EQU 14; минуты (0 - 59)
OFFSET_SS    EQU 17; секунды (0 - 59)

  ORG 100h

Start:
  jmp NEAR PTR Install

; обработчик вектора прерывания 9
TSR_Int09h:
  push AX
  push ES
  mov AX, ROM_BIOS
  mov ES, AX
  mov AL, [BYTE PTR ES:17h]; первый байт состояния регистра клавиатуры
  xor AH, AH
  or AH, FL_CTRL
  or AH, FL_ALT
  and AL, AH
  cmp AL, AH; нажата ли комбинация LCtrl+LAlt?
  jne Exit_09h
  in AL, 60h
  cmp AL, SC_I
  call NEAR PTR do_it
Exit_09h:
  pop ES
  pop AX
  jmp DWORD PTR [CS:Old09]
do_it PROC NEAR
  ; ***********
  pushf
  push AX
  push BX
  push CX
  push DX
  push DS
  ; реализация основного функционала
  mov AH, 03h
  mov BH, [CS:saved_page]; сохранить позицию и форму курсора
  int BIOS_API
  mov [CS:saved_row], DH
  mov [CS:saved_col], DL
  mov [CS:saved_start], CH
  mov [CS:saved_end], CL
  mov AH, 02h; BIOS: установить позицию курсора
  mov BH, [CS:saved_page]; видеостраница
  mov DH, 9; строка: 10-я в BASIC -> 9 для BIOS
  mov DL, 24; столбец: 25-й в BASIC -> 24 для BIOS
  int BIOS_API
  mov AX, CS
  mov DS, AX
  mov AH, 09h
  lea DX, [DS:update_d]
  int DOS_API
  mov AH, 02h; восстановить позицию курсора
  mov BH, [CS:saved_page]
  mov DH, [CS:saved_row]
  mov DL, [CS:saved_col]
  int BIOS_API
  mov AH, 01h; восстановить форму и видимость курсора
  mov CH, [CS:saved_start]
  mov CL, [CS:saved_end]
  int BIOS_API
  pop DS
  pop DX
  pop CX
  pop BX
  pop AX
  popf
  ; ***********
  retn
do_it ENDP
  Old09 DD 0; адрес старого вектора прерывания 09h
  update_d DB '1995-10-27 15:46:57$'; дата запуска ЭВМ
  saved_page  DB 0
  saved_row   DB 0
  saved_col   DB 0
  saved_start DB 0
  saved_end   DB 0

; инициализация
Install:
  pushf
  push AX
  push BX
  push DX
  push ES
  push DS

  call NEAR PTR get_datetime

  mov AX, DS:[2Ch]; взять из PSP сегмент окружения
  mov ES, AX
  mov AH, 49h; освободить блок памяти
  int DOS_API

  mov AH, 35h; получить адрес (вектор) текущего обработчика прерывания
  mov AL, 09h; номер вектора прерывания
  int DOS_API
  mov [WORD PTR CS:Old09], BX
  mov [WORD PTR CS:Old09 + 2], ES

  mov AH, 25h; назначить вектор прерывания
  mov AL, 09h; номер вектора прерывания
  lea DX, [CS:TSR_Int09h]
  int DOS_API

  mov AX, CS
  mov DS, AX
  mov AH, 09h
  lea DX, [DS:msg]
  int DOS_API
  lea DX, [DS:update_d]
  int DOS_API

Exit:
  pop DS
  pop ES
  pop DX
  pop BX
  pop AX
  popf

  lea DX, [CS:Install]
  add DX, 15
  mov CL, 4
  shr DX, CL
  mov AX, 3100h; terminate-and-stay-resident program (TSR)
  int DOS_API

; ------------------------------------------------------------
; get_datetime
; Вход: нет
; Выход: строка в update_d, формат 'YYYY-MM-DD HH:MM:SS$'
; Используемые регистры: AX, BX, CX, DX, SI
; ------------------------------------------------------------
get_datetime PROC NEAR
  pushf
  push AX
  push BX
  push CX
  push DX
  push SI

  mov AH, 2Ah; функция получения даты
  int DOS_API; CX = год, DH = месяц, DL = день
  mov year, CX
  mov month, DH
  mov day, DL
  mov AH, 2Ch; функция получения времени
  int DOS_API; CH = час, CL = минута, DH = секунда
  mov hour, CH
  mov minute, CL
  mov second, DH

  ; час (0 - 23)
  mov AL, hour
  mov SI, OFFSET_HH
  call NEAR PTR write_to_update_d

  ; минута (0 - 59)
  mov AL, minute
  mov SI, OFFSET_MI
  call NEAR PTR write_to_update_d

  ; секунда (0 - 59)
  mov AL, second
  mov SI, OFFSET_SS
  call NEAR PTR write_to_update_d

  ; месяц (1 - 12)
  mov AL, month
  mov SI, OFFSET_M
  call NEAR PTR write_to_update_d

  ; день (1 - 31)
  mov AL, day
  mov SI, OFFSET_D
  call NEAR PTR write_to_update_d

  ; год (1980 - 2099)
  mov DX, 0
  mov AX, year
  mov BX, 100
  div BX; AX - частное; DX - остаток
  ; AL - старшая половина 4-значного года, DL - младшая половина 4-значного года
  mov SI, OFFSET_YYYY; старшая половина 4-значного года
  call NEAR PTR write_to_update_d
  mov AL, DL
  mov SI, OFFSET_YYYY + 2; младшая половина 4-значного года
  call NEAR PTR write_to_update_d

  pop SI
  pop DX
  pop CX
  pop BX
  pop AX
  popf
  retn
get_datetime ENDP

; ------------------------------------------------------------
; write_to_update_d
; Вход: регистр AL - целое беззнаковое число от 0 до 99; регистр
; SI - смещение для переменной update_d для формирования числа
; из двух цифр в формате ASCII
; Выход: переменная update_d - представление входного числа в
; формате ASCII в виде двух цифр по указанному смещению
; ------------------------------------------------------------
write_to_update_d PROC NEAR
  push AX
  mov [BYTE PTR CS:bin_d], AL
  call NEAR PTR get_ascii_2digits
  mov AH, [BYTE PTR CS:asc_d]; старшый разряд числа
  mov AL, [BYTE PTR CS:asc_d + 1]; младший разряд числа
  mov [BYTE PTR CS:update_d + SI], AH
  mov [BYTE PTR CS:update_d + SI + 1], AL
  pop AX
  retn
write_to_update_d ENDP

; ------------------------------------------------------------
; get_ascii_2digits
; Вход: переменная bin_d - целое беззнаковое число от 0 до 99
; Выход: переменная asc_d - представление входного числа в
; формате ASCII в виде двух цифр
; ------------------------------------------------------------
get_ascii_2digits PROC NEAR
  mov [BYTE PTR CS:asc_d], '0'
  mov [BYTE PTR CS:asc_d + 1], '0'
  pushf
  push AX
  mov AL, [BYTE PTR CS:bin_d]
  cmp AL, 99
  ja Exit_get_ascii_2digits
  aam; AH - частное; AL - остаток
  or AX, TO_DIGIT + TO_DIGIT * 256; преобразование числа из двоичного формата в формат ASCII
  mov [BYTE PTR CS:asc_d], AH; старшый разряд числа
  mov [BYTE PTR CS:asc_d + 1], AL; младший разряд числа
Exit_get_ascii_2digits:
  pop AX
  popf
  retn
get_ascii_2digits ENDP

msg DB 'The program is staying TSR. Hit LCtrl+LAlt+I to invoke it.', 0Dh, 0Ah, '$'
year        DW 0
month       DB ?
day         DB ?
hour        DB ?
minute      DB ?
second      DB ?
bin_d       DB ?
asc_d       DB '00'

END Start
