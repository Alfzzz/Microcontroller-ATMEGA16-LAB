;
; practica12.asm
;
; Created: 23-Nov-20 12:18:21 PM
; Author : mata
;


.include "m16def.inc"

.def LCD = R20
; D7-D6-D5-D4-BL-E-RW-RS
.def BIN_LSB=R22
.def BIN_MSB=R23
.def ASCII = R17

.org 0 
	RJMP main

.org 0x1C
	RJMP ADC_CONV


main: 

;Puntero
LDI R16, HIGH (RAMEND)
OUT SPH, R16
LDI R16, LOW (RAMEND)
OUT SPL, R16
;Configuracion puntero RAM
LDI XL, LOW(0x60)
LDI XH, HIGH(0x60)

;Puertos
SER R16
OUT DDRC, R16	;puerto A como salida
SBI PORTC, 2	;preparar enable de LCD 

;inicializacion de LCD
CALL delay10ms
CALL initLCD_4bits

;configuracion de ADC
LDI R16, 0B11100000		;INTERNAL 2.56V, RIGHT, ADC0
OUT ADMUX, R16

LDI R16, 0B10101111		;ENABLE, NO START, AUTO TRIGGER, - , INTERRUPT, 128 PRE
OUT ADCSRA, R16

SEI

SBI ADCSRA, 6		;INICIAR CONVERSION

FIN: 
RJMP FIN


ADC_CONV:
	IN R16,SREG
	PUSH R16

	CALL readADC
	CALL writeLCD

	POP R16
	OUT SREG, R16
	SBI ADCSRA, 6	
RETI


readADC:
	IN R16, ADCH	;LEER ADC (HIGH)
	MOV BIN_LSB, R16
	CALL BIN_BCD
RET

writeLCD:
	LDI XL, LOW(0x60)	;reiniciar apuntadores 
	LDI XH, HIGH(0x60)
	LDI ASCII, 0X30
	LDI R25, 0x80		;PRIMERA POSICION LCD
	CLT
	CALL sendLCD_4bits
	LD R25, X+
	ADD R25, ASCII
	SET
	CALL sendLCD_4bits	;X000
	LD R25, X+
	ADD R25, ASCII
	SET
	CALL sendLCD_4bits	;0X00
	LD R25, X+
	ADD R25, ASCII
	SET
	CALL sendLCD_4bits	;00X0
	LD R25, X+
	ADD R25, ASCII
	SET
	CALL sendLCD_4bits	;000X
RET


initLCD_4bits:
	;function set: 0b001010XX
	LDI R25, 0b00101000
	CLT		; T=0 - inst
	CALL sendLCD_4bits
	CALL delay10ms
	;display on/off control
	LDI R25, 0b00001111
	CLT
	CALL sendLCD_4bits
	CALL delay10ms
	LDI R25, 0b00000001
	CLT
	CALL sendLCD_4bits
	CALL delay10ms
RET

; R25 = data a enviar
; T= 1-data / 0-inst
sendLCD_4bits:
	PUSH LCD
	MOV LCD,R25
	ANDI LCD, 0b11110000
	ORI LCD, 0b00000100		; BL=0 E=1
	BLD LCD, 0				; carga T a bit0
	OUT PORTC, LCD

	CBI PORTC, 2			;E=0
	CALL delay40us
	SBI PORTC, 2
	CALL delay40us
	MOV LCD,R25
	SWAP LCD
	ANDI LCD, 0b11110000
	ORI LCD, 0b00000100		; BL=0 E=1
	BLD LCD, 0				; carga T a bit0
	OUT PORTC, LCD
	CBI PORTC, 2			;E=0
	CALL delay40us
	SBI PORTC, 2
	CALL delay40us
	POP LCD
RET

; Espacio de memoria en RAM donde se guarda el número convertido en BCD
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

; lógica: se incrementa el número BCD mientras se decrementa el binario hasta que sea 0.
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

delay10ms:	
	PUSH R19
	PUSH R20
	LDI R19, 104
loop3:	
		LDI R20 ,255 
loop4:	
		DEC R20 
		BRNE loop4
		DEC R19
		BRNE loop3
	POP R20
	POP R19
RET

delay40us:	
	PUSH R19
	PUSH R20
	LDI R19, 1
loop5:	
		LDI R20 ,125 
loop6:	
		DEC R20 
		BRNE loop6
		DEC R19
		BRNE loop5
	POP R20
	POP R19
RET