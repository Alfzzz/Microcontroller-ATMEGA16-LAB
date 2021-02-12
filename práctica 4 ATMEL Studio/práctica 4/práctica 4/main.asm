;
; LED_test.asm
;
; Created: 06-Feb-19 3:59:57 PM
; Author : mata
;
.def leds = R22 ;definir leds como referencia a R22 

.org 0 ; ;definir 0 como la posición de memoria que se cargará el programa
.include "m16def.inc" ;Traducir instrucciones del ATMega16 para que el compilador entienda

;Definicion del puntero de pila
LDI R16, HIGH (RAMEND) ; pasar el contenido de la última dirección de RAM a R16
OUT SPH, R16 ;pasar R16 a la parte más significativa del puntador de de pila
LDI R16, LOW (RAMEND) ; pasar el contenido de la última dirección de RAM a R16
OUT SPL, R16 ;pasar R16 a la parte menos significativa del puntador de de pila

;Configuracion puntero RAM
LDI XL, LOW(0x60)  ;XL=06
LDI XH, HIGH(0x60) ;XH=00
LDI R16, 10 ;R16=10
LDI R17, 0x22 ;R16=0x22

MOV R24, R17 ;Guardar el registro R17 en R24 

loop: ;Etiqueta loop
ST X+, R17 ;Guardar R17 en la dirección apuntada por X y luego realizar un post incremento
DEC R16 ;Decrementar R16 por 1
BRNE loop ;Regresa a etiqueta loop si la bandera Z=0/R16=0

;Hasta aqui memoria RAM
SER R16 ;R16=0xFF
OUT DDRA, R16 ;Puerto A como salida
OUT DDRB, R16 ;Puerto B como salida
OUT DDRC, R16 ;Puerto C como salida
OUT DDRD, R16 ;Puerto D como salida
INICIO: ;Etiqueta INICIO
LDI R23, 8  ;Guardar 8 en R23
CLR leds ;leds=0x00
SEC		; C=1
izq: ;Etiqueta Izq
ROL leds ;Recorrimiento hacia la izquierda con el valor de carry y el valor de MSb se guarda en carry
OUT PORTA, leds ;Sacar el valor de leds recorrido hacia la izquierda por el puerto A
OUT PORTB, leds ;Sacar el valor de leds recorrido hacia la izquierda por el puerto B
OUT PORTC, leds ;Sacar el valor de leds recorrido hacia la izquierda por el puerto C
OUT PORTD, leds ;Sacar el valor de leds recorrido hacia la izquierda por el puerto D
CALL delay100ms ;Correr lo que se encuentra en la etiqueta delay100ms que se encuentra al final del código  
DEC R23 ;Decrementar R16 por 1
BRNE izq ;Regresa a etiqueta izq si la bandera Z=0/R23=0
LDI R23, 8 ;Guardar 8 en R23
der: ;etiqueta der
ROR leds ;;Recorrimiento hacia la derecha con el valor de carry y el valor de LSb se guarda en carry
OUT PORTA, leds ;Sacar el valor de leds recorrido hacia la derecha por el puerto A
OUT PORTB, leds ;Sacar el valor de leds recorrido hacia la derecha por el puerto B
OUT PORTC, leds ;Sacar el valor de leds recorrido hacia la derecha por el puerto C
OUT PORTD, leds ;Sacar el valor de leds recorrido hacia la derecha por el puerto D
CALL delay100ms ;Correr lo que se encuentra en la etiqueta delay100ms que se encuentra al final del código
DEC R23 ;Decrementar R23 por 1
BRNE der ;Regresa a etiqueta der si la bandera Z=0/R23=0


FIN: ;Etiqueta FIN
RJMP INICIO ;Regresar a la etiqueta INICIO, es decir, volver a correr al las instrucciones anteriores


delay10ms:	LDI R19, 104 ;Guardar el valor de 104 en R19 dentro de la etiqueta de delay10ms
	loop1:	LDI R20 ,255 ;Guardar el valor de 255 en R20 dentro de la etiqueta de loop1
	loop2:	DEC R20 ;Decrementar R20 por 1 dentro de la etiqueta loop2
			BRNE loop2 ;Regresar a la etiqueta loop2 si R20=0/Z=0
			DEC R19 ;Decrementar R19 por 1
			BRNE loop1 ;Regresar a loop1 si R19=0/Z=0
RET ;Regresar a donde fue llamado delay10ms

delay100ms: ;Etiqueta100ms
		LDI R21, 10 ;;Guardar el valor de 10 en R19 dentro de la etiqueta de delay10ms
loop3:	CALL delay10ms ;Correr lo que se encuentra en la etiqueta de delay10ms
		DEC R21 ;decrementar R21 por 1
		BRNE loop3 ;Reregsar a loop3 si R21=0/Z=0
RET ;Regresar a donde fue llamado delay100ms