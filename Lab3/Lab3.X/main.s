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

;-------------------------------MACROS------------------------------------------  
ConfigPines MACRO   ;Configurar pines acorde a su funcionamiento
    BANKSEL ANSEL	;Apagar las entradas analogicas
    clrf    ANSEL
    clrf    ANSELH
    BANKSEL TRISA	;colocar el puerto B como entrada en primeros 2 pines
    MOVLW   0xF3		;el resto como salida
    MOVWF   TRISB
    clrf    TRISC	;los puertos como salida
    clrf    TRISD
    clrf    TRISE
    BANKSEL PORTA	;colocar salidas en 0
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    ENDM		;termina el macro
    
configTimer MACRO   ;Configurar T0 y precargar valor, limpiar bandera
    BANKSEL OPTION_REG
    BCF	    OPTION_REG,5	;T0 a reloj interno [T0CS]
    BSF	    OPTION_REG,4	;Prescaler a el T0  [PSA]
    BCF	    OPTION_REG,2	;configurar el Prescaler    [PS2]
    BCF	    OPTION_REG,1	;[PS1]
    BCF	    OPTION_REG,0	;[PS0]
    BANKSEL TMR0
    ;BSF	    INTCON,5		;[T0IE] habilitar interrupcion T0
    MOVLW   200
    MOVWF   TMR0
    BCF	    INTCON,2		;[T0IF]	apagar la bandera del T0
ENDM
    
;--------------------------------Vector de Reset--------------------------------
PSECT resVect, delta=2, abs, class=CODE
ORG 0000h
ResetVec:
    PAGESEL main
    goto main

;------------------------Configuracion Microcontrolador-------------------------
PSECT loopPrincipal, delta=2, abs
ORG 0X000A	
main:
    ConfigPines
    configTimer

encendido:
    BANKSEL	TMR0
    BTFSS	INTCON,2
    goto	$-1
    BANKSEL	PORTC
    BSF		PORTC,0
    BANKSEL	TMR0
    MOVLW	200
    MOVWF	TMR0
    BCF		INTCON,2
    GOTO	encendido
    
    
END    