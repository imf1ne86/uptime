# `uptime` Utility

This program displays the date on which the current computer session began. It remains resident in memory and is invoked by pressing **LCtrl+LAlt+I**.

- **Executable format:** `.com`
- **Programming language:** Turbo Assembler, version 2.0
- **Source-code encoding:** CP866
- **Executable size:** 504 bytes
- **TSR portion in RAM:** 448 bytes

**System requirements:**
1. IBM PC/AT
2. Real-mode CPU operation
3. DOS

**Build commands:**
```
tasm.exe uptime.asm
tlink.exe /x /t uptime.obj
del uptime.obj
```



# Утилита "uptime"

Данная программа показывает дату запуска текущего сеанса ЭВМ. Программа остаётся резидентной и вызывается пользователем через комбинацию клавиш LCtrl+LAlt+I.

- **Формат компиляции:** ".com"-файл
- **Язык программирования:** Turbo Assembler, ver. 2.0
- **Кодировки исходного кода:** CP866
- **Размер исполнительного файла:** 504 байта
- **Размер TSR-части в ОЗУ:** 448 байт

**Системные требования:**
1) IBM PC AT;
2) реальный режим работы ЦП;
3) операционная система DOS.

**Компиляция программы:**
```
tasm.exe uptime.asm
tlink.exe /x /t uptime.obj
del uptime.obj
```
