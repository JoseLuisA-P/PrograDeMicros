/* 
 * File:   main10.c
 * Author: jalva
 *
 * Created on 3 de mayo de 2021, 09:35 AM
 * Editado: 3 de mayo de 2021
 * 
 * Hardware:
 * PuertoA y Puerto B, salidas en led del valor ingresado
 * Puerto C, pines RX/TX salida y entrada para comunicacion serial asincrona
 */

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits 
//(INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and 
//can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON       // RE3/MCLR pin function select bit (
//RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit 
//(Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit 
//(Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits 
//(BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit 
//(Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit 
//(Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit 
//(RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
//(Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory 
//Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#define _XTAL_FREQ 8000000 // Frecuencia de reloj

uint8_t estado, dato, cambio;

//-----------------------------Prototipos
void configuraciones(void);
void send1dato(char dato);
void sendString(unsigned char* mensaje);

void __interrupt() rutinterrupcion(void){
    if(PIR1bits.RCIF){
        dato = RCREG; 
        PIR1bits.RCIF = 0;
        cambio = 1;
    }
}

void main(void) {
    
    configuraciones();
     
    while(1){
        /*Codigo de la parte 1
        __delay_ms(500);
        send1dato('a');  
        if(PIR1bits.RCIF) PORTB = RCREG; //mira si hay dato para leer*/
        
        //codigo de la parte 2
        switch(estado){
            case 0:
                sendString("\rQue accion desea ejecutar? \r");
                sendString("(1) Desplegar cadena de caracteres \r");
                sendString("(2) Cambiar PORTA \r");
                sendString("(3) Cambiar PORTB\r");
                estado = 20;
                break;
            case 1:
                sendString("\rCadena enviada\r\r");
                dato = 0;
                estado = 0;
                break;
            case 2:
                sendString("\rValor para el puerto A\r");
                while(!cambio);
                PORTA = dato;
                dato = 0;
                estado = 0;
                break;
            case 3:
                sendString("\rValor para el puerto B\r");
                while(!cambio);
                PORTB = dato;
                dato = 0;
                estado = 0;
                break;
            case 20:
                cambio = 0;
                if(dato == '1') estado = 1;
                if(dato == '2') estado = 2;
                if(dato == '3') estado = 3;
                break;
            default:
                break;
        }
    }
}

void configuraciones(void){
    ANSEL =         0X00;
    ANSELH =        0X00;
    TRISA =         0X00;
    TRISB =         0X00;
    TRISCbits.TRISC6 = 0;   //TX como salida
    TRISCbits.TRISC7 = 1;   //RX como entrada
    PORTA =         0X00;
    PORTB =         0X00;
    PORTC =         0X00;
    
    estado = 0;
    
    //configurando el oscilador
    OSCCONbits.IRCF = 0b111; //oscilador a 8Mhz
    OSCCONbits.SCS = 0b1;
    
    //configuracion de las interrupciones
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
    PIE1bits.RCIE   = 1; //permite interrupciones de recepcion de datos
    
    //Configuracion del EUSART
    SPBRG =                 12;      //12 para un baud rate de 9615
    TXSTAbits.BRGH =        0;      //baja velocidad por el reloj
    TXSTAbits.TXEN =        1;      //habilitar transmision
    RCSTAbits.CREN =        1;      //habilita la recepcion
    TXSTAbits.SYNC =        0;      //modo asincrono
    RCSTAbits.SPEN =        1;      //configura los pines como seriales
    
}

void send1dato(char dato){ 
    TXREG = dato;   //carga el dato que se va a enviar
    while(!TXSTAbits.TRMT); //espera hasta que se envie el caracter
}

void sendString(unsigned char* mensaje){ // \r se utiliza para el salto de linea
    while(*mensaje != 0x00){    //mira si el valor es distinto a 0
        send1dato(*mensaje);    //si lo es, envia el dato
        mensaje ++;             //apunta a la siguiente letra en el mensaje
    }//como apunta a la direccion de inicio de todo el string, con cada
     //iteracion cambia al siguiente caracter del string
}