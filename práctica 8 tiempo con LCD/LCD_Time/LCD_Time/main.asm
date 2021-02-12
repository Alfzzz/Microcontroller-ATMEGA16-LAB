.ORG 0
.INCLUDE "m16def.inc"
.DEF dataByte=R23
;Configuración de puntero de pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16
//CALL retardo40us
;Configración de puertos
SER R16
OUT DDRA,R16 ;Puerto A como salida,
CLR R16
OUT DDRC,R16	;Switches PC0 Y PC1,botones PC2 y PC3
SBI DDRB,3	;Salida de PWM y Switch
CALL initLCD_4bits	;Inicialización deLCD
CLR R16	;Limpiar Unidades y Decenas
CLR R17	;Limpiar Centenas y Millares
LDI R19,128	;Empezar el PWM con ducy Cycle de 50% aprox
ClearDisplay1:
	CLT	
	LDI dataByte,0x01 ;Clear display
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms	

	LecturaPrimerSwitch:	;lectura del primer Switch
		SBIS PINC,0	;Leer el valor del primer switch(activo en 1)
		RJMP ClearDisplay2	;Si el switch 1 no está activo, hacer lectura del segundo switch 
		CALL enviarTiempo	;Enviar el tiempo por LCD
		CALL Incremento	;Si el switch sí está activo, incrementar 1 al llamar subrutina Incremento 
		CALL retardo10ms ; hacer un retardo de 10ms
		CLR R20	;Resetear R20
		OUT TCCR0,R20	;apagar el timer 0, para que deje de mostrar cuando esté el primer switch activo
		SBIC PINC,0	;Checar si el switch 1 se desactivo
	RJMP LecturaPrimerSwitch	;En el caso de no esté apagado volver a incrementar
	ClearDisplay2:	;Si se apagó el switch 1, limpiar pantalla
		CLT
		LDI dataByte,0x01 ;Clear display
		CALL sendLCD_4bits ;enviar
		CALL retardo10ms
	LecturaSegundoSwitch:	;lectura del segundo switch
		SBIS PINC,1	;Leer el valor del segundo switch(activo en 1)
		RJMP NingunSwitchActivo	;Si el segundo switch no está activo,volver a hacer lectura del primer switch
		;Eliminador de rebote para el primer botón
		SBIC PINC,2	;Botón de incremento activo en 0
		RJMP SegundoBttn	;Leer botón 2 en caso de que el primero no está activo
		CALL retardo10ms	;antirebote
		SBIC PINC,2
		RJMP SegundoBttn	;Tomar valor para ver si fue ruido
		CALL retardo10ms
		INC R19	;Incrementar duty cycle si se presionó botón 1
		CPI R19,0 ;checar si se pasó del 100%
		BRNE SegundoBttn	;Leer botón 2 en caso de que no se haya pasado
		DEC R19	;Decrementar 1 para que se mantenga en duty cycle de 100%
		SegundoBttn:
			SBIC PINC,3	;Botón para decrementar activo en 0
			RJMP SeguirSegundoBttn	;Terminar de leer si el botón 2 no está activo
			CALL retardo10ms	;Antirebote
			SBIC PINC,3	;
			RJMP SeguirSegundoBttn	;Tomar valor para ver si fue ruido
			CALL retardo10ms	;antirebote
			DEC R19	;decrementar duty cycle si segundo botón se presionó
			CPI R19,255	;checar si bajó por menor de 0 el duty cycle
			BRNE SeguirSegundoBttn	;Terminar el proceso de lectura de botones
			INC R19	;Mantener el duty cycle más bajo posible si se sigue decrementando
		SeguirSegundoBttn:
			OUT OCR0,R19	;Sacar el valor a comparar para el timer 0
			LDI R20,0b01101101	;Palabra de control, Modo no invertido, clear, prescaler de 1024,modo CTC
			OUT TCCR0,R20	;Activar el Timer 0
			CLT	;Instrucción de LCD
			LDI dataByte,0b11000111	;Posición del cursor en 2da línea centrada
			CALL sendLCD_4bits	;Enviar instrucción
			SET	;Dato
			LDI dataByte,'P'	
			CALL sendLCD_4bits	;Escribir P de PWN
			LDI dataByte,'W'	
			CALL sendLCD_4bits ;Escribir W de PWN
			LDI dataByte,'M' 
			CALL sendLCD_4bits ;Escribir M de PWN
			SBIC PINC,1	;Volver a leer switch 2
			RJMP LecturaSegundoSwitch	;Si el switch 2 sigue encendido, volver a correr el proceso
			RJMP LecturaPrimerSwitch	;Caso contrario, leer el switch 1
			NingunSwitchActivo:	;Si ningún switch se activó, se hace lo siguiente
				CALL MensajeACTIVESWITCH	;Enviar mensaje para activar switch
				CLR R20	
				OUT TCCR0,R20	;Parar el PWM
				SBIC PINC,0	;Leer el switch 1
				RJMP ClearDisplay1	;Irse a etiqueta ClearDisplay1
				SBIC PINC,1	;Leer el switch2
				RJMP ClearDisplay2	;Irse a etiqueta ClearDisplay2
				RJMP NingunSwitchActivo	;Si ningún switch se ativó, volver a mandar el mensaje


sendLCD_4bits:	;Subrutina para enviar byte, primero parte alta(4 bits) y luego para baja(4 bits)
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	ANDI R24,0xF0    ;Aplicar una mascara para conservar solo parte alta        
	ORI R24,0b00000100	;Enable en 1
	BLD R24,0	;copiar la bandera T al bit 0 de R24, RS
	OUT PORTA,R24	;Mostrar por el puerto el registro R24
	CBI PORTA,2	;Poner Enable en 1 
	//CALL retardo40us	;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	SBI PORTA,2	;Poner Enable en 0
	//CALL retardo40us ;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	SWAP R24	;Intercambiar parte alta con parte baja
	ANDI R24,0xF0	;Aplicar una mascara para conservar solo parte baja que está guardada en parte alta de R24
	ORI R24,0b00000100
	BLD R24,0	;copiar la bandera T al bit 0 de R24
	OUT PORTA,R24 ;Mostrar por el puerto el registro R24
	CBI PORTA,2 ;Enable en 1
	//CALL retardo40us;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	SBI PORTA,2 ;Enable en 0
	CALL retardo40us ;retardo de 500us
RET;regresar a donde fue llamada 

initLCD_4bits: ;Subrutina de inicialización
	CLT ;Setear bandera T para inidicar que los bytes son de instrucción
	;Inicialización
	CALL retardo10ms;retardo de 10ms
	LDI dataByte,0x28	;Modo 4 bits,2 líneas,Font 5x7 
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms	;retardo de 10ms
	LDI dataByte,0x0F ;Cursor ON, Display ON, modo blink
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms ;retardo 10ms
	LDI dataByte,0x01 ;Clear display
	CALL sendLCD_4bits ;enviar
	CALL retardo10ms ; retardo de 10ms
RET

enviarTiempo:
	CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
	LDI dataByte,0b10000110	;Posición del cursor 1ra línea centrado para escribir tiempo xx:xx
	CALL sendLCD_4bits	;Enviar instrucción
	SET
	MOV R24,R16	;Obtener el tiempo parte alta(Millares y Centenas)
	SWAP R24	;cambiar Millares con centenas
	ANDI R24,0x0F	;Mascara para guardar millares
	LDI dataByte,0x30	;Empezar el dataByte con 0x30
	ADD dataByte,R24	;Suma con millares, así se obtiene el ASCII correspondiente
	CALL sendLCD_4bits	;enviar
	MOV R24,R16	;Obtener el tiempo parte alta(millares y centenas)
	ANDI R24,0x0F	;mascara para mantener centenas
	LDI dataByte,0x30	
	ADD dataByte,R24	;ASCII centenas
	CALL sendLCD_4bits
	LDI dataByte,0x3A	;ASCII de ":"
	CALL sendLCD_4bits
	MOV R24,R17	;Obtener el tiempo parte baja(decenas y unidades)
	SWAP R24	
	ANDI R24,0x0F	;Mascara para mantener decenas
	LDI dataByte,0x30	
	ADD dataByte,R24 ;ASCII decenas
	CALL sendLCD_4bits
	MOV R24,R17	;Obtener el tiempo parte baja(decenas y unidades)
	ANDI R24,0x0F	;Mascara para mantener unidades
	LDI dataByte,0x30	
	ADD dataByte,R24	;ASCII unidades
	CALL sendLCD_4bits
RET

Incremento:	;Subrutina de Incremento
	unidades:	;Para las unidades
		INC R17	;Incrementar R17 donde se guarda el valor de las unidades
		LDI R18,0x0F	;R18 es un registro para guardar la mascara
		AND R18,R17		;Aplicar la mascara para leer solamente el valor de la parte baja de R17, las unidades
		CPI R18,10	;Si el valor de las unidades llega a ser 10, hacer lo siguinte
		BREQ Decenas	;Se llama va directo a la etiqueta de "Decenas" porque ya llegó a 10 en unidades	
		; mostrar unidades con Decenas por el puerto A, las Decenas no se han modificado
		RET	;Regresar de donde fue llamado la subrutina de Incremento

	Decenas:	;En caso de que unidades llega a 10
		ANDI R17,0b11110000 ;Resetear parte baja de R17, unidades
		SUBI R17,-0x10	;Sumar 1 a la parte alta de R17, Decenas
		CPI R17,0xA0	;Checar si la parte alta de R17 llegó a 10
		BREQ Centenas	;En caso de que las Decenas llegue a 10, irse a la etiqueta Decenas
		RET ;Regresar de donde fue llamado la subrutina de Incremento

	Centenas:	;En caso de que Decenas llega a 10 
		CLR R17 ;Resetear unidades y Decenas
		INC R16	;Incrementar las centenas
		LDI R18,0x0F	;Registro para aplicar una mascara con el fin de leer solo centenas
		AND R18,R16	;aplicar mascara
		CPI R18,10	;checar si la parte baja de R18 centenas es igual a 10
		BREQ Millares	;En caso de que centena sea 10, irse a la etiqueta de millares
		RET ;Regresar de donde fue llamado la subrutina de Incremento

	Millares: ;En caso de que Decenas llega a 10
		CLR R17	;Resetear unidades y DecenasSegundo
		ANDI R16,0b11110000	;Resetear las centenas
		SUBI R16,-0x10	;Sumar 1 a millares
		CPI R16,0x60	;Checar si la parte alta de R16 es 6, millares
		BREQ ResetearTodo ;En caso de que millares sea 10, irse a la etiqueta para resetear todo y volver a contar
		RET ;Regresar de donde fue llamado la subrutina de Incremento
		ResetearTodo:	;Resetear todo después de 9999
			CLR R16	;Resetear un registro R16
			CLR R17
RET	 ;Regresar de donde fue llamado la subrutina de Incremento
MensajeACTIVESWITCH:
	CLT
	LDI dataByte,0b10000101
	CALL sendLCD_4bits
	SET
	LDI dataByte,'A'
	CALL sendLCD_4bits
	LDI dataByte,'C'
	CALL sendLCD_4bits
	LDI dataByte,'T'
	CALL sendLCD_4bits
	LDI dataByte,'I'
	CALL sendLCD_4bits
	LDI dataByte,'V'
	CALL sendLCD_4bits
	LDI dataByte,'E'
	CALL sendLCD_4bits
	CLT
	LDI dataByte,0b11000101
	CALL sendLCD_4bits
	SET
	LDI dataByte,'S'
	CALL sendLCD_4bits
	LDI dataByte,'W'
	CALL sendLCD_4bits
	LDI dataByte,'I'
	CALL sendLCD_4bits
	LDI dataByte,'T'
	CALL sendLCD_4bits
	LDI dataByte,'C'
	CALL sendLCD_4bits
	LDI dataByte,'H'
	CALL sendLCD_4bits
RET

retardo10ms:
	PUSH R25
	/*
	cteT1=T/Tr=10ms/125ns=80000 no cabe en 16 bits 65536
	cteT2=T/Tr=10ms/(8*125ns)=10000 sí cabe en 16 bits con prescaler de 8
	cargar 10000-1=9999 en OCR1AH|OCR1AL
	Palabra de control 00000000|00001010 modo CTC con prescaler de 8
	*/
	LDI R25,HIGH(9999)
	OUT OCR1AH,R25
	LDI R25,LOW(9999)
	OUT OCR1AL,R25
	LDI R25,0b00000000
	OUT TCCR1A,R25
	LDI R25,0b00001010
	OUT TCCR1B,R25
	lecturaRetardo10ms:
		IN R25,TIFR
		SBRS R25,OCF1A
		RJMP lecturaRetardo10ms
		CLR R25
		OUT TCCR1B,R25
		LDI R25,1<<OCF1A
		OUT TIFR,R25
POP R25
RET

retardo40us:
	PUSH R21
	PUSH R20
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