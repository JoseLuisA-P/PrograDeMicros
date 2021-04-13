/* 
 * File:   main.c
 * Autor: Jose Luis Alvarez Pineda
 *
 * Creado: 12 de abril de 2021
 * Modificado: 13 de abril de 2021
 * Funcionamiento: se utiliza el timmer 0 para multiplexar valores mostrados
 * en un 7 segmentos, los cuales incrementan o decrementan con dos botones.
 * 
 * Hardware:
 * Puerto A: indicador binario del valor a aumentar.
 * Puerto B: los primeros dos botones, 0 para aumentar y 1 para decrementar.
 * Puerto C: utilizado para multiplexar.
 * Puerto D: los puertos asignados a cada display.
 */
//LIBRERIAS INCLUIDAS
#include <xc.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

//BITS DE CONFIGURACION
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
//oscillator: I/O function on RA6/OSC2/CLKOUT pin, 
//I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and 
//can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON       // RE3/MCLR pin function select bit 
//(RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit 
//(Program memory code protection is disabled)
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

//PROTOTIPOS DE LAS FUNCIONES
void configuracion(void);
void multiplexado(uint8_t val);
void division(uint8_t conteo,uint8_t* un,uint8_t* dec,uint8_t* cent);

//VARIABLES a utilizar
uint8_t Contador = 0,Conteo = 0, Uni = 0, Dec = 0, Cent = 0;
unsigned MUX = 0;

//para el manejo de las interrupciones
void __interrupt() isr(void){
    if(INTCONbits.RBIF && !PORTBbits.RB0){
        Contador++;
        PORTB = PORTB;
        INTCONbits.RBIF = 0;
    } 
    if(INTCONbits.RBIF && !PORTBbits.RB1){
        Contador--;
        PORTB = PORTB;
        INTCONbits.RBIF = 0;
    } 
    if(INTCONbits.T0IF){
        //PORTC++;      linea de la parte 1 para mostrar el funcionamiento
        Conteo++;
        MUX = 1;
        INTCONbits.T0IF = 0;
        TMR0 = 217;
    }
    INTCONbits.RBIF = 0;    //apagarla cuando vuelve a cambiar 
}

void main(void) {
    configuracion();
    
    do{
        PORTA = Contador;
        
        if(MUX){    //Para que solo actualice acorde al timmer
            if(Conteo >2) Conteo = 0;
            division(Contador,&Uni,&Dec,&Cent);  //realiza la division
        switch(Conteo){
            case 0:
                PORTC = 0X00;
                multiplexado(Uni);
                PORTC = 0X01;
                break;
            case 1:
                PORTC = 0X00;
                multiplexado(Dec);
                PORTC = 0X02;
                break;
            case 2:
                PORTC = 0X00;
                multiplexado(Cent);
                PORTC = 0X04;
                break;
            
        } 
        MUX = 0;
    }
    }while(1);
}

void configuracion(void){
    //CONFIGURACION ENTRADA Y SALIDA DE LOS PUERTOS
    ANSEL =     0X00;      //desactivar analogicos
    ANSELH =    0X00;      
    TRISA =     0X00;   //todos los puertos como salidas
    TRISB =     0X03;   //primeros dos entradas, demas salidas
    TRISC =     0X00;
    TRISD =     0X00;
    PORTB =     0X00;  //inicializando valor de los puertos
    PORTC =     0X00;
    PORTD =     0X00;
    
    //CONFIGURACIONES DE LAS INTERRUPCIONES
    INTCONbits.GIE =  1;    //habilitando interrupciones globales
    INTCONbits.RBIE = 1;    //habilitando interrupciones del PORTB
    PORTB = PORTB;
    INTCONbits.RBIF = 0;
    INTCONbits.T0IE = 1;    //habilitando interrupciones del TIMER0
    INTCONbits.T0IF = 0;
    TMR0 = 217;
    //CONFIGURACION DE LAS INTERRUPCIONES EN B
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;     //Colocando las pullups
    WPUBbits.WPUB1 = 1;
    IOCBbits.IOCB0 = 1;     //Colocando las interrupciones de cambio
    IOCBbits.IOCB1 = 1;
    PORTB = PORTB;
    INTCONbits.RBIF = 0;
    Contador = 0X00;
    //CONFIGURADNO EL TIMMER0
    OSCCONbits.SCS = 1;
    OPTION_REGbits.T0CS = 0;    //Timmer 0 a FOSC y Prescalador asignado
    OPTION_REGbits.PSA  = 0;
    OPTION_REGbits.PS2  = 1;    //valor del prescalador|
    OPTION_REGbits.PS1  = 1;
    OPTION_REGbits.PS0  = 0;
   
}

void multiplexado(uint8_t val){
    switch(val){    //depende el valor asi le asigna al puerto D
        case 0:
        PORTD = 0b00111111;	break;//0
        case 1:
        PORTD = 0b00000110; break;//1
        case 2:
        PORTD = 0b01011011;	break;//2
        case 3:
        PORTD = 0b01001111;	break;//3
        case 4:
        PORTD = 0b01100110;	break;//4
        case 5:
        PORTD = 0b01101101;	break;//5
        case 6:
        PORTD = 0b01111101;	break;//6
        case 7:
        PORTD = 0b00000111;	break;//7
        case 8:
        PORTD = 0b01111111;	break;//8
        case 9:
        PORTD = 0b01100111;	break;//9   
        default:
        PORTD = 0b00111111;	break;//0
    }
}

void division(uint8_t conteo,uint8_t* un,uint8_t* dec,uint8_t* cent){
    uint8_t div = conteo;
    *un =   0;
    *dec =  0;
    *cent = 0;
    //modifica los valores de las variables asignadas de forma inmediata
    
    while(div >= 100){
    *cent = div/100;
    div = div - (*cent)*(100);
    }
    
    while (div >= 10){
    *dec = div/10;
    div = div - (*dec)*(10);
    }
    
    *un = div;
}