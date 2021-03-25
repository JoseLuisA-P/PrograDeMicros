;-------------------------------------------------------------------------------
;
;   Autor: Jose Luis Alvarez Pineda
;   Archivo: main.s
;   Fecha de creacion: 25 de marzo de 2021
;   modificacion: 25 de marzo 2021
;   Dispositivo: PIC16F887
;   Descripcion:
/*  El timer 0 se utiliza para multiplexar dos displays. El timer 1 hace que una
    variable cuente a cada segundo y con el multiplexado del timer 0 se
    despliega en los displays. El timer 2 hace que tanto los displays como un 
    led cambien de estado cada 0.25 segundos.
    */    
;   Hardware:
/*  En el puerto C se tiene conectado las terminales del display
    En el puerto D0 y D1 los pines que multiplexan los display
    En el puerto E0 se tiene el led que cambia de estado.
     */
;-------------------------------------------------------------------------------
PROCESSOR   16F887
#include <xc.inc>

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
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;-------------------------------Variables---------------------------------------
Psect	udata_shr		;Variables temporales de W y status para las INT
W_TEMP:		DS  1
STATUS_TEMP:	DS  1
    
Psect	udata_bank0		;variables para los timmers
BANDERAS:	DS  1
CONTEO:		DS  1
TIM1:		DS  1
TIM2:		DS  1

;----------------------------------MACROS---------------------------------------
configPuertos	MACRO	    ;configurar los puertos
    BANKSEL	ANSEL
    CLRF	ANSEL	;quitar entradas analogicas
    CLRF	ANSELH
    BANKSEL	TRISA	;Configurar entradas y salidas de puertos
    CLRF	TRISC
    CLRF	TRISD
    CLRF	TRISE
    BANKSEL	PORTB	;Colocar la salida de los puertos en low todas
    CLRF	PORTC
    CLRF	PORTD
    CLRF	PORTE
    BSF		PORTD,0	    ;enciende el primer bit
    CLRF	CONTEO
    ENDM

configINT	MACRO	;configurar interrupciones
    BANKSEL	INTCON
    BSF		GIE	;habilitar interrupciones
    BSF		PEIE
    BSF		T0IE	;habilitar interrupcion del TIMER0
    BCF		T0IF	;apagar bandera TIMER0   
    ;configurando interrupciones del timmer1 y 2
    BANKSEL	PIE1
    BSF		TMR1IE	;habilita la interrupcion del timmer 1
    BSF		TMR2IE	;habilita la interrucion del timmer 2
    BANKSEL	PIR1
    BCF		TMR1IF
    BCF		TMR2IF
    ENDM

configTIM1	MACRO
    BANKSEL	T1CON
    BSF		T1CKPS1
    BSF		T1CKPS0	    ;pre en 8
    BSF		TMR1ON
    CALL	CARGAT1	    ;carga T1 con 3035, para que cuentre cada 0.5 Seg
    ENDM
    
configTIM2	MACRO
    BANKSEL	PR2
    MOVLW	104
    MOVWF	PR2	    ;coloca el periodo en 104 y da como resultado 25mS
    BANKSEL	T2CON
    CLRF	TMR2
    BSF		TOUTPS3
    BSF		TOUTPS2
    BSF		TOUTPS1
    BCF		TOUTPS0	    ;POST en 15
    BSF		TMR2ON	    ;enciende el timmer
    BSF		T2CKPS1	    ;pre en 16
    BSF		T2CKPS0	    
    ENDM
    
configOSC	MACRO	;configurar el oscilador interno
    BANKSEL TMR0
    CLRWDT
    CLRF    TMR0
    BANKSEL OSCCON  ;configurando la frecuencia y fuente del oscilador
    BSF	    IRCF2
    BSF	    IRCF1
    BCF	    IRCF0   ;Frecuencia de 4MHz---110
    BSF	    SCS	    ;utilizar el oscilador interno
    ;Configurando el prescalador y lafuente
    BCF	    OPTION_REG,5    ;TIMER0 usa el reloj interno
    BCF	    OPTION_REG,3    ;Prescalador al timmer0
    BSF	    PS2
    BCF	    PS1
    BCF	    PS0	    ;Usar prescalador de 32
    CALL    CARGAT0
    ENDM  
    
;---------------------------Codigo ejecutable-----------------------------------
Psect	vectorReset, class = CODE, delta = 2, abs
ORG 0000h
    goto main
    
Psect	vectorINT, class= code, delta = 2, abs
ORG 0004h
    push:
    MOVWF   W_TEMP	    ;Guardar de forma temporal W y STATUS
    SWAPF   STATUS,W	    ;sin alterar sus banderas
    MOVWF   STATUS_TEMP	
    
    BTFSC   T0IF
    GOTO    T0RUT
    BTFSC   TMR1IF
    GOTO    T1RUT
    BTFSC   TMR2IF
    GOTO    T2RUT
    GOTO    pop
    
    T0RUT:
    BSF	    BANDERAS,0	    ;Bandera timmer0, cada 1.25 mS
    BCF	    T0IF	    ;apaga la bandera 
    CALL    CARGAT0	    ;carga el valor de T0
    GOTO    pop
    
    T1RUT:
    INCF    TIM1	    ;aumenta el valor de TIM1
    BCF	    TMR1IF	    ;Apaga la bandera
    CALL    CARGAT1	    ;Precarga el valor de T1
    GOTO    pop
    
    T2RUT:
    INCF    TIM2
    BCF	    TMR2IF
    GOTO    pop
    
    pop:
    SWAPF   STATUS_TEMP,W
    MOVWF   STATUS
    SWAPF   W_TEMP,F
    SWAPF   W_TEMP,W
    RETFIE			;termina la rutina de interrupcion

Psect	loopPrin, class = code, delta = 2, abs
ORG 0100h
 
    tabla:
    CLRF    PCLATH	;Colocar el PCLATH en 01 para seleccionar la
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
    configTIM1
    configTIM2
    configOSC
    
    loop:
    BTFSC   BANDERAS,0
    CALL    MUX
    BCF	    STATUS,2
    MOVLW   2
    XORWF   TIM1,W
    BTFSC   STATUS,2	;mira si timmer1 ya conto 1 segundo
    CALL    INCREMENTO
    BCF	    STATUS,2
    MOVLW   10
    XORWF   TIM2,W
    BTFSC   STATUS,2	;mira si timmer2 ya conto 0.25 segundo
    CALL    TOOGLE
    BTFSC   PORTE,0
    GOTO    $+3
    CLRF    PORTC
    GOTO    loop
    CALL    MULTIPLEX	;multiplexar
    GOTO    loop
    
    
    CARGAT0:
    BANKSEL TMR0    ;Precarga el valor de 217 al TM0
    MOVLW   217
    MOVWF   TMR0
    BCF	    INTCON,2	;Limpiar bandera del TIMER0
    RETURN
    
    CARGAT1:
    BANKSEL PORTA	;selecciona el banco del timmer 1 H y L
    MOVLW   11011011B
    MOVWF   TMR1L
    MOVLW   00001011B
    MOVWF   TMR1H
    RETURN
    
    INCREMENTO:
    INCF    CONTEO
    CLRF    TIM1
    RETURN
    
    MUX:    
    BCF	    STATUS,0	    ;Elimina el carry
    RLF	    PORTD	    ;rota a la izquierda y lo coloca en 1 si se paso
    BTFSS   PORTD,2	    ;a la 3ra posicion
    GOTO    $+3
    CLRF    PORTD
    BSF	    PORTD,0
    RETURN

    
    MULTIPLEX:   
    BCF	    BANDERAS,0
    BTFSC   PORTD,0
    CALL    LDEC
    BTFSC   PORTD,1
    CALL    LUNI
    RETURN
    
    LDEC:
    CLRF    PORTD
    MOVF    CONTEO,W
    ANDLW   0Fh
    CALL    tabla
    MOVWF   PORTC
    BSF	    PORTD,0
    RETURN
    
    LUNI:
    CLRF    PORTD
    SWAPF   CONTEO,W
    ANDLW   0Fh
    CALL    tabla
    MOVWF   PORTC
    BSF	    PORTD,1
    RETURN
    
    TOOGLE:
    CLRF    TIM2
    BTFSS   PORTE,0
    GOTO    $+3
    BCF	    PORTE,0
    RETURN
    BSF	    PORTE,0
    RETURN