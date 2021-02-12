;Master 
.INCLUDE "m16def.inc"
.DEF dataByte=R27	;registro para la dato o intrucción LCD
.ORG 0
RJMP main
.ORG 0x22
RJMP twi
.ORG 0x24	;INT2 botón de STOP general
LDI R18,0b00000001	;código de error para parar las bandas
RETI

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	;Puertos
	SER R16
	OUT DDRD,R16	;Información recibida del slave
	OUT DDRA,R16	;LCD

	CALL initLCD_4bits	;Inicialización LCD
	LDI R30,0	;Registro para indicar si es instrucción 0 o dato 1 para la LCD
	LDI dataByte,0b10000000	;Cambiar direccion del cursor al primer punto
	CALL sendLCD_4bits	;Enviar instrucción
	LDI R30,1	;Enviar dato a continuación
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,' '	
	CALL sendLCD_4bits	
	LDI dataByte,'P'	
	CALL sendLCD_4bits	
	LDI dataByte,'L'	
	CALL sendLCD_4bits
	LDI dataByte,'A'	
	CALL sendLCD_4bits
	LDI dataByte,'N'	
	CALL sendLCD_4bits
	LDI dataByte,'T'	
	CALL sendLCD_4bits
	LDI dataByte,'A'	
	CALL sendLCD_4bits
	LDI R30,0	;Enviar instrucción
	LDI dataByte,0b11000000	;Cambiar direccion del cursor a segunda linea
	CALL sendLCD_4bits	;Enviar instrucción
	LDI R30,1	;Enviar datos a continuación
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,' '	
	CALL sendLCD_4bits
	LDI dataByte,'E'	
	CALL sendLCD_4bits
	LDI dataByte,'M'	
	CALL sendLCD_4bits
	LDI dataByte,'B'	
	CALL sendLCD_4bits
	LDI dataByte,'O'	
	CALL sendLCD_4bits
	LDI dataByte,'T'	
	CALL sendLCD_4bits
	LDI dataByte,'E'	
	CALL sendLCD_4bits
	LDI dataByte,'L'	
	CALL sendLCD_4bits
	LDI dataByte,'L'	
	CALL sendLCD_4bits
	LDI dataByte,'A'	
	CALL sendLCD_4bits
	LDI dataByte,'D'	
	CALL sendLCD_4bits
	LDI dataByte,'O'	
	CALL sendLCD_4bits
	LDI dataByte,'R'	
	CALL sendLCD_4bits
	LDI dataByte,'A'	
	CALL sendLCD_4bits

	;Inicializar twi
	;TWPS=1,  TWBR=(8MHZ/10k-16)/2/4=98	,velocidad de SCL en 10kHz
	LDI R16,98	;SCL de 10kHz, prescaler 1 
	OUT TWBR,R16
	LDI R16,0	;Prescaler 1
	OUT TWSR,R16

	;Interrupciones
	LDI R16,0b00100000	;INT2 BOTÓN STOP genral
	OUT GICR, R16	
	LDI R16,0b00000000	;Detectar INT0 flanco de bajada
	OUT MCUCSR,R16
	SEI	;Habilitar Interrupción
	LDI R31,2	;contador de datos a recibir, se espera recibir de 2 slaves
	ciclo:
		CLT ;T en 0 para recepción(master modo receptor)
		LDI R25,0x40	;enviar a dirección 0x20
		LDI R16,0b10100101 ;TWINT,TWSTA,TWEN,TWIE Enviar condición de START
		OUT TWCR,R16
		CLT ;T en 0 para recepción
		LDI R25,0x42	;enviar para dirección 0x21
		LDI R16,0b10100101 ;TWINT,TWSTA,TWEN,TWIE Enviar condición de START
		OUT TWCR,R16
		CLR R25	;indica la dirección general CALL en registro valor 0
		SET	;T en 1 para transmsión
		LDI R16,0b10100101 ;TWINT,TWSTA,TWEN,TWIE Enviar condición de START
		OUT TWCR,R16
		RJMP ciclo

initLCD_4bits: ;Subrutina de inicialización
	LDI R30,0	;enviar istreucción
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

sendLCD_4bits:	;Subrutina para enviar byte, primero parte alta(4 bits) y luego para baja(4 bits)
	MOV R29,dataByte ;copiar el contenido de dataByte a R24
	ANDI R29,0xF0    ;Aplicar una mascara para conservar solo parte alta        
	ORI R29,0b00000100
	//BLD R29,0	;copiar la bandera T al bit 0 de R24, RS
	ADD R29,R30
	OUT PORTA,R29	;Mostrar por el puerto el registro R24
	CBI PORTA,2	;Poner Enable en 1 
	CALL retardo40us	;llamar retardo de 1ms. Se ha probado con 40us, sin embargo 1ms muestra mejores resultados en la simulación
	SBI PORTA,2	;Poner Enable en 0
	CALL retardo40us ;retardo de 40us
	MOV R29,dataByte ;copiar el contenido de dataByte a R24
	SWAP R29	;Intercambiar parte alta con parte baja
	ANDI R29,0xF0	;Aplicar una mascara para conservar solo parte baja que está guardada en parte alta de R24
	ORI R29,0b00000100
	ADD R29,R30	;copiar la bandera T al bit 0 de R24
	OUT PORTA,R29 ;Mostrar por el puerto el registro R24
	CBI PORTA,2 ;Enable en 1
	CALL retardo40us;llamar retardo de 1ms. Se ha probado con 40us, sin embargo 1ms muestra mejores resultados en la simulación
	SBI PORTA,2 ;Enable en 0
	CALL retardo500us ;retardo de 500us
RET;regresar a donde fue llamada  

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
twi:	
	IN R15,SREG
	PUSH R15	
	;Esperar a que se termine de transmitir START

	wait1:
		IN R16, TWCR
		SBRS R16, TWINT
		RJMP wait1				

	;Confirmar condición de START
	IN R16, TWSR	
	ANDI R16, 0b11111000	;Mascara
	CPI R16, 0x08	;Checar si el START se envió correctamente
	BRNE error1
	;Enviar SLA dirección del SLAVE
	BRTC SLA_R	;Checar si se quiere enviar o recibir
	OUT TWDR, R25		;Dirección del Slave+W
	LDI R16,0b10000101	;TWINT,TWEN,TWIE	
	OUT TWCR, r16			;Enviar
	RJMP wait2	;Esperar a que se termine de enviar
	SLA_R:
		MOV R16,R25
		INC R16 ;Dirección del Slave+R
		OUT TWDR, R16	
		LDI R16,0b10000101	;TWINT,TWEN,TWIE
		OUT TWCR, r16			;Enviar 
		RJMP wait2	;Esperar a que se termine de enviar
	;Esperar a que se termine de transmitir SLA+W/R
error1:
	RJMP error
	wait2:
		IN R16, TWCR
		SBRS R16, TWINT	;Esperar a queTWINT esté en 1
		RJMP wait2				
	;Confirmar SLA+W
	IN R16, TWSR
	ANDI R16, 0b11111000	;Máscara
	BRTC confirmarSLA_R	
	CPI R16, 0x20	;Checar si se recibió SLA+W, ACK no recibido
	BREQ twiSTOP
	CPI R16, 0x18 ;Checar si se recibió SLA+W, ACK recibido
	BRNE  error
	RJMP dataByte1
	confirmarSLA_R:
		CPI R16, 0x48	;Checar si se recibió SLA+R, ACK no recibido
		BREQ twiSTOP
		CPI R16,0x40	;Checar si se recibió SLA+R, ACK recibido
		BRNE  error
	;Enviar dato

	dataByte1:
	CPI R18,0b00000001	;checar si se presionó el stop GENERal
	BRNE enviarPWM	;sino enviar pwm
	OUT TWDR,R18	;enviar el byte 000000001 para indicar que se paren las bandas
	RJMP enviarSeguir	
	enviarPWM:
	BRTC recibirByte
	CP R11,R12	;comparar las dos velocidades
	BRLO enviarR11	;enviar la velocidad más baja
	OUT TWDR,R12
	RJMP enviarSeguir
	enviarR11:
		OUT TWDR,R11
	enviarSeguir:
	LDI R16,0b10000101	;TWINT,TWEN,TWIE		
	OUT TWCR, R16	;Enviar
	RJMP wait3
	recibirByte:
		LDI R16,0b11000101	;TWINT,TWEA,TWEN,TWIE	
		OUT TWCR, R16	
	;Esperar a que este disponible la línea
	wait3:
	IN R16, TWCR
	SBRS R16, TWINT
	RJMP wait3				

	confirmarByte:
	BRTC confirmarRecepcionByte
	IN R16, TWSR
	ANDI R16, 0b11111000
	CPI R16, 0x28	;data byte transmitido ,ACK recibido
	BRNE  error
	RJMP twiStop				
	confirmarRecepcionByte:
		IN R16, TWSR
		ANDI R16, 0b11111000
		CPI R16, 0x50	;data byte recibido ,ACK transmitido
		BRNE  error				
	
		;Liberar la línea y terminar
		LDI R16,0b11000100	;TWINT,TWEA,TWEN
		OUT TWCR,R16

		;Leer dato recibido
		CPI R31,2	
		BREQ leerPrimerByte
		CPI R31,1
		BREQ leerSegundoByte
		leerPrimerByte:
			IN R11,TWDR
			DEC R31
			RJMP twiSTOP
		leerSegundoByte:
			IN R12,TWDR
			LDI R31,2
			RJMP twiSTOP
	;Enviar STOP
	twiStop:
	LDI R16,0b10010101	;TWINT,TWEN,TWSTO,TWIE
	OUT TWCR, r16	
	POP R15
	OUT SREG,R15		
	RETI
			
error:
	SBI DDRC,7
	SBI PORTC,7
	POP R15
	OUT SREG,R15		
	RETI
retardo10ms:
	LDI R20,104
	ciclo2:
		LDI R21,255
	ciclo1:
		DEC R21
		BRNE ciclo1
		DEC R20
		BRNE ciclo2
RET