;
; LED_test.asm
;
; Created: 06-Feb-19 3:59:57 PM
; Author : mata
;
.def leds = R22

.org 0 
.include "m16def.inc"

;Definicion del puntero
LDI R16, HIGH (RAMEND)
OUT SPH, R16
LDI R16, LOW (RAMEND)
OUT SPL, R16

;Configuracion puntero RAM
LDI XL, LOW(0x60)
LDI XH, HIGH(0x60)
LDI R16, 10
LDI R17, 0x22

MOV R24, R17

loop:
ST X+, R17
DEC R16
BRNE loop

;Hasta aqui memoria RAM

SER R16
OUT DDRA, R16
LDI R23, 8
CLR leds
SEC		; C=1
izq:
ROL leds
OUT PORTA, leds
CALL delay100ms
DEC R23
BRNE izq
LDI R23, 8
der:
ROR leds
OUT PORTA, leds
CALL delay100ms
DEC R23
BRNE der


FIN:
RJMP FIN


delay10ms:	LDI R19, 104
	loop1:	LDI R20 ,255 
	loop2:	DEC R20 
			BRNE loop2
			DEC R19
			BRNE loop1
RET 

delay100ms:
		LDI R21, 10
loop3:	CALL delay10ms
		DEC R21
		BRNE loop3
RET
