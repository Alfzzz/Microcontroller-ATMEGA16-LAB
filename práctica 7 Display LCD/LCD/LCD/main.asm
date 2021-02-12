.ORG 0
.INCLUDE "m16def.inc"
.DEF dataByte=R25	;registro que se utilizará para byte de instrucción o dataBytes

;Configuración de apuntador de pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuración de puertos, PBA salida para LCD PA0 RS, PA1 RW, PA2 E, PA7-PA4 dataBytes de 4 bits 
SER R16
OUT DDRA,R16

;Inicialización del display LCD
CALL initLCD_4bits

CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
LDI dataByte,0b10000000	;Cambiar direccion del cursor al primer punto
CALL sendLCD_4bits	;Enviar instrucción


SET ;Setear bandera T para indicar que se enviarán byte de dataBytes de caracteres
LDI dataByte,0x22	; comilla doble
CALL sendLCD_4bits	;Escribir comilla doble "

CALL Ciclo5Espacios	;llamar Subrutina para escribir 5 espacios seguidos

LDI dataByte,0x48	;H
CALL sendLCD_4bits	;;Escrbir H
LDI dataByte,0x4F	;O
CALL sendLCD_4bits	;;Escrbir O
LDI dataByte,0x4c	;L
CALL sendLCD_4bits ;Escrbir L
LDI dataByte,0x41	;A
CALL sendLCD_4bits	;Escrbir A

CALL Ciclo5Espacios	;Subrutina para escribir 5 espacios seguidos

LDI dataByte,0x22	;comilla doble
CALL sendLCD_4bits	;Escribir comilla doble

CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
LDI dataByte,0b11000000	;Cambiar direccion del cursor al primero de la segunda línea
CALL sendLCD_4bits	;Enviar nstrucción

SET;Setear bandera T para indicar que se enviará byte de dataBytes de caracteres
LDI dataByte,0x22	;comilla doble
CALL sendLCD_4bits	;Escribir comilla doble "

CALL Ciclo4Espacios ;Subrutina para escribir 4 espacios seguidos

LDI dataByte,0x4D	;M
CALL sendLCD_4bits	;Escribir M
LDI dataByte,0x55	;U
CALL sendLCD_4bits	;Escribir U
LDI dataByte,0x4E	;N
CALL sendLCD_4bits	;Escribir N
LDI dataByte,0x44	;D
CALL sendLCD_4bits	;Escribir D
LDI dataByte,0x4F	;O
CALL sendLCD_4bits	;Escribir O
LDI dataByte,0x21	;!
CALL sendLCD_4bits	;Escribir !

CALL Ciclo4Espacios	;Subrutina para escrbir 4 espacios seguidos

LDI dataByte,0x22	;"
CALL sendLCD_4bits	;Escribir "

Fin:	;Termina la escritura
 RJMP Fin
 ;;;;;;;;;;;;;, Subrutinas ;;;;;;;;;;;
Ciclo4Espacios: ;subrutina para escribir 4 espacios seguidos
	LDI R19,4	;Cargar a un registro el valor 4
	Espacios4:	
		SET	;Setear bandera T para indicar que se envia byte de dataByte de caracter
		LDI dataByte,0x20	;espacio
		CALL sendLCD_4bits	;Escribir espacio
		DEC R19	;decrementar registro R19
		BRNE Espacios4	;Volver a realizar hasta alcanzar 4 ciclos
RET ;Regresar a donde fue llamada


Ciclo5Espacios:	;subrutina para escribir 4 espacios seguidos
	LDI R19,5	;Cargar a un registro el valor 4
	Espacios5:	
		SET	;Setear bandera T para indicar que se envia byte de dataByte de caracter
		LDI dataByte,0x20 ;espacio
		CALL sendLCD_4bits	;escribir espacio
		DEC R19	;decrementar registro R19
		BRNE Espacios5 ;vlover a realizar hasta alcanzar 5 ciclos
RET; regresar a donde fue llamada

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

retardo1ms:
	PUSH R20
	PUSH R21
	LDI R20,20
	ciclo8:
		LDI R21,135
	ciclo7:
		DEC R21
		BRNE ciclo7
		DEC R20
		BRNE ciclo8
		POP R21
		POP R20 
RET