/* 
 * File:   main9.c
 * Author: jalva
 *
 * Creado el 24 de abril de 2021.
 * Modificado el 24 de abril de 2021.
 */

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
//oscillator:I/O function on RA6/OSC2/CLKOUT pin,I/O function on RA7/OSC1/CLKIN)
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

//--------------------------------VARIABLES
uint8_t POT1,POT2;  //variables de manejo de potenciometros

//--------------------------------PROTOTIPOS
void configuraciones(void);

//---------------------------------INTERRUPCION

void __interrupt() inter(void){
    
    if(PIR1bits.ADIF){
        ADCON0bits.CHS0 = ~ADCON0bits.CHS0;
        PIR1bits.ADIF = 0;  //apaga la bandera
        INTCONbits.TMR0IF = 0; //apaga la bandera de ser necesario
        TMR0 = 100;         //procurar que pase el tiempo
    }
    
}

//-------------------------------LOOP PRINCIPAL
void main(void) {
    
    configuraciones();
    //se colocan como 0 los menos significativos
    CCP1CONbits.DC1B0 = 0;
    CCP1CONbits.DC1B1 = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    while(1){
        
        if(!ADCON0bits.CHS0){
            POT1 = ADRESH;
            CCPR2L = (POT1>>1) + 128;  //Valores entre 128 y 255
        }
        
        if(ADCON0bits.CHS0){
            POT2 = ADRESH;
            CCPR1L = (POT2>>1) + 128;  //Valores entre 128 y 255
        }
        
        if(INTCONbits.TMR0IF) {
            ADCON0bits.GO = 1;
            INTCONbits.TMR0IF = 0;}
        
    }
    
}

//-------------------------------FUNCIONES SECUNDARIAS

void configuraciones(void){
    //configuracion puertos
    ANSEL =             0X03;   //primeros dos pines como analogicos
    ANSELH =            0X00;
    TRISA =             0X03;   //primeros dos como entradas
    TRISC =             0X06;   //pines CCPX como entradas y deshabilitados PWM
    
    //configurando el oscilador
    OSCCONbits.IRCF = 0b111; //oscilador a 8Mhz
    OSCCONbits.SCS = 0b1;
    
    //configuracion ADC a 8Mhz
    ADCON0bits.ADCS =   0b10;
    ADCON0bits.CHS =    0b0000;  //comience leyendo en el 0
    ADCON0bits.GO =     0b0;
    ADCON0bits.ADON =   0b1;
    ADCON1bits.ADFM =   0b0; //justificado a la IZQUIERDA
    ADCON1bits.VCFG1 =  0b0; //referencias a alimentacion del PIC
    ADCON1bits.VCFG0 =  0b0;
    
    //configuracion interrupciones
    PIE1bits.ADIE =     1;      //habilita INT del ADC
    PIR1bits.ADIF =     0;     //apaga bandera ADC
    INTCONbits.GIE =    1;     //habilita interrupciones
    INTCONbits.PEIE =   1;    //habilita perifericas
    
    //configuracion PWM
    CCP1CONbits.P1M = 0b00;     //para que se module y solo uno sea salida
    PR2 = 249;                  //precargando para el periodo del PWM
    CCP1CONbits.CCP1M = 0b1100; //asignar como PWM
    CCP2CONbits.CCP2M = 0b1111; //CCP2 como PWM
    CCPR1L = 0x0f;              //precarga duty cicle inicial
    CCPR2L = 0x0f;              //precargando duty cicle inicial
    PIR1bits.TMR2IF = 0;        //apaga la bandera
    T2CONbits.T2CKPS = 0b11;    //prescalador en 16
    T2CONbits.TMR2ON = 1;       //enciende el timmer
    
    while(!PIR1bits.TMR2IF);    //loop para que no cambie a salida hasta un ciclo
    TRISC = 0X00;               //CCP2 como salida habilitada
    
    //configuracion timer0
    OSCCONbits.SCS = 1;
    OPTION_REGbits.T0CS = 0;    //Timmer 0 a FOSC y Prescalador asignado
    OPTION_REGbits.PSA  = 0;
    OPTION_REGbits.PS2  = 0;    //valor del prescalador 2
    OPTION_REGbits.PS1  = 0;
    OPTION_REGbits.PS0  = 0;
    INTCONbits.T0IF =     0;
    TMR0 = 100; 
    ADCON0bits.GO =     0b1;    //Comienza la conversion
    
}