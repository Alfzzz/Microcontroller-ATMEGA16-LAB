.ORG 0
.INCLUDE "m16def.inc"

;Configuración del puntero de la pila
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
	CALL SetearOResetearR16	;Llamar la subrutina SetearOResetear R16 que se encuentra entre línea 28 y 34
	SBRC R18,0	;Leer el primer switch, si es 0 se salta la siguiente instrucción
	CALL PrimerSwitchON	;Llamar la subrutina PrimerSwitchON, líneas 36-45
	SBRC R18,1	;Leer el segundo switch, si es 0 se salta la siguiente instrucción
	CALL SegundoSwitchON	;Llamar la subrutina SegundoSwitchON, líneas 47-73
	SBRC R18,2	;;Leer el tercer switch, si es 0 se salta la siguiente instrucción
	CALL TercerSwitchON		;Llamar la subrutina TercerSwitchON, líneas 75-95
	RJMP Inicio	;Volver a revisar

SetearOResetearR16:
		SBRS R19,0	;Si el primer switch esta 1, setear el registro R16 para que empiece el conteo descendente con 255
		SER R16	;Setear registro R16
		SBRS R19,1	;Si el segundo switch esta 1, resetear el registro R16 para que el recorrimiento de los LEDs empiece con todos apagados
		CLR R16	;Resetear registro R16
		CLT	;Poner la bandera de T en 0, cuando está en 0 encienen los LEDs de izquierda a derecha, cuando está en 1 apaga los LEDs de derecha a izquierda
RET	;Regresar porque es subrutina

PrimerSwitchON:
	LDI R19,0b00000001	;Definir que está en el estado cuando el primer switch está activo
	DEC R16	;Conteo descendente, decrementar 1 a R16
	OUT PORTC,R16	;Mostrar R16 por el puerto C		
	LDI R22,10	;Cargar 10 al registro R22 para llamar 10 veces retardo de 10ms, 10*10ms=100ms
	ciclo10:
		CALL retardo10ms	;Llamar subrutina retardo10ms
		DEC R22	;Decrementar R22
		BRNE ciclo10	;Volver a llamar ciclo10 si no cumplieron 10 ciclos 
RET	;Regresar porque es subrutina

SegundoSwitchON:
	LDI R19,0b00000010	;Definir que está en el estado cuando el segundo switch está activo
	BRTC izquierdaAderecha	;Si la bandera T no está en 0, se encenderán los LEDs de izquierda a derecha, al contrario seguir
	derechaAIzquierda:
		LSL R16	;Apagar los LEDs de derecha a izquierda, entra 0 a R16(0) y se recorren los bits
		OUT PORTC,R16	;Mostrar por el puerto C R16
		SBRS R16,7	;Si sigue en 1 R16(7), se salta la siguiente línea
		CLT	;Resetear la bandera T para indicar que tiene que encender los LEDs después
		CALL retardo200ms	;Llamar subrutina de retardo200ms, líneas 91-97
RET; Regresar de donde fue llamada la subrutina
	izquierdaAderecha:	;Si la bandera T fue 0, se llama
		SEC	;Setear el Carry
		ROR R16	;Encender los LEDs de izquierda a derecha, entra el Carry a R16(7) y se recorren los bits a la derecha
		OUT PORTC,R16	;Mostrar el R16 por el puerto C
		SBRC R16,0	;Si el primer bit es 1, ejecutar la siguiente instrucción para indicar que ahora va apagar los LEDs 
		SET	;Setear la bandera para indicar que se tienen que apagar los LEDs después
		CALL retardo200ms	;Llamar subrutina de retardo200ms, líneas 91-97
RET; Regresar de donde fue llamada la subrutina

TercerSwitchON:
	LDI R19,0b00000100 ;Definir que está en el estado cuando el tercer switch está en 1
	CPI R17,0x09	;Comparar al número si llegó a 9
	BREQ ResetearR17	;Resetear el número si llega a 9
	INC R17	;Incrementar el número si no ha llegado a 9
	OUT PORTB,R17	;Mostrar por el puerto B el número
	CALL retardo500ms	;Llamar subrutina de retardo500ms líneas 99-105
RET	;Regresar de donde fue llamado
	ResetearR17:
		CLR R17	;Resetear a 0 si el número llegó a 9
		OUT PORTB,R17	;Mostrar por el puerto B
		CALL retardo500ms	;llamar subrutina de retardo500ms líneas 99-105
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