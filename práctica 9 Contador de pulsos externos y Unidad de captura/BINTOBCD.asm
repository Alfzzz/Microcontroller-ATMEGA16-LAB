.include "m16def.inc"
.org 0

-- registros de donde se tomará el número binario a transformar
.def BIN_LSB=R22
.def BIN_MSB=R23

ldi r16,low(RAMEND)
out SPL,r16
ldi r16,high(RAMEND)
out SPH,r16	     ;init Stack Pointer

CALL BIN_BCD

FIN:RJMP FIN

-- Espacio de memoria en RAM donde se guarda el número convertido en BCD
BIN_BCD: CLR R16
         STS 0x60,R16
	     STS 0x61,R16
	     STS 0x62,R16
	     STS 0x63,R16

    otro:  CPI BIN_LSB,0
           BRNE INC_BCD
           CPI BIN_MSB,0
           BRNE INC_BCD
           RET

-- lógica: se incrementa el número BCD mientras se decrementa el binario hasta que sea 0.
  INC_BCD: LDI R17,0
	      LDI YL,0x63
	      LDI YH,0

     ciclo: LD R20,Y
            inc R20
	      ST Y,R20
	      CPI R20,10
	      BRNE DEC_BIN
	      ST Y, R17
	      DEC YL
	      CPI YL,0x5F
	      BRNE ciclo

DEC_BIN: DEC BIN_LSB
         CPI BIN_LSB,0xFF
         BRNE otro
         DEC BIN_MSB
         RJMP otro
