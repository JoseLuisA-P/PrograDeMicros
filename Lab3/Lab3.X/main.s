;-------------------------------------------------------------------------------
;
;   Autor: Jose Luis Alvarez Pineda
;   Archivo: main.s
;   Fecha de creacion/modificacion: 
;   Dispositivo: PIC16F887
;   Descripcion:
;   Hardware:
;
;-------------------------------------------------------------------------------
    
;   Librerias utilzadas
PROCESSOR 16F887
#include <xc.inc>

;------------------------Palabras de configuracion------------------------------
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
  
;--------------------------Variables a utilizar---------------------------------
PSECT udata_bank0
Contador:   DS	1   ;variable del contador
BandCont:    DS	1   ;variable para el aumento
    
;-------------------------------MACROS------------------------------------------  
ConfigPines MACRO   ;Configurar pines acorde a su funcionamiento
    BANKSEL ANSEL	;Apagar las entradas analogicas
    clrf    ANSEL
    clrf    ANSELH
    BANKSEL TRISA	;colocar el puerto B como entrada en primeros 2 pines
    MOVLW   0xF3	;el resto como salida
    MOVWF   TRISB
    clrf    TRISC	;los puertos como salida
    clrf    TRISD
    clrf    TRISE
    BANKSEL PORTA	;colocar salidas en 0
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    clrf    Contador	;Variable contador en 0
    ENDM		;termina el macro
    
configTimer MACRO   ;Configurar T0 y precargar valor, limpiar bandera
    BANKSEL OPTION_REG
    BCF	    OPTION_REG,5	;T0 a reloj interno [T0CS]=0
    BCF	    OPTION_REG,3	;Prescaler a el T0  [PSA]=0
    BSF	    OPTION_REG,2	;configurar el Prescaler    [PS2]
    BSF	    OPTION_REG,1	;[PS1]
    BCF	    OPTION_REG,0	;[PS0]	configurado en 110--1:128
    BANKSEL TMR0
    MOVLW   12			;se precarga el T0 con 12
    MOVWF   TMR0
    BCF	    INTCON,2		;[T0IF]	apagar la bandera del T0
ENDM

configOsc   MACRO
    BANKSEL OSCCON		;Configurar el oscilador inter
    BSF	    OSCCON,6		;[IRCF2]=1
    BCF	    OSCCON,5		;[IRCF1]=0    
    BCF	    OSCCON,4		;[IRCF0]=0------ INTC de 1MHz
    BSF	    OSCCON,0		;SCS reloj interno
ENDM
;--------------------------------Vector de Reset--------------------------------
PSECT resVect, delta=2, abs, class=CODE
ORG 0000h
    PAGESEL main
    goto main
    
;------------------------Configuracion Microcontrolador-------------------------
PSECT loopPrincipal, delta=2, class =CODE
main:
    ConfigPines
    configTimer
    configOsc
    
loop:
    BANKSEL INTCON
    BTFSC   INTCON,2		;mira si la bandera del timmer esta arriba
    call    timer0
    ;comprobar el estado del boton de aumento
    BTFSC   RB0			;boton de aumento
    BSF	    BandCont,0		;bit0 de aumento para permitir el contar 
    BTFSS   RB0			;al dejar de presionar el boton
    call    contArriba
    ;comprobar el estado del boton de decremento
    BTFSC   RB1			;boton de decremento
    BSF	    BandCont,1		;bit1 de decremento para permitir el disminuir 
    BTFSS   RB1			;al dejar de presionar el boton
    call    contAbajo
    ;comprobar si no se pasan del valor, sino regresa el valor a 0
    BTFSC   PORTC,4
    clrf    PORTC
    goto    loop

contAbajo:
    BTFSC   BandCont,1		;mira si es 1 para disminuir
    DECF    PORTC		;decrementar el valor del puerto C
    BCF	    BandCont,1		;coloca en 0 la bandera de Decremento
    return
    
contArriba:
    BTFSC   BandCont,0		;mira si es 1 para contar
    INCF    PORTC		;aumenta el valor del puertoC
    BCF	    BandCont,0		;coloca en 0 la bandera en Aumento
    return
    
timer0:
    BANKSEL TMR0
    MOVLW   12			;se precarga el T0 con 12
    MOVWF   TMR0
    INCF    Contador		;Incrementa el valor del contador
    BTFSC   Contador,2		;revisa si el contador ya llego a 4
    call    aumentoPortD	;aumenta el puerto y reinicia el contador
    BCF	    INTCON,2		;apaga la bandera del timer0
    return

toogle:
    movlw   0x01		;coloca en 1 y hace XOR con PORTE en el 0
    XORWF   PORTE,F		;si este es distinto lo coloca en 0, sino en 1
    BCF	    BandCont,2
    clrf    PORTD		;coloca el valor del puerto D en 0
    return
    
aumentoPortD:
    INCF    PORTD		;incrementa el puerto D
    BTFSC   PORTD,4		;si se pasa de 4bits regresa a 0
    CLRF    PORTD		
    CLRF    Contador		;el contador regresa a 0
    BCF	    STATUS,2		;en 0 el valor de la bandera de 0
    MOVF    PORTC,W		;revisa el valor del led
    XORWF   PORTD,W		;Resta a C el valor de D
    BTFSC   STATUS,2		;Revisa si el valor da como resultado 0
    BSF	    BandCont,2		;Activa la 3ra bandera del contador
    BTFSC   BandCont,2		
    call    toogle		;Hacer toogle al Led
    return
    
END    