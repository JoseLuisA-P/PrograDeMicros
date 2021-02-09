;******************************************************************************
;autor: Jose Luis Alvarez Pineda
;Dispositivo: PIC16F887
;Compilador: pic-as(v2.30), MPLABX V5.45
;
;Hardware:leds en puertos A, B y D, entradas con botones en puerto C.
;
;Programa:Contadores de 4 bits en 2 puertos y resultado de la suma con carry
; en otro puerto distinto, utilizando 2 botones por puerto para incrementer
; y uno para desplegar el resultado de la suma
;******************************************************************************

PROCESSOR 16F887
#include <xc.inc>
;******************************************************************************
;Palabras de configuracion
;******************************************************************************
    
; CONFIG1
  CONFIG  FOSC = XT		; Oscillator Selection bits (RC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;******************************************************************************
;variables a utilizar
;******************************************************************************
PSECT udata_bank0	;common memory
CONT1:	DS  1		;variable contador 1 de un byte
CONT2:	DS  1		;variable contador 2 de un byte
RES:	DS  1		;resultado de la suma

;******************************************************************************
;Vector de reset
;******************************************************************************
PSECT resVect, abs, delta = 2, class = CODE
ORG 0X00h	;posicion del vector de reset
VectorReset:
    PAGESEL main
    goto main
;******************************************************************************
;Configuracion del microcontrolador
;******************************************************************************
PSECT code, abs, delta = 2
ORG 0x10h
 
main:	;configuraciones iniciales del uC
    bsf	    STATUS,5	    ;seleccion de banco 1
    bcf	    STATUS,6
    clrf    TRISD	    ;colocar puerto D como salida
    MOVLW   0X1F	    ;cargar el valor en W de la configuracion 
    MOVWF   TRISC	    ;del puerto C
    clrf    TRISB	    ;colocar puerto B como salida
    clrf    TRISA	    ;coloca puerto A como salida
    bsf	    STATUS,6	    ;seleccionar el banco 4
    clrf    ANSEL	    ;configurar los ansel para colocar los pines
    clrf    ANSELH	    ;como digitales 
    bcf	    STATUS,5	    ;seleccion del banco 0
    bcf	    STATUS,6    
    clrf    PORTD	    ;colocar en 0 los puertos a utilizar
    clrf    PORTB	    
    clrf    PORTA
    ;valor a las variables
    MOVLW   0
    MOVWF   CONT1
    MOVLW   0
    MOVWF   CONT2

loop:
    BTFSC   PORTC,0 ;revisa el valor de C0, salta si es 0
    call    incC1   ;incrementa el valor de Contador1
    BTFSC   PORTC,1 ;revisa el valor de C1, salta si es 0
    call    decC1   ;reduce el valor de Contador1
    BTFSC   PORTC,2
    call    incC2   ;aumenta el valor de Contador2
    BTFSC   PORTC,3
    call    decC2   ;reduce el valor de Contador2
    BTFSC   PORTC,4 
    call    adicion
    goto loop
    
incC1:
    BTFSC   PORTC,0 ;revisa si es 0 para salta
    goto    $-1	    ;sino sigue en loop hasta que es 0
    INCF    CONT1,1 ;aumenta la variable y la almacena misma pos
    BTFSC   CONT1,4 ;mira si no cuenta mas de 4 bits
    clrf    CONT1   ;sino coloca todo en 0 de nuevo
    MOVF    CONT1,0 ;carga CONT1 en W
    MOVWF   PORTD   ;carga W en PORTD
    return
    
decC1:
    BTFSC   PORTC,1 ;revisa si es 0 para salta
    goto    $-1	    ;sino sigue en loop hasta que es 0
    DECF    CONT1,1 ;disminuye el valor de CONT1 y lo almacena misma pos
    BTFSC   CONT1,4
    clrf    CONT1
    MOVF    CONT1,0 ;carga CONT1 en W
    MOVWF   PORTD   ;carga W en PORTD
    return

incC2:
    BTFSC   PORTC,2;revisa si es 0 para saltar
    goto    $-1
    INCF    CONT2,1 ; aumentar el valor y lo almacena misma pos
    BTFSC   CONT2,4 ;mira si no cuenta mas de 4 bits
    clrf    CONT2   ;sino coloca todo en 0
    MOVF    CONT2,0 ;Carga cont2 a W
    MOVWF   PORTB   ;carga W en PORTB
    return

decC2:
    BTFSC PORTC,3   ;revisa si es 0 para saltar
    goto    $-1
    DECF    CONT2,1 ;disminuye el valor y lo almacena misma pos
    BTFSC   CONT2,4 ;mira si no cuenta abajo de 0
    clrf    CONT2   ;coloca todo en 0
    MOVF    CONT2,0 ;Coloca cont2 en W
    MOVWF   PORTB   ;Carga W en portb
    return

adicion:
    BTFSC   PORTC,4 ;revisa si es 0 para saltar
    goto    $-1
    MOVF    CONT1,0 ;colocar cont1 en W
    ADDWF   CONT2,0 ;Se suman contador 2 a W y se guarda en W
    MOVWF   PORTA   ;se coloca W en portA
    return
    
end