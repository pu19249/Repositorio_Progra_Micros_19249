/*
 * Archivo:   main_brazo.c
 * Autor: Jonathan Pu c.19249
 * Descripcion de hardware: 3 servomotores para el control de los brazos, 
 * 1 motor reductor para mover la base del brazo, potenciometros para el control
 * actuadores digitales para grabar posicion default
 * Descripcion de software: control de servos con funciones de bitbanging,
 * control de motor DC con modulo PWM y comunicacion serial
 * Created on May 19, 2021, 12:10 AM
 */

#include <xc.h>
#include <stdint.h>
#include <stdio.h> //libreria para mandar str en comunicacion serial
#include <pic16f887.h> 
#define _XTAL_FREQ 4000000
/*=============================================================================
                        BITS DE CONFIGURACION
 =============================================================================*/
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
//oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/
//CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and 
//can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR 
//pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code 
//protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code 
//protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal
///External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit 
//(Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF         // Low Voltage Programming Enable bit 
//(RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
//(Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 
//(Write protection off)

void setup(void);

void main(void){
    setup();
     
    while(1){
        RB0 = 1;
        __delay_ms(500);
        RB0 = 0;
        __delay_ms(500);
    }
}

void setup(void){
    TRISBbits.TRISB0 = 0;
    PORTB = 0X00;
    //Configurar reloj interno
    OSCCONbits.IRCF0 = 0;        //reloj interno de 4mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.SCS = 1;  //internal oscillator is used for system clock
}