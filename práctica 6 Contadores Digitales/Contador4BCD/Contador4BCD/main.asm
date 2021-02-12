.ORG 0
.INCLUDE "m16def.inc"

;Configuración de puntero de pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configración de puertos   PB7-PB4 Millares | PB3-PB0 Centenas | PA7-PA4 Decenas | PA3-PA0 Unidades
LDI R16,0xFF
OUT DDRA,R16 ;Puerto A como salida, la parte baja mostrará las centenas y la parte alta los millares
OUT DDRB,R16 ;Puerto B como salida, la parte baja mostrará las unidades y la parte alta las decenas

CLR R16	;Resetear R16: la parte baja mostrará las centenas y la parte alta los millares
CLR R17	;Resetear R17: la parte baja mostrará las unidades y la parte alta las decenas
OUT PORTA,R16	;Mostrar por el puerto A(millares y centenas) el valor de 0
OUT PORTB,R17	;Mostrar por el puerto B(decenas y unidades) el valor de 0

PollingPrimerSwitch:	;Polling del primer Switch
	SBIS PINC,0	;Leer el valor del primer switch(activo en 1)
	RJMP PollingSegundoSwitch	;Si el switch 1 no está activo, hacer polling del segundo switch 
	CALL Incremento	;Si el switch sí está activo, incrementar 1 al llamar subrutina Incremento 
	CALL retardo10ms ; hacer un retardo de 10ms
	PollingSegundoSwitch:	;Polling del segundo switch
		SBIS PINC,1	;Leer el valor del segundo switch(activo en 1)
		RJMP PollingPrimerSwitch	;Si el segundo switch no está activo,volver a hacer polling del primer switch
		;Lo siguiente ocurre solo si el segundo switch está activo
		;Primero se hace lectura del botón con un eliminador de rebote
		SBIS PINC,2	;Leer el valor del botón(activo en 1) 
		RJMP PollingPrimerSwitch ;Si el botón no se presionó, volver a hacer polling del primer switch
		CALL retardo10ms ;hacer un retardo de 10ms para volver a leer después del "ruido"
		SBIS PINC,2 ;Volver a leer el estado del botón
		RJMP PollingPrimerSwitch	;Si el botón leyó 0, fue ruido y se va a polling de primer switch
		Wait: ;Sucede en caso de que leyó 1,se presionó el botón es decir está activo 
			SBIC PINC,2	;Detectar cuando e haya soltado el botón
			RJMP Wait	;Esperar a que se suelte
		CALL retardo10ms	;ya se soltó el botón y se hace un retardo para esperar aque acabe ruido de rebote
		;Termina Eliminador de rebote y se presionó el botón
		CALL Incremento		;Incrementar 1 al llamar subrutina Incremento
		CALL Incremento		;Segundo incremento porque es el caso cuando el segundo switch está activo y se ha presionado el botón
		CALL retardo10ms	;hacer un retardo de 10ms
		RJMP PollingPrimerSwitch	;Volver a hacer polling del primer switch

;Subrutinas
Incremento:	;Subrutina de Incremento
	Unidades:	;Para las unidades
		INC R17	;Incrementar R17 donde se guarda el valor de las unidades
		LDI R18,0x0F	;R18 es un registro para guardar la mascara
		AND R18,R17		;Aplicar la mascara para leer solamente el valor de la parte baja de R17, las unidades
		CPI R18,10	;Si el valor de las unidades llega a ser 10, hacer lo siguinte
		BREQ Decenas	;Se llama va directo a la etiqueta de "Decenas" porque ya llegó a 10 en unidades	
		OUT PORTA,R17	;En caso de que no se haya llegado a 10 las unidades, 
		; mostrar unidades con decenas por el puerto A, las decenas no se han modificado
		RET	;Regresar de donde fue llamado la subrutina de Incremento

	Decenas:	;En caso de que unidades llega a 10
		ANDI R17,0b11110000 ;Resetear parte baja de R17, unidades
		SUBI R17,-0x10	;Sumar 1 a la parte alta de R17, decenas
		CPI R17,0xA0	;Checar si la parte alta de R17 llegó a 10
		BREQ Centenas	;En caso de que las decenas llegue a 10, irse a la etiqueta decenas
		OUT PORTA,R17	;Mostrar por el puerto A las decenas y las unidades en caso de que decenas no llegue a 10
		RET ;Regresar de donde fue llamado la subrutina de Incremento

	Centenas:	;En caso de que decenas llega a 10 
		CLR R17 ;Resetear unidades y decenas
		OUT PORTA,R17	;Mostrar por el puerto A las unidades y las decenas
		INC R16	;Incrementar las centenas
		LDI R18,0x0F	;Registro para aplicar una mascara con el fin de leer solo centenas
		AND R18,R16	;aplicar mascara
		CPI R18,10	;checar si la parte baja de R18 centenas es igual a 10
		BREQ Millares	;En caso de que centena sea 10, irse a la etiqueta de millares
		OUT PORTB,R16	;Mostrar por el puerto B las centenas en caso de que no sea igual a 10
		RET ;Regresar de donde fue llamado la subrutina de Incremento

	Millares: ;En caso de que decenas llega a 10
		CLR R17	;Resetear unidades y decenas
		OUT PORTA,R17	;Mostrar por el puerto A las unidades y las decenas
		ANDI R16,0b11110000	;Resetear las centenas
		SUBI R16,-0x10	;Sumar 1 a millares
		CPI R16,0xA0	;Checar si la parte alta de R16 es 10, millares
		BREQ ResetearTodo ;En caso de que millares sea 10, irse a la etiqueta para resetear todo y volver a contar
		OUT PORTB,R16	;Mostrar por el puerto B las centenas y millares	
		RET ;Regresar de donde fue llamado la subrutina de Incremento
		ResetearTodo:	;Resetear todo después de 9999
			CLR R16	;Resetear un registro R16
			OUT PORTA,R16	;Mostrar 0 en decenas y unidades
			OUT PORTB,R16	;Mostrar 0 en millares y centenas
			RET	 ;Regresar de donde fue llamado la subrutina de Incremento	

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

