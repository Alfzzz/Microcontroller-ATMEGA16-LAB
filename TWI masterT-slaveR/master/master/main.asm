.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x22
RJMP twi
main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	SBI DDRA,7
	;Inicializar 
	LDI R16,8
	OUT TWBR,R16 ;TWBR=(8MHZ/100k-16)/2/4=8 ,velocidad de SCL en 100kHz
	LDI R16,0
	OUT TWSR,R16	;Prescaler de 0

	
	fin:
		SBIS PINA,0	
		RJMP activarTWI	;activar twi cuando PA0 est� en 0
		RJMP fin
		activarTWI:
			SEI	;habilitar interrupciones
			SBI PORTA,7	;mostrar por una l�nea de que se va activar twi
			LDI R16,0b10100101 ;mandar condici�n de START TWINT,TWSTA,TWEN,TWIE
			OUT TWCR,R16
			SEI
			RJMP fin

twi:
	;Enviar START

	//LDI   R16,0b10100101	;TWINT,TWSTA,TWEN	;Condici�n de STart, usar si no es interrupci�n
	//OUT   TWCR, R16			
	
	;Esperar a que se termine de transmitir START
	wait1:
	IN R16, TWCR
	SBRS R16, TWINT	;Cuando la bandera INT se activa, indica que la l�nea est� libre
	RJMP wait1				

	;Confirmar condici�n de START
	IN R16, TWSR	
	ANDI R16, 0b11111000
	CPI r16, 0x08	;Checar si se transmiti� correctamente START 
	BRNE error				

	;Enviar SLA+W	W en 0,R en 1
	LDI R16,0x40	;Direcci�n 0x20|W
	OUT TWDR, R16	
	LDI R16,0b10000101	;TWINT,TWEN,TWIE
	OUT TWCR, r16			;Enviar

	;Esperar a que se termine de transmitir SLA+W
	wait2:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait2				

	;Confirmar SLA+W
	IN R16, TWSR
	ANDI R16, 0b11111000
	CPI R16, 0x18	;Checar si se recibi� SLA+W, ACK recibido
	BRNE  error				

	;Enviar dato
	LDI R16, 0b11001100	; Data
	OUT TWDR, R16
	LDI R16,0b10000101	;TWINT,TWEN	
	OUT TWCR, R16			

	;Esperar a que se termine de transmitir SLA+W
	wait3:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait3				

	;Confirmar
	IN R16, TWSR
	ANDI R16, 0b11111000
	CPI R16, 0x28	;data byte transmitido ,ACK recibido
	//BRNE  error				

	;Enviar STOP
	LDI R16,0b10010101	;TWINT,TWEN,TWSTO
	OUT TWCR, r16			
	RETI
			


error:
	SBI DDRD,4
	SBI PORTD,4
	RJMP error
