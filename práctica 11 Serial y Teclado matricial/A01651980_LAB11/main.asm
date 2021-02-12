.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x2
RJMP tecla
.ORG 0x16
RJMP rx
.DEF dataByte=R25	;registro que se utilizará para byte de instrucción o dataBytes

main:
	;Configuración de apuntador de pila
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16

	;Configuración de puertos, PBA salida para LCD PA0 RS, PA1 RW, PA2 E, PA7-PA4 dataBytes de 4 bits 
	SER R16
	OUT DDRA,R16	;LCD
	SBI DDRD,1	;Tx

	;Inicialización del display LCD
	CALL initLCD_4bits
	LDI R23,33

	;Inicialización del serial
	LDI R16,0b10000110	;asíncrono, sin paridad, 1 bit de stop, enviar 8 bits
	OUT UCSRC,R16
	LDI R16,0b10011000	;RXCIE habilitado, rx y tx habilitado, enviar 8 bits 
	OUT UCSRB,R16
	LDI R16,0	;Baud Rate 9600
	OUT UBRRH,R16
	LDI R16,51
	OUT UBRRL,R16

	;Interupciones
	LDI R16,0b01000000
	OUT GICR,R16
	LDI R16,0b00000010
	OUT MCUSR,R16
	SEI

	fin:
		RJMP fin

tecla:
	IN R15,SREG
	PUSH R15
	IN R20,PINC
	LDI ZH,HIGH(0x0400<<1)
	LDI ZL,LOW(0x0400<<1)
	ADD ZL,R20
	LPM R16,Z
	OUT UDR,R16
	polling:
		SBIS UCSRA,UDRE
		RJMP polling
	POP R15
	OUT SREG,R15
	RETI

rx:
	IN R15,SREG
	PUSH R15
	IN R16,UDR
	DEC R23
	BREQ primeraLinea
	CPI R23,16
	BREQ segundaLinea
	RJMP rxRETI
	primeraLinea:
		CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
		LDI dataByte,0x01 ;Clear display
		CALL sendLCD_4bits
		LDI R23,33
		LDI dataByte,0b10000000	;Cambiar direccion del cursor al primer punto
		CALL sendLCD_4bits	;Enviar instrucción
	segundaLinea:
		CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
		LDI dataByte,0b11000000	;Cambiar direccion del cursor al primer punto
		CALL sendLCD_4bits	;Enviar instrucción
	rxRETI:
		SET
		MOV dataByte,R16
		CALL sendLCD_4bits	;Enviar dato
		POP R15
		OUT SREG,R15
		RETI	

sendLCD_4bits:	;Subrutina para enviar byte, primero parte alta(4 bits) y luego para baja(4 bits)
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	ANDI R24,0xF0    ;Aplicar una mascara para conservar solo parte alta        
	ORI R24,0b00000100
	BLD R24,0	;copiar la bandera T al bit 0 de R24, RS
	OUT PORTA,R24	;Mostrar por el puerto el registro R24
	CBI PORTA,2	;Poner Enable en 1 
	CALL retardo40us	;llamar retardo de 1ms. Se ha probado con 40us, sin embargo 1ms muestra mejores resultados en la simulación
	SBI PORTA,2	;Poner Enable en 0
	CALL retardo40us ;retardo de 40us
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	SWAP R24	;Intercambiar parte alta con parte baja
	ANDI R24,0xF0	;Aplicar una mascara para conservar solo parte baja que está guardada en parte alta de R24
	ORI R24,0b00000100
	BLD R24,0	;copiar la bandera T al bit 0 de R24
	OUT PORTA,R24 ;Mostrar por el puerto el registro R24
	CBI PORTA,2 ;Enable en 1
	CALL retardo40us;llamar retardo de 1ms. Se ha probado con 40us, sin embargo 1ms muestra mejores resultados en la simulación
	SBI PORTA,2 ;Enable en 0
	CALL retardo500us ;retardo de 500us
RET;regresar a donde fue llamada 

initLCD_4bits: ;Subrutina de inicialización
	CLT ;Setear bandera T para inidicar que los bytes son de instrucción
	;Inicialización
	CALL retardo10ms;retardo de 10ms
	LDI dataByte,0x28	;Modo 4 bits,2 líneas,Font 5x7 
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms	;retardo de 10ms
	LDI dataByte,0x06  ;Modo incremental del cursor y apagar el desplazamiento shif
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms ;retardo 10ms
	LDI dataByte,0x0F ;Cursor ON, Display ON, modo blink
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms ;retardo 10ms
	LDI dataByte,0x01 ;Clear display
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms ; retardo de 10ms
RET
	
retardo10ms:
	PUSH R20
	PUSH R21
	LDI R20,104
	ciclo2:
		LDI R21,255
	ciclo1:
		DEC R21
		BRNE ciclo1
		DEC R20
		BRNE ciclo2
		POP R21
		POP R20 
RET
retardo500us:
	PUSH R20
	PUSH R21
	LDI R20,5
	ciclo3:
		LDI R21,255
	ciclo4:
		DEC R21
		BRNE ciclo4
		DEC R20
		BRNE ciclo3
		POP R21
		POP R20 
RET
retardo40us:
	PUSH R20
	PUSH R21
	LDI R20,24
	ciclo5:
		LDI R21,3
	ciclo6:
		DEC R21
		BRNE ciclo6
		DEC R20
		BRNE ciclo5
		POP R21
		POP R20 
RET	

.ORG 0x400
.DB '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'