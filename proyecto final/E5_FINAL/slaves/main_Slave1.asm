;Slave1(mismo para el slave 2, pero cambiando la dirección del slave TWAR=0x43)

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x22
RJMP twi
.ORG 0x24
RJMP stop
main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	;Puertos
	SER R16
	//OUT DDRA,R16	;Puerto D como salia para mostrar byte recibido de master
	OUT DDRD,R16
	SBI DDRC,5
	SBI DDRC,3
	SBI DDRB,3

	;Inicializar twi
	;TWPS=1,  TWBR=(8MHZ/100kHz-16)/2/4=8
	LDI R16,62	;SCL de 100kHz, prescaler 1 
	OUT TWBR,R16
	LDI R16,0b01000101	;TWEA,TWEN,TWIE esperar master
	OUT TWCR,R16
	LDI R16,0	;prescaler de 1
	OUT TWSR,R16
	LDI R16,0x41	;Dirección Slave+1(general call)
	OUT TWAR,R16
	
	;Interrupciones
	LDI R16,0b00100000	;INT2
	OUT GICR, R16
	LDI R16,0b00000000	;Detectar INT2 flanco de bajada
	OUT MCUCR,R16

	;PWM
	LDI R16,0b01101001	;Clear para 0C0,fast PWM, 1024 prescaler	8M/(1024*256)=30.5Hz 
	OUT TCCR0,R16


	LDI R16,0b01100000	;.5V de referencia, ajustamiento a la izquierda, canal 0
	OUT ADMUX,R16
	LDI R16,0b10000111	;ADC enable, prescaler de 128
	OUT ADCSRA,R16 

	SEI	;Habilitar Interrupciones
	
	fin:
		SBI ADCSRA,ADSC
		pollingADC:
			SBIS ADCSRA,ADIF
			RJMP pollingADC
		SBI ADCSRA,ADIF
		//IN R16,ADCL
		IN R24,ADCH
		OUT PORTD,R24
		CPI R25,0b00000001
		BREQ errorSTOP
		OUT OCR0,R25	;Duty Cycle
		RJMP fin
		errorSTOP:
			SBI PORTC,6
			CLR R16
			OUT TCCR0,R16
		RJMP fin


stop:
	PUSH R16
	IN R15,SREG
	PUSH R15

	SBI PORTC,6
	CLR R16
	OUT TCCR0,R16

	POP R15
	OUT SREG,R15
	POP R16
	RETI

twi:		
	IN R15,SREG
	PUSH R15
	;Esperar a que se apague TWINT
	wait1:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait1				
	;Confirmar dirección
	IN R16, TWSR	
	ANDI R16, 0b11111000	;Mascara
	//OUT PORTA,R16	
	CPI R16,0x60	;Checar si fue direcicón mismo+W, ACK transmitido
	BREQ recibir
	CPI R16,0xA0	;Checar si fue direcicón mismo+W
	BREQ recibir
	CPI R16,0x68	;Checar si fue direcicón mismo+W, ACK transmitido
	BREQ recibir
	CPI R16,0xA8	;Checar si fue direcicón mismo+R, ACK transmitido
	BREQ enviar
	CPI R16,0xB0	;Checar si fue direcicón mismo+R, ACK transmitido
	BREQ enviar
	CPI R16,0x70	;Checar si fue general call+W, ACK transmitido
	BREQ recibir
	CPI R16,0x78	;Checar si fue general call+W, ACK transmitido
	BREQ recibir

	RJMP error	
	

	recibir:
		CLT	;T en 0 para recibir
		LDI R16,0b11000101	;TWINT,TWEA,tWEN, twiE
		OUT TWCR,R16	
		RJMP wait2

	enviar:
		SET	;T en 1 para enviar
		;Enviar dato
		OUT TWDR, R24
		LDI R16,0b10000101	;TWINT,TWEN	
		OUT TWCR, R16	;Enviar
	

	;Esperar a que se termine de recibir dato ACK, o a que termine de transmitir el dato
	wait2:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait2				


	;Confirmar Dato
	BRTS confirmarDatoTransmision
	IN R16, TWSR	
	//OUT PORTA,R16
	ANDI R16, 0b11111000	;Mascara
	CPI R16, 0x80	;Checar si se recibió correctamente, ACK transmitido
	BREQ seguirConfirmarDatoRecepcion
	CPI R16,0x90
	BREQ seguirConfirmarDatoRecepcion
	RJMP error
	seguirConfirmarDatoRecepcion:
		RJMP leerDatoRecepcion
		confirmarDatoTransmision:
			IN R16, TWSR	
			ANDI R16, 0b11111000	;Mascara
			CPI R16, 0xC8	;Checar si se transmitió correctamente, ACK regresado
			BRNE error		;--------------------Checar
			LDI R16,0b11000101	;TWINT,TWEA,TWEN
			OUT TWCR,R16
			POP R15
			OUT SREG,R15
			RETI
		

	leerDatoRecepcion:
		LDI R16,0b11000101	;TWINT,TWEA,TWEN
		OUT TWCR,R16
		;Leer dato
		IN R16,TWDR
		MOV R25,R16

	POP R15
	OUT SREG,R15
	RETI

error:
	SBI DDRC,7
	SBI PORTC,7
	//LDI R16,0b11000101	;TWINT,TWEA,TWEN
	//OUT TWCR,R16
	POP R15
	OUT SREG,R15
	RETI 
