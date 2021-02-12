.INCLUDE "m16def.inc"
.ORG 0	;Reset
RJMP main
.ORG 2	;INT0
RJMP bttnIncremento
.ORG 4	;INT1
RJMP bttnDecremento
.ORG 6	;Timer 2 compare
RJMP switchIncremento10ms
.ORG 0x26	;Timer 0 compare
RJMP refresh


main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16


	;Configración de puertos   
	LDI R16,0xFF
	OUT DDRB,R16 ;Puerto B como salida	barrido|BCD

	;Interrupciones
	LDI R16,0b10000010	;OCIE2 y OCIE0 habilitado
	OUT TIMSK,R16
	LDI R16,0b11000000	;habilitar ,INT1,INT0 para los dos botones
	OUT GICR,R16
	LDI R16,0b00001111	;Detectar flanco de subida para INT1 e INT0 
	OUT MCUCR,R16
	SEI	;Habilitar interrupciones

	;Preparar refrescamiento	
	LDI XH,HIGH(0x60)	;Apuntador a RAM para los displays
	LDI XL,LOW(0x60)
	LDI R24,4	;contador de digitos 
	LDI R25,0b00010000	;Código de barrido para 4 displays 7seg cátodo común 

	;Configurar timers
	;Timer 0 para refrescar displays
	LDI R16,64;OCR0=(1/(n*30Hz))/(1024*Tc)-1=(1/(4*50))/(1024*125ns)-1=64
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC prescaler de 1024 para timer 0
	OUT TCCR0,R16
	;Timer 2 para incrementar dado el caso que el switch 1 esté activo
	LDI R16,77 ;10ms,  OCR2=10ms/(1024*Tc)-1=10ms/(1024*125ns)-1=77
	OUT OCR2,R16
	
	;Cargar valores a RAM para los cuatro displays
	CLR R16	;Cargar 0 al inicio
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16
	polling:
			SBIC PIND,0	;Leer el switch 1
			RJMP ActivarTimer2	;Activar dado caso que el switch 1 esté en 1
			SBIS PIND,1	;Leer el switch 2
			RJMP Mostrar0	;Mostrar 0 y apagar timer 2 si está en 0
			RJMP polling	;Volver a leer
			ActivarTimer2:
				LDI R16,0b00001111 ;CTC prescaler de 1024 para timer 2
				OUT TCCR2,R16	
				RJMP polling	;Volver a leer
			Mostrar0:
				CLR R16	;Resetear contador BCD
				STS 0x60,R16	;Resetear millares
				STS 0x61,R16	;Resetear centenas
				STS 0x62,R16	;Resetear decenas
				STS 0x63,R16	;Resetear unidades
				OUT TCCR2,R16	;Apagar timer 2
				RJMP Polling	;Volver a leer
				
				
bttnIncremento:

	IN R16,SREG	;Salvar entorno
	PUSH R16
	SBIS PIND,1	;Leer switch 2
	RJMP bttnIncrementoRETI	;Salir si está desactivado el switch
	CALL retardo10ms	;Rebote
	SBIS PIND,2	;Checar si fue ruido
	RJMP bttnIncrementoRETI	;Salir si fue ruido
	SEI	;dejar que entre la interrupción de refresh
	bttnIncrementoPolling:	;Esperar a que suelte el botón
		SBIC PIND,2	
		RJMP bttnIncrementoPolling
	CALL retardo10ms	;Botón soltado después de10ms
	CALL incremento	;Incrementar contador BCD
	bttnIncrementoRETI:
		POP R16
		OUT SREG,R16
		RETI

incremento:
	;Incrementar BCD
	CLR R17 ;registro para resetear después
	LDS R16,0x63	;Leer unidades
	INC R16	
	STS 0x63,R16
	CPI R16,10
	BRNE incrementoRET
	STS 0x63,R17 ;Resetear si unidades llegó a 10
	LDS R16,0x62	;Leer decenas
	INC R16
	STS 0x62,R16
	CPI R16,10
	BRNE incrementoRET
	STS 0x62,R17	;Resetear si decenas llegó a 10
	LDS R16,0x61	;Leer centenas
	INC R16
	STS 0x61,R16
	CPI R16,10
	BRNE incrementoRET
	STS 0x61,R17	;Resetear centenas
	LDS R16,0x60	;Leer Millares
	INC R16
	STS 0x60,R16
	CPI R16,10
	BRNE incrementoRET
	STS 0x60,R17	;Resetear millares
	incrementoRET:
		RET
		
bttnDecremento:
	IN R16,SREG
	PUSH R16

	SBIS PIND,1	;Leer switch 2
	RJMP bttnIncrementoRETI	;Salir si el switch está desactivado
	CALL retardo10ms	;Rebote
	SBIS PIND,3	;Checar si fue ruido
	RJMP bttnDecrementoRETI	;Salir si fue ruido
	SEI	;dejar que entre la interrupción de refresh
	bttnDecrementoPolling:	;Esperar a que se suelte el botón
		SBIC PIND,3
		RJMP bttnDecrementoPolling
	CALL retardo10ms	;Botón suelto

	;Decrementar BCD
	LDI R17,9 ;registro para poner en 9 después
	LDS R16,0x63	;Leer unidades
	DEC R16
	STS 0x63,R16
	CPI R16,255
	BRNE bttnDecrementoRETI
	STS 0x63,R17 ;poner unidades en 9 si llegó a menor de 0
	LDS R16,0x62	;Leer decenas
	DEC R16
	STS 0x62,R16
	CPI R16,255
	BRNE bttnDecrementoRETI
	STS 0x62,R17	;poner decenas en 9 si llegó a menor de 0
	LDS R16,0x61	;Leer centenas
	DEC R16
	STS 0x61,R16
	CPI R16,255
	BRNE bttnDecrementoRETI
	STS 0x61,R17	;poner centenas em 9 si llegó a menor de 0
	LDS R16,0x60	;Leer Millares
	DEC R16
	STS 0x60,R16
	CPI R16,255
	BRNE bttnDecrementoRETI
	STS 0x60,R17	;poner millares en 9 si llegó a menor de 0
	bttnDecrementoRETI:
		POP R16
		OUT SREG,R16
		RETI
		
refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	MOV R20,R25	;código de barrido a R20
	ANDI R20,0xF0	;Enmascarar código de barrido
	ADD R0,R20	;Sumar número a mostrar en parte baja
	OUT PORTB,R0	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador de digitos
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero a RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b00010000	;código de barrido para display7seg cátodo común x4
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI

switchIncremento10ms:
	IN R16,SREG	;Salvar entorno
	PUSH R16
	CALL incremento	;Incrementar contador BCD
	POP R16
	OUT SREG,R16
	RETI
	
retardo10ms:	;Subrutina de retardo de 10ms
	LDI R20,104
	ciclo2:
		LDI R21,255
	ciclo1:
		DEC R21
		BRNE ciclo1
		DEC R20
		BRNE ciclo2
RET
