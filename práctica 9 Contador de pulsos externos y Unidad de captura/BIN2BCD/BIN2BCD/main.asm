.INCLUDE "m16def.inc"
.ORG 0
.def BIN_LSB=R22
.def BIN_MSB=R23
;Configuración de puntero de pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

call BIN_BCD

Fin:
	RJMP Fin

//-- Espacio de memoria en RAM donde se guarda el número convertido en BCD
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
	LD R20,Y ;R24 es el registro de contador BCD de 1 a 9, traerse el valor de la memoria RAM           
	inc R20  ;Incrementar el contador de BCD   
	ST Y,R20 ;Guardar de vuelta valor incrementado     
	CPI R20,10	;Checar si se llegó a 10      
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

