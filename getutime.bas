Rem Получение даты от uptime
'
' * *************************
' * Программа написана на языке программирования PowerBASIC, ver. 2.10f.
' *
' * @author Ефремов А. В., 03.11.2026
'

LET appName$ = "uptime": ' наименование искомого ПО
LET appEntryOffset% = &H100 - 14: ' точка входа в искомое ПО
LET appOffset% = 161: ' смещение для переменной со значением даты uptime
LET appStringLength% = 19: ' "1995-10-27 15:46:57"

' https://stanislavs.org/helppc/int_21-52.html
REG 1, &H5200: CALL INTERRUPT &H21: ' the pointer to the DOS "invars" table
LET es& = toLong(REG(9)): LET bx& = toLong(REG(2)) - 2&
DEF SEG = es&: LET mcbseg& = toLong(PEEKI(bx&))

LET found% = 0
DO
  DEF SEG = mcbseg&: ' сегмент MCB (Memory Control Block)
  LET bType$ = PEEK$(&H0, 1)
  LET wOwner% = PEEKI(&H1)
  LET wSize& = toLong(PEEKI(&H3))
  LET sName$ = PEEK$(&H8, 8): ' имя работающего в оперативной памяти ПО
  REPLACE ANY CHR$(0) WITH CHR$(32) IN sName$
  LET sName$ = LCASE$(LTRIM$(RTRIM$(sName$)))
  IF wOwner% <> 0 AND sName$ <> "" THEN
    IF sName$ = appName$ THEN
      LET found% = 1
      EXIT LOOP
    END IF
  END IF
  LET mcbseg& = mcbseg& + wSize& + 1&
LOOP UNTIL (mcbseg& < 0& OR mcbseg& > 65535& OR bType$ = "Z")
IF found% THEN
  PRINT "The TSR app of " + CHR$(34) + appName$ + CHR$(34) + " is found."
  LET uptimeseg& = toLong(wOwner%)
  PRINT "The entry point is at [" + HEX$(uptimeseg&) + "h:" + HEX$(appEntryOffset%) + "h]."
  DEF SEG = uptimeseg&
  PRINT "Uptime: " + PEEK$(appEntryOffset% + appOffset%, appStringLength%)
ELSE
  PRINT "There is no TSR " + CHR$(34) + appName$ + CHR$(34) + " app in RAM."
END IF

PRINT "Hit Esc to continue..."
WHILE INKEY$ <> CHR$(27): WEND
END

' преобразование 16-битного знакового числа в 32-битное беззнаковое
FUNCTION toLong(x%)
  LET bign& = CVL(MKI$(x%) + MKI$(0))
  toLong = bign&
END FUNCTION
