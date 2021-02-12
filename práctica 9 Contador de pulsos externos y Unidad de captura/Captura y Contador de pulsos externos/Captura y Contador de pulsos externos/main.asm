.INCLUDE "m16def.inc"
.ORG 0
.DEF dataByte=R25
.def BIN_LSB=R22
.def BIN_MSB=R23
;Configuración de puntero de pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16
SER R16
OUT DDRA,R16
CLR R16
CLR R17
CALL initLCD_4bits

LecturaSwitch1:	;Polling del primer Switch
	SBIS PINC,0	;Leer el valor del primer switch(activo en 1)
	RJMP LecturaSwitch2	;Si el switch 1 no está activo, hacer polling del seguswitch 
 	/*
	cteT1=T/Tr=2ms/125ns=16000 sí cabe en 16 bits 65536
	cargar 16000-1=15999 en OCR1AH|OCR1AL
	Palabra de control 00000000|00001001 modo CTC, sin prescaler
	*/
	LDI R24,HIGH(15999)
	OUT OCR1AH,R24
	LDI R24,LOW(15999)
	OUT OCR1AL,R24
	LDI R24,0b00000000
	OUT TCCR1A,R24
	LDI R24,0b00001001
	OUT TCCR1B,R24
	CLR R24
	OUT OCR0,R24
	LDI R24,0b00001111	;Detectar flanco de subida y modo CTC
	OUT TCCR0,R24

	pollingRetardo2ms:
		IN R24,TIFR
		SBRS R24,OCF0
		RJMP pulsoNoDetectado	
		CALL Incremento
		LDI R24,1<<OCF0
		OUT TIFR,R24
		pulsoNoDetectado:
			SBRS R24,OCF1A
			RJMP pollingRetardo2ms
		CLR R24
		OUT TCCR1B,R24
		OUT TCCR0,R24
		LDI R24,1<<OCF1A
		OUT TIFR,R24
		CALL enviarBCD
		CLR R16
		CLR R17
		SBIC PINC,0	;Leer el valor del primer switch(activo en 1)
		RJMP LecturaSwitch1	;Si el switch 1 no está activo, hacer polling del seguswitch 
	LecturaSwitch2:	;Polling del segundo switch	
		SBIS PINC,1	;Leer el valor del segundo switch(activo en 1)
		RJMP LecturaSwitch1	;Si el segundo switch no está activo,volver a hacer polling del primer switch
		;Lo siguiente ocurre solo si el segundo switch está activo
		CLR R24
		OUT TCCR1A,R24
		LDI R24,0b01000100	;Detectar flanco de subida, prescaler de 256
		OUT TCCR1B,R24
		PollingCaptura1:	;Polling de bandera de la unidad de captura,flanco de subida
			IN R24,TIFR
			SBRS R24,ICF1
			RJMP PollingCaptura1
		CLR R24
		OUT TCNT1H,R24	;Resetear el contador
		OUT TCNT1L,R24	;Resetear el contador
		LDI R24,1<<ICF1	
		OUT TIFR,R24 ;Apagar bandera	
		CLR R24	
		OUT TCCR1A,R24
		LDI R24,0b00000100 ;Detectar flanco de bajada
		OUT TCCR1B,R24
		PollingCaptura2:	;Polling de la bandera de unidad de captura, flanco de bajada
			IN R24,TIFR
			SBRS R24,ICF1
			RJMP PollingCaptura2
		CLR R24
		OUT TCCR1A,R24	;Apagar timer
		OUT TCCR1B,R24	;Apagar timer
		LDI R24,1<<ICF1	
		OUT TIFR,R24 ;Apagar bandera	
		IN BIN_LSB,ICR1L ;Escribir parte baja
		IN BIN_MSB, ICR1H	;Escribir parte alta
		CALL BIN_BCD	;Convertir el valor a BCD
		CLT	;Resetear bandera T para indicar que se enviará byte de instrucción
		LDI dataByte,0b11000110	;Posición del cursor 2da línea centrado para escribir tiempo xx:xx
		CALL sendLCD_4bits	;Enviar instrucción
		SET
		LDI YH,0	;Dirección parte alta(Millares)
		LDI YL,0x60    ;Dirección para dígitos BCD parte baja(Millares)  	 
		LD R24,Y+ ;Millares
		LDI dataByte,0x30
		ADD dataByte,R24
		CALL sendLCD_4bits
		LD R24,Y+ ;Centenas
		LDI dataByte,0x30
		ADD dataByte,R24
		CALL sendLCD_4bits
		LD R24,Y+ ;Decenas
		LDI dataByte,0x30
		ADD dataByte,R24
		CALL sendLCD_4bits
		LD R24,Y ;Unidades
		LDI dataByte,0x30
		ADD dataByte,R24
		CALL sendLCD_4bits		 
		SBIC PINC,0	;Leer el valor del primer switch(activo en 1)
		RJMP LecturaSwitch2	;Si el switch 1 no está activo, hacer polling del segundoswitch 
		RJMP LecturaSwitch1	;Volver a hacer polling del primer switch

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
		CPI R16,0xA0	;Checar si la parte alta de R16 es 6, millares
		BREQ ResetearTodo ;En caso de que millares sea 10, irse a la etiqueta para resetear todo y volver a contar
		RET ;Regresar de donde fue llamado la subrutina de Incremento
		ResetearTodo:	;Resetear todo después de 9999
			CLR R16	;Resetear un registro R16
			CLR R17
RET	 ;Regresar de donde fue llamado la subrutina de Incremento

enviarBCD:
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

sendLCD_4bits:	;Subrutina para enviar byte, primero parte alta(4 bits) y luego para baja(4 bits)
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	ANDI R24,0xF0    ;Aplicar una mascara para conservar solo parte alta        
	ORI R24,0b00000100	;Enable en 1
	BLD R24,0	;copiar la bandera T al bit 0 de R24, RS
	OUT PORTA,R24	;Mostrar por el puerto el registro R24
	CBI PORTA,2	;Poner Enable en 1 
	CALL retardo40us	;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	SBI PORTA,2	;Poner Enable en 0
	CALL retardo40us ;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	MOV R24,dataByte ;copiar el contenido de dataByte a R24
	SWAP R24	;Intercambiar parte alta con parte baja
	ANDI R24,0xF0	;Aplicar una mascara para conservar solo parte baja que está guardada en parte alta de R24
	ORI R24,0b00000100
	BLD R24,0	;copiar la bandera T al bit 0 de R24
	OUT PORTA,R24 ;Mostrar por el puerto el registro R24
	CBI PORTA,2 ;Enable en 1
	CALL retardo40us;El tiempo puede acercarse más al minuto si se comenta esta línea, funciona en la simulación
	SBI PORTA,2 ;Enable en 0
	CALL retardo40us ;retardo de 500us
RET;regresar a donde fue llamada 
retardo10ms:
	PUSH R24
	/*Timer 2
	cteT1=T/Tr=10ms/125ns=80000 no cabe en 8 bits 255
	cteT2=T/Tr=10ms/(1024*125ns)=78 sí cabe en 8 bits con prescaler de 1024
	cargar 78-1=77 en OCR2
	Palabra de control 00001111 modo CTC con prescaler de 1024
	*/
	LDI R24,LOW(77)
	OUT OCR2,R24
	LDI R24,0b00001111
	OUT TCCR2,R24
	pollingRetardo10ms:
		IN R24,TIFR
		SBRS R24,OCF2
		RJMP pollingRetardo10ms
		CLR R24
		OUT TCCR2,R24
		LDI R24,1<<OCF2
		OUT TIFR,R24
POP R24
RET

retardo40us:
	PUSH R24
	/*Timer 2
	cteT1=T/Tr=40us/125ns=320 no cabe en 8 bits 255
	cteT2=T/Tr=40us/(8*125ns)=40 sí cabe en 8 bits con prescaler de 8
	cargar 40-1=39 en OCR2
	Palabra de control 00001010 modo CTC con prescaler de 8
	*/
	LDI R24,LOW(39)
	OUT OCR2,R24
	LDI R24,0b00001010
	OUT TCCR2,R24
	pollingRetardo40us:
		IN R24,TIFR
		SBRS R24,OCF2
		RJMP pollingRetardo40us
		CLR R24
		OUT TCCR2,R24
		LDI R24,1<<OCF2
		OUT TIFR,R24
POP R24
RET


//-- Espacio de memoria en RAM donde se guarda el número convertido en BCD
//Subrutina dada por el profesor Omar Mata
BIN_BCD:	;Inicializar BCD en |0|0|0|0|
	CLR R16
	STS 0x60,R16	
    STS 0x61,R16     
	STS 0x62,R16     
	STS 0x63,R16

otro:  
	CPI BIN_LSB,0	;Checar si la parte baja del valor binario llegó a 0      
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	CPI BIN_MSB,0   ;Checar si la parte alta del valor bianrio llegó a 0        
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	RET	;Terminar el proceso y ya se convirtió el binario a BCD

//-- lógica: se incrementa el número BCD mientras se decrementa el binario hasta que sea 0.
 INC_BCD: 
	LDI R17,0     ;Registro utilizado para resetear en el caso de que llegue a 10 
	LDI YL,0x63    ;Dirección para dígitos BCD parte baja  
	LDI YH,0	;Dirección de unidades parte alta
ciclo: 
	LD R24,Y ;R24 es el registro de contador BCD de 1 a 9, traerse el valor de la memoria RAM           
	inc R24  ;Incrementar el contador de BCD   
	ST Y,R24 ;Guardar de vuelta valor incrementado     
	CPI R24,10	;Checar si se llegó a 10      
	BRNE DEC_BIN	;En caso de que no sea 10, decrementar valor binario      
	ST Y, R17	;Resetear el valor de BCD en caso que haya llegado a 10      
	DEC YL	;Decrementar el apuntador para que vaya a continuación a incrementar por el "10" que corresponde       
	CPI YL,0x5F	;Checar si llegó a 0x5F, en teoría puede ser cualquier valor diferente de las direcciones de RAM      
	BRNE ciclo	

DEC_BIN: 
	DEC BIN_LSB ;Decrementar valor binario     
	CPI BIN_LSB,0xFF	;Checar si se restó de 0, inidicación para restar parte alta         
	BRNE otro	;En el caso de que no haya llegado a menor de 0 la resta, volver a hacer la operación       
	DEC BIN_MSB	;En el caso de que se restó de 0, restar parte alta        
	RJMP otro	;Volver a hacer la operación
