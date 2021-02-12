.ORG 0
.INCLUDE "m16def.inc"

;Configuraci�n del puntero de la pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configurar puerto C y B como modo salida
;Se ocupan los 3 Switches en el puerto A, no se configura porque el puerto arranca como modo entrada  
LDI R16,0xFF	;Cargar 0xFF al registro
OUT DDRC,R16	;Configurar el puerto C como salida 
OUT DDRB,R16	;Configurar el puerto B como salida

Inicio:
	IN R18,PINA	;Leer el puerto A donde se encuentran los switches
	CPSE R18,R19	;Comparar si hubo cambio de estado del switch, si R18  y R19 no son iguales hubo un cambio de estado y se configura R16
	CALL SetearOResetearR16	;Llamar la subrutina SetearOResetear R16 que se encuentra entre l�nea 28 y 34
	SBRC R18,0	;Leer el primer switch, si es 0 se salta la siguiente instrucci�n
	CALL PrimerSwitchON	;Llamar la subrutina PrimerSwitchON, l�neas 36-45
	SBRC R18,1	;Leer el segundo switch, si es 0 se salta la siguiente instrucci�n
	CALL SegundoSwitchON	;Llamar la subrutina SegundoSwitchON, l�neas 47-73
	SBRC R18,2	;;Leer el tercer switch, si es 0 se salta la siguiente instrucci�n
	CALL TercerSwitchON		;Llamar la subrutina TercerSwitchON, l�neas 75-95
	RJMP Inicio	;Volver a revisar

SetearOResetearR16:
		SBRS R19,0	;Si el primer switch esta 1, setear el registro R16 para que empiece el conteo descendente con 255
		SER R16	;Setear registro R16
		SBRS R19,1	;Si el segundo switch esta 1, resetear el registro R16 para que el recorrimiento de los LEDs empiece con todos apagados
		CLR R16	;Resetear registro R16
		CLT	;Poner la bandera de T en 0, cuando est� en 0 encienen los LEDs de izquierda a derecha, cuando est� en 1 apaga los LEDs de derecha a izquierda
RET	;Regresar porque es subrutina

PrimerSwitchON:
	LDI R19,0b00000001	;Definir que est� en el estado cuando el primer switch est� activo
	DEC R16	;Conteo descendente, decrementar 1 a R16
	OUT PORTC,R16	;Mostrar R16 por el puerto C		
	LDI R22,10	;Cargar 10 al registro R22 para llamar 10 veces retardo de 10ms, 10*10ms=100ms
	ciclo10:
		CALL retardo10ms	;Llamar subrutina retardo10ms
		DEC R22	;Decrementar R22
		BRNE ciclo10	;Volver a llamar ciclo10 si no cumplieron 10 ciclos 
RET	;Regresar porque es subrutina

SegundoSwitchON:
	LDI R19,0b00000010	;Definir que est� en el estado cuando el segundo switch est� activo
	BRTC izquierdaAderecha	;Si la bandera T no est� en 0, se encender�n los LEDs de izquierda a derecha, al contrario seguir
	derechaAIzquierda:
		LSL R16	;Apagar los LEDs de derecha a izquierda, entra 0 a R16(0) y se recorren los bits
		OUT PORTC,R16	;Mostrar por el puerto C R16
		SBRS R16,7	;Si sigue en 1 R16(7), se salta la siguiente l�nea
		CLT	;Resetear la bandera T para indicar que tiene que encender los LEDs despu�s
		CALL retardo200ms	;Llamar subrutina de retardo200ms, l�neas 91-97
RET; Regresar de donde fue llamada la subrutina
	izquierdaAderecha:	;Si la bandera T fue 0, se llama
		SEC	;Setear el Carry
		ROR R16	;Encender los LEDs de izquierda a derecha, entra el Carry a R16(7) y se recorren los bits a la derecha
		OUT PORTC,R16	;Mostrar el R16 por el puerto C
		SBRC R16,0	;Si el primer bit es 1, ejecutar la siguiente instrucci�n para indicar que ahora va apagar los LEDs 
		SET	;Setear la bandera para indicar que se tienen que apagar los LEDs despu�s
		CALL retardo200ms	;Llamar subrutina de retardo200ms, l�neas 91-97
RET; Regresar de donde fue llamada la subrutina

TercerSwitchON:
	LDI R19,0b00000100 ;Definir que est� en el estado cuando el tercer switch est� en 1
	CPI R17,0x09	;Comparar al n�mero si lleg� a 9
	BREQ ResetearR17	;Resetear el n�mero si llega a 9
	INC R17	;Incrementar el n�mero si no ha llegado a 9
	OUT PORTB,R17	;Mostrar por el puerto B el n�mero
	CALL retardo500ms	;Llamar subrutina de retardo500ms l�neas 99-105
RET	;Regresar de donde fue llamado
	ResetearR17:
		CLR R17	;Resetear a 0 si el n�mero lleg� a 9
		OUT PORTB,R17	;Mostrar por el puerto B
		CALL retardo500ms	;llamar subrutina de retardo500ms l�neas 99-105
RET; Regresar de donde fue llamado

;retardo de 10ms para frecuencia de reloj de 8MHz
retardo10ms:
	LDI R20,104
	ciclo104:
		LDI R21,255
	ciclo255:
		DEC R21
		BRNE ciclo255
		DEC R20
		BRNE ciclo104
RET  

retardo200ms:
	LDI R22,20	;llamar 20 veces el retardo de 10ms, 10ms*20=200ms
		ciclo20_1:
			CALL retardo10ms
			DEC R22
			BRNE ciclo20_1
RET

retardo500ms:
	LDI R22,50	;llamar 50 veces el retardo de 10ms, 10ms*50=500ms
	ciclo50_1:
		CALL retardo10ms
		DEC R22
		BRNE ciclo50_1
RET