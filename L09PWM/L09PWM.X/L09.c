/*
 * File: mainL09.c
 * Author: Jonathan Pu
 * Hardware: conversion ADC, PWM y dos servos
 * Funcionamiento: control de dos servomotores con PWM en pines analogicos
 * Created on April 27, 2021
 */

#include <xc.h>
#include <stdint.h>
#define _XTAL_FREQ 8000000
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
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit 
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


/*==============================================================================
                               INTERRUPCIONES Y PROTOTIPOS
 =============================================================================*/
void setup(void);


void __interrupt() isr(void){
    if (ADIF == 1){
        if (ADCON0bits.CHS == 0){
            CCPR1L = (ADRESH>>1)+124;  //para que tome el rango desde el centro
            CCP1CONbits.DC1B1 = ADRESH & 0b01; //toma uno de los b que falta
            CCP1CONbits.DC1B0 = ADRESL>>7; //para el otro bit
        }
        else{ //el otro canal de PWM
            CCPR2L = (ADRESH>>1)+124;
            CCP2CONbits.DC2B1 = ADRESH & 0b01;
            CCP2CONbits.DC2B0 = ADRESL>>7;
        }
            ADIF = 0;           //apaga la bandera
        //}
    }
}

/*==============================================================================
                                LOOP PRINCIPAL
 =============================================================================*/

void main(void) {
    setup();
  
    while(1){
        if (ADCON0bits.GO == 0){       //si estaba en el canal0
            if (ADCON0bits.CHS == 1){    
                ADCON0bits.CHS = 0;     //
        }
            else {
                ADCON0bits.CHS = 1;   //si es otro cambiamos el canal de nuevo
            }
        __delay_us(100);
        ADCON0bits.GO = 1; //inicia la conversion otra vez
        }
    }
    return;
}

/*==============================================================================
                            CONFIGURACION DE PIC
 =============================================================================*/
void setup(void){
    //estos dos son los de mis pot
    ANSELbits.ANS0 = 1;
    ANSELbits.ANS1 = 1;
    ANSELH = 0x00;
    //en estos dos puertos estan mis servomotores
    TRISAbits.TRISA0 = 1;
    TRISAbits.TRISA1 = 1;
    
    //configurar el oscilador interno  
    OSCCONbits.IRCF0 = 1;        //reloj interno de 8mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.SCS = 1;      
     
    //configurar el modulo ADC
    ADCON0bits.CHS = 0;     //canal 0
    __delay_us(100);
    
    ADCON0bits.ADCS0 = 0;   //para que el clock select sea FOSC/32
    ADCON0bits.ADCS1 = 1;   //que tiene el osc int hasta 500kHz maximo
    ADCON0bits.ADON = 1;    //ADC enable bit
    ADCON1bits.ADFM = 0;    //left justified
    ADCON1bits.VCFG1 = 0;   //5 voltios
    ADCON1bits.VCFG0 = 0;   //tierra
    
    
    //configuracion del PWM junto con el TMR2
    TRISCbits.TRISC2 = 1;   //habilitar momentaneamente el pin de salida
    TRISCbits.TRISC1 = 1;
    PR2 = 250;               //queremos que sea de 20ms por el servo
    CCP1CONbits.P1M = 0;    //modo PWM single output     
    CCP2CONbits.CCP2M = 0b1111; //para que sea PWM
    CCP1CONbits.CCP1M = 0b00001100; //PWM mode, P1A, P1C active-high
    
    
    CCPR1L = 0x0F;          //ciclo de trabajo
    CCP1CONbits.DC1B = 0;   //los bits menos significativos
    CCPR2L = 0x0F;
    CCP2CONbits.DC2B0 = 0; 
    CCP2CONbits.DC2B1 = 0;
    
    
    PIR1bits.TMR2IF = 0;    //limpiar la interrupcion del timer2
    T2CONbits.T2CKPS0 = 0;   //configurar el prescaler a 16
    T2CONbits.T2CKPS1 = 1;        
    T2CONbits.TMR2ON = 1;   //habilitar el tmr2on
    while (PIR1bits.TMR2IF == 0);
    PIR1bits.TMR2IF = 0;    //limpiar nuevamente
    TRISCbits.TRISC2 = 0;   //regresar el pin a salida
    TRISCbits.TRISC1 = 0;
    
    
    //configurar interrupciones
    PIE1bits.ADIE = 1;      //enable de la int del ADC
    PIR1bits.ADIF = 0;      //limpiar la interrupcion del ADC
    INTCONbits.GIE = 1;     //habilita las interrupciones globales
    INTCONbits.PEIE = 1;    //periferical interrupts
    
    
    //limpiar puertos
    PORTC = 0x00;
}
/*==============================================================================
                                    FUNCIONES
 =============================================================================*/


