/*
 * File: mainL08.c
 * Author: Jonathan Pu
 * Hardware: conversion ADC en leds y 7seg
 * Funcionamiento: conversion de señal de poten y mostrar su valor en decimal
 * y en los leds, leyendo los bits mas significativos
 * Created on April 19, 2021
 */

#include <xc.h>
#include <stdint.h>
#define _XTAL_FREQ 250000
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
#pragma config LVP = ON         // Low Voltage Programming Enable bit 
//(RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit 
//(Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 
//(Write protection off)

/*==============================================================================
                                VARIABLES
 =============================================================================*/
char dividendo, centenas, decenas, unidades, transistores, temporal;
char residuo, contador;
//tabla para la traduccion del 7 segmentos
char tabla_7seg [16] = {0b00111111, 0b00000110, 0b01011011, 
                       0b01001111, 0b01100110, 0b01101101,
                       0b01111101, 0b00000111, 0b01111111,
                       0b01101111, 0b01110111, 0b01111100,
                       0b00111001, 0b01011110, 0b01111001, 0b01110001};

/*==============================================================================
                               INTERRUPCIONES Y PROTOTIPOS
 =============================================================================*/
void setup(void);
void division(void);
void display1(void);
void display2(void);
void display3(void);
void multiplexado(void);

void __interrupt() isr(void){
    if (ADIF == 1){ //ya se termino la conversion
        if (ADCON0bits.CHS == 0){
            PORTC = ADRESH;
        }
        else{
            dividendo = ADRESH;}
        //ADCON0bits.GO = 1;
       ADIF = 0; //apaga la bandera
        }
       
    
    //interrupcion del timer0
    if (T0IF == 1){
        multiplexado();
        TMR0 = 255;
        INTCONbits.T0IF = 0;
    }  
}



/*==============================================================================
                                LOOP PRINCIPAL
 =============================================================================*/
void main(void) {
    setup();
    ADCON0bits.GO = 1; //iniciar la conversion
    while(1){
        if (ADCON0bits.GO == 0){       //si estaba en el canal0
            if (ADCON0bits.CHS == 1){    
                ADCON0bits.CHS = 0;     //
        }
            else {
                ADCON0bits.CHS = 1;   //si es otro cambiamos el canal de nuevo
            }
        __delay_us(50);
        ADCON0bits.GO = 1; //inicia la conversion otra vez
        }
       division();
    }   
    return;
}

/*==============================================================================
                            CONFIGURACION DE PIC
 =============================================================================*/
void setup(void){
    //Configurar todos los puertos de salidas de los leds y disp con sus transis
    ANSELbits.ANS0 = 1;
    ANSELbits.ANS1 = 1;
    ANSELH = 0x00;
    TRISAbits.TRISA0 = 1;
    TRISAbits.TRISA1 = 1;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;
    //configurar el oscilador interno  
    OSCCONbits.IRCF0 = 0;        //reloj interno de 250khz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.SCS = 1;          //internal oscillator is used for system clock
    //configurar el timer0
    OPTION_REGbits.T0CS = 0;     //oscilador interno
    OPTION_REGbits.PSA = 0;      //prescaler asignado al timer0
    OPTION_REGbits.PS0 = 1;      //prescaler tenga un valor 1:256
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS2 = 1;
    TMR0 = 255;
    //configurar interrupciones
    PIE1bits.ADIE = 1;      //enable de la int del ADC
    PIR1bits.ADIF = 0;      //limpiar la interrupcion del ADC
    INTCONbits.GIE = 1;     //habilita las interrupciones globales
    INTCONbits.T0IE = 1;    //habilita la interrupcion del timer0
    INTCONbits.T0IF = 0;    //limpia bit de int del timer 0
    INTCONbits.PEIE = 1;    //periferical interrupts
    //configurar el modulo ADC
    ADCON0bits.ADCS0 = 1;   //para que el clock select sea FRC
    ADCON0bits.ADCS1 = 1;   //que tiene el osc int hasta 500kHz maximo
    ADCON0bits.ADON = 1;    //ADC enable bit
    ADCON1bits.ADFM = 0;    //left justified
    ADCON1bits.VCFG1 = 0;   //5 voltios
    ADCON1bits.VCFG0 = 0;   //tierra
    ADCON0bits.CHS = 0;     //canal 0
    //limpiar todos los puertos antes
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
            
}

/*==============================================================================
                                    FUNCIONES
 =============================================================================*/

void division (void){
    centenas = dividendo/100;//esto me divide entre 100 y se queda con el entero
    residuo = dividendo%100; //el residuo de lo que estoy operando
    decenas = residuo/10; 
    unidades = residuo%10; //se queda con las unidades de las decenas
    //las variables estan en todo el codigo entonces no necesito el return
    return;
} 

void multiplexado(void){
 
    //PORTE = 0x00; //Para limpiar el puerto de transistores
    transistores = 0x00; //para que se vaya al disp1
    if (transistores == 0b00000000){
        PORTE = 0x00;
        display1();
    }
    if (transistores == 0b00000001){ //para que se vaya al disp2
        PORTE = 0x00;
        display2();
    }
    if (transistores == 0b00000010){ //para que se vaya al disp3
        PORTE = 0x00;
        display3();
    }
    return;
}

void display1(void){
    PORTEbits.RE0 = 1; //apagar y encender los bits correspondientes
    //PORTEbits.RE2 = 0;
    PORTD = (tabla_7seg[centenas]); //traducir las centenas llamando la pos del
    transistores = 0b00000001; //array, ahi cambia de transistor para el disp2
    
    return;
}

void display2(void){
    
    PORTD = tabla_7seg[decenas];
    transistores = 0b00000010;
    //PORTEbits.RE0 = 0;
    PORTEbits.RE1 = 1;
    return;}


void display3(void){
    
    PORTD = tabla_7seg[unidades];
    transistores = 0x00;
    //PORTEbits.RE1 = 0;
    PORTEbits.RE2 = 1;
    return;
}
