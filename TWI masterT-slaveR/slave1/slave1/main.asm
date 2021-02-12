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

	SER R16
	OUT DDRD,R16
	OUT DDRB,R16

	LDI R16,8	;TWBR=(8MHZ/100k-16)/2/4=8 ,velocidad de SCL en 100kHz
	OUT TWBR,R16
	LDI R16,0b01000101	;TWEA,TWEN,TWIE
	OUT TWCR,R16
	LDI R16,0	;Prescaler para SCL en 0
	OUT TWSR,R16	
	LDI R16,0x40	;Dirección Slave 0x20+0	dirección|TWGCE
	OUT TWAR,R16
	SEI
	fin:
		
		RJMP fin

twi:
	;Habilitar TWI  
	//	LDI   R16,0b01000101	;TWEA,TWEN	;Solo si no es por interrupción
	//OUT   TWCR, R16			
	
	;Esperar a que se apague INT
	wait1:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait1				

	;Confirmar SLA+W
	IN R16, TWSR	
	ANDI R16, 0b11111000
	CPI r16, 0x60	;Checar si fue direcicón mismo, ACK transmitido
	BRNE error		

	LDI R16,0b11000101	;TWINT,TWEA,TWEN
	OUT TWCR,R16

	;Esperar a que se termine de recibir dato ACK
	wait2:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait2				

	;Confirmar Dato
	IN R16, TWSR	
	ANDI R16, 0b11111000
	CPI r16, 0x80	;Checar si se recibió correctamente, ACK regresado
	BRNE error	

	LDI R16,0b11000101	;TWINT,TWEA,TWEN
	OUT TWCR,R16

	;Leer dato
	IN R16,TWDR
	OUT PORTD,R16
	RETI

error:
	//SER R16
	//OUT DDRB,R16
	//OUT PORTB,R16
	SBI DDRC,7
	SBI PORTC,7
	RJMP error