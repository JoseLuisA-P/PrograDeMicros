;-------------------------------------------------------------------------------
;
;   Autor: Jose Luis Alvarez Pineda
;   Archivo: main.s
;   Fecha de creacion: 27 de febrero 2021
;   modificacion: 22 de febrero 2021
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

;--------------------------------Variables--------------------------------------
Psect	udata_shr		;Variables temporales de W y status para las INT
W_TEMP:		DS  1
STATUS_TEMP:	DS  1
    
Psect	udata_bank0		;variables para las divisiones.
banderas:	DS  1		;0=aumento,1=disminucion,2=timmer
HEXH:		DS  1		;bits altos del HEX
HEXL:		DS  1		;bits bajos del HEX
MUX:		DS  1		;variable para multiplexar los displays
;-------------------------------Macros-----------------------------------------    
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
    CLRF	PORTB
    CLRF	PORTC
    CLRF	PORTD
    CLRF	MUX	;limpia el multiplexor
    BSF		MUX,0	;el primer bit encendido
    ENDM

configINT	MACRO	;configurar interrupciones
    BANKSEL	INTCON
    BSF		GIE	;habilitar interrupciones
    BSF		RBIE	;habilitar interrupciones de cambio en B
    BSF		T0IE	;habilitar interrupcion del TIMER0
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
    BANKSEL	TMR0
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
    BSF	    PS1
    BCF	    PS0	    ;Usar prescalador de 128
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
    
    INTT0:
    BTFSC   T0IF	;mira la si la interrupcion es del timmer0
    RLF	    MUX,F	   ;corre a la izquierda el 1 en el mux
    BTFSC   T0IF	;mira la si la interrupcion es del timmer0
    BSF	    banderas,2
    BCF	    T0IF
    
    INTRB:
    BANKSEL PORTB
    BTFSC   RBIF
    CALL    PUSHES
    
    pop:
    SWAPF   STATUS_TEMP,W
    MOVWF   STATUS
    SWAPF   W_TEMP,F
    SWAPF   W_TEMP,W
    RETFIE			;termina la rutina de interrupcion
    
    PUSHES:
    BTFSS   PORTB,0
    BSF	    banderas,0	    ;enciende primer bit para aumentar
    BTFSS   PORTB,1
    BSF	    banderas,1	    ;enciende segundo bit para disminuir
    BCF	    RBIF 
    RETURN
    
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
    configINTB
    configOSC
    
    loop:
    ;rutina para aumentar o disminuir el valor de B acorde a las interrupciones
    BANKSEL PORTB
    BTFSC   banderas,0
    CALL    aumento
    BTFSC   banderas,1
    CALL    disminucion
    ;Rutina para dividir en nibbles el valor obtenido
    MOVF    PORTC,W	;Coloca el valor del puertoC en W
    ANDLW   0X0F	;Se colocan los ultimos 4 en 0
    MOVWF   HEXL	;mueve el nibble bajo a HEXL
    SWAPF   PORTC,W	;le da la vuelta a los nibbles en C y los coloca en W
    ANDLW   0X0F	;Se colocan los ultimos 4 en 0
    MOVWF   HEXH	;mueve el nibble alto a HEXH
    ;Rutina multiplexado
    BTFSC   MUX,2
    CALL    ARREGLOMUX
    ;Rutina subir los valores del display
    BTFSC   banderas,2	;actualiza los valores cada vez que el mux cambia 
    CALL    MUX7
    GOTO loop
    
    CARGAT0:
    BANKSEL TMR0    ;Precarga el valor de 217 al TM0
    MOVLW   217
    MOVWF   TMR0
    BCF	    INTCON,2	;Limpiar bandera del TIMER0
    RETURN
    
    MUX7:
    BTFSC   MUX,0	    ;revisa si es el bit de hexLow
    CALL    CARGARHBAJO	    ;coloca en puerto D el valor de HEX bajo
    BTFSC   MUX,1	    ;revisa si es el bit de hexHigh
    CALL    CARGARHALTA	    ;coloca en puerto D el valor de HEX alto
    BCF	    banderas,2
    RETURN
    
    ARREGLOMUX:	    ;coloca la posicion del mux de nuevo en la priemra
    CLRF    MUX	    ;coloca en 0 el MUX y luego carga el primer bit de nuevo
    BSF	    MUX,0
    RETURN
    
    aumento:
    INCF    PORTC	;aumenta el valor de C
    BCF	    banderas,0	;limpia la bandera aumento de banderas
    RETURN
    
    disminucion:
    DECF    PORTC	;disminuye el valor de C
    BCF	    banderas,1	;limpia la bandera de disminucion de banderas
    RETURN
    
    CARGARHBAJO:
    CLRF    PORTA	    ;se limpia el puerto
    MOVF    HEXL,W	    ;carga los nibble bajos en w
    CALL    tabla
    MOVWF   PORTD	    ;cargar el valor de W extraido de la tabla en D
    MOVF    MUX,W
    MOVWF   PORTA	    ;coloca el valor de muxw en A
    RETURN
    
    CARGARHALTA:
    CLRF    PORTA	    ;se limpia el puerto
    MOVF    HEXH,W	    ;carga los nibble altos en w
    CALL    tabla
    MOVWF   PORTD	    ;cargar el valor de W extraido de la tabla en D
    MOVF    MUX,W
    MOVWF   PORTA	    ;coloca el valor de muxw en A
    RETURN
    
END