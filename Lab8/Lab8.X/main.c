/* 
 * File:   main.c
 * Author: jalva
 *
 * Created on 17 de abril de 2021, 06:23 PM
 */

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
//oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and 
//can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON       // RE3/MCLR pin function select bit (RE3/MCLR 
//pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code 
//protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit 
//(Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit 
//(Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit 
//(Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit 
//(RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
//(Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 
//(Write protection off)

#include <xc.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#define _XTAL_FREQ 4000000 // Frecuencia de reloj

//------------------variables a utilizar ---------------------------------------
union BANDERAS{ //declarar variable con bits nombrados
    struct{
        unsigned updt: 1;   //actualizar el valor de los leds
        unsigned chchan: 1; //cambio de canal, si es 0 o el 1
        unsigned : 1;
        unsigned : 1;
        unsigned : 1;
        unsigned : 1;
        unsigned : 1;
        unsigned : 1;
    };
}bandera1;

uint8_t POT1, POT2;

//----------------------------prototipos----------------------------------------
void configuracion(void);
//-----------------------------Interrupciones-----------------------------------
void __interrupt() isr(void){
    
    if(PIR1bits.ADIF){
        bandera1.updt = 1;  //coloca bandera en 1
        PIR1bits.ADIF = 0;  //apaga bandera de converison analogica
        bandera1.chchan = ~bandera1.chchan;   //cambio de canal
        INTCONbits.T0IF = 0;
        if (!bandera1.chchan)ADCON0bits.CHS0 = 1;
        else ADCON0bits.CHS0 = 0; //Cambia de puerto analogico
        TMR0 = 250;
    }
   
}
//-----------------------------MAIN---------------------------------------------
void main(void) {
    configuracion();
    
    while(1){
        if(INTCONbits.T0IF){
            
            if(bandera1.updt && !bandera1.chchan){
                POT1 = ADRESH;
                bandera1.updt = 0;  //apaga la bandera
                PORTB = POT1;     //El valor se despliega en leds en PORTB
                ADCON0bits.GO = 1;  //De nuevo comienza a contar
            }
            
            if(bandera1.updt && bandera1.chchan){
                POT2 = ADRESH;
                bandera1.updt = 0;  //apaga la bandera
                PORTC = POT2;     //El valor se despliega en leds en PORTB
                ADCON0bits.GO = 1;  //De nuevo comienza a contar
            }
            
        }
    }
    
}

//------------------------------Funciones---------------------------------------
void configuracion(void){
    //Configuracion de puertos y entradas
    ANSEL =     0X03;   //AN0 Y AN1 analogicos
    ANSELH =    0X00;
    TRISA =     0X03;   //RA0 Y RA1 entradas, demas salidas
    TRISB =     0X00;   //Demas puertos como salidas
    TRISC =     0X00;
    TRISD =     0X00;
    PORTA =     0X00;   //inicializando el valor del puerto
    PORTB =     0X00;
    PORTC =     0X00;
    PORTD =     0X00;
    
    bandera1.chchan = 1;    //comienza con el canal AN0
    
    //Configuracion del ADC
    //ADCON0
    ADCON0bits.ADCS =   0b01;   //2us para obtener el resultado
    ADCON0bits.CHS =    0b0000; //selecciona canal AN0
    ADCON0bits.GO =     0b0;    //no esta conviertiendo
    ADCON0bits.ADON =   0b1;    //modulo encendido
    //ADCON1
    ADCON1bits.ADFM =   0b0;    //justificado a la izquierda
    //no se modifican referencia, default usa VSS y VDD.
    
    //Configuracion de interrupciones
    INTCONbits.GIE =    0b1;    //habilitar interrupciones globales
    INTCONbits.PEIE =   0b1;    //habilitar interrupciones perifericas
    PIE1bits.ADIE =     0b1;    //habilitar interrupciones de ADC
    PIR1bits.ADIF =     0b0;    //apaga la bandera del ADC
    
    //Configuracion timmer0
    OSCCONbits.SCS = 1;
    OPTION_REGbits.T0CS = 0;    //Timmer 0 a FOSC y Prescalador asignado
    OPTION_REGbits.PSA  = 0;
    OPTION_REGbits.PS2  = 0;    //valor del prescalador|
    OPTION_REGbits.PS1  = 0;
    OPTION_REGbits.PS0  = 0;
    INTCONbits.T0IF =     0;
    TMR0 = 250; 
    
    ADCON0bits.GO =     0b1;    //esta conviertiendo
}