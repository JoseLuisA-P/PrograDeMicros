;-------------------------------------------------------------------------------
;
;   Autor: Jose Luis Alvarez Pineda
;   Archivo: main.s
;   Fecha de creacion: 21 de febrero 2021
;   modificacion: 
;   Dispositivo: PIC16F887
;   Descripcion:
/* 
    */    
;   Hardware:
/*                  	
    */
;-------------------------------------------------------------------------------

PROCESSOR 16F887
#include <xc.inc>

;----------------------Bits de configuracion------------------------------------ 
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;----------------------------Variables a utilizar------------------------------- 

Psect	udata_bank0 ;variables almacenadas en el banco 0
Conbin:	    DS	1   ;variable del contador binario
ConTim:	    DS	1   ;variable del contador del timmer
Tlow:	    DS	1   ;intermedio bajo para el timmer 0 (contar hasta 100ms)
Thigh:	    DS	1   ;intermedio alto para el timmer 0 (contar hasta 1s)
  
Psect	udata_shr   ;variables almacenadas en el banco de memoria compartida
W_TEMP:	     DS 1   ;Temporal de W
STATUS_TEMP: DS	1   ;Temporal de STATUS

;-------------------------------Macros---------------------------------    
configPuertos	MACRO	    ;configurar los puertos
    BANKSEL	ANSEL
    CLRF	ANSEL	;quitar entradas analogicas
    CLRF	ANSELH
    BANKSEL	TRISA	;Configurar entradas y salidas de puertos
    CLRF	TRISA
    CLRF	TRISC
    CLRF	TRISD
    MOVLW	0X03
    MOVWF	TRISB
    BANKSEL	PORTB	;Colocar la salida de los puertos en low todas
    CLRF	PORTA
    CLRF	PORTC
    CLRF	PORTD
    ENDM

configINT	MACRO	;configurar interrupciones
    BANKSEL	INTCON
    BSF		GIE	;habilitar interrupciones
    BSF		RBIE	;habilitar interrupciones de cambio en B
    ;BSF	T0IE	;habilitar interrupcion del TIMER0
    BCF		T0IF	;apagar bandera TIMER0
    BCF		RBIF	;apagar bandera de cambios en puerto B
    ENDM

configINTB	MACRO		;configurar pullup e interrupciones en B
    BANKSEL	TRISA
    BCF		OPTION_REG,7	;permite habilitar las pullup en B (RBPU)
    MOVLW	0X03
    MOVWF	WPUB	;Primeros dos pines de B en WeakPullup
    MOVLW	0X03
    MOVWF	IOCB	;primeros dos pines habilitados de intOnChange
    BANKSEL	PORTA
    MOVF	PORTB,W	;eliminar el mismatch
    BCF		RBIF
    ENDM
    
configOSC	MACRO	;configurar el oscilador interno
    ENDM
;-------------------------------Vector de reset---------------------------------
Psect	VReset, class = code, delta = 2, abs
ORG 0000h
	goto main
	
;----------------------------Vector de interrupcion-----------------------------
Psect	VInter, class = code, delta = 2, abs
ORG 0004h
push:
    MOVWF   W_TEMP	    ;Guardar de forma temporal W y STATUS
    SWAPF   STATUS,W	    ;sin alterar sus banderas
    MOVWF   STATUS_TEMP	

pinesB: 
    BANKSEL	PORTA
    BTFSC	RBIF
    CALL	contB
    
pop:
    SWAPF	W_TEMP, F	    ;cargar de nuevo el valor de W y STATUS
    MOVWF	W_TEMP	    ;sin modificar las banderas
    SWAPF	STATUS_TEMP,W
    MOVF	STATUS
    RETFIE

contB:
    BTFSS	PORTB,	0
    INCF	PORTA
    BTFSS	PORTB,	1   ;se lee el puerto no hay mismatch
    DECF	PORTA
    BCF		INTCON,	0    ;limpiar bandera de RB 
    CALL	tablaRB
    RETURN
   
;----------------------------Configuracion del uC-------------------------------
Psect mainLoop, class = code, delta = 2, abs
ORG 0100h
 
tabla:
    clrf    PCLATH	;Colocar el PCLATH en 01 para seleccionar la
    BSF	    PCLATH,0	;pagina correcta
    ADDWF   PCL		;sumar segmento + PCL para seleccionar el valor adecuado
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01100111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;b
    retlw   00111001B	;C
    retlw   01011110B	;d
    retlw   01111001B	;E
    retlw   01110001B	;F 
    
 main:
    configPuertos
    configINT
    configINTB
 loop:
    GOTO loop
    
tablaRB:		;colocar el valor de la tabla en PORTC
    BTFSC   PORTA,  4	
    CALL    LIM
    MOVF    PORTA,W
    CALL    tabla
    MOVWF   PORTC   
    RETURN  
    
LIM:
    MOVLW   0X0F	;para evitar que cuente mas de 4 bits
    ANDWF   PORTA,F
    RETURN
    
    END   