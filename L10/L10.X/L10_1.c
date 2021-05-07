/*
 * File: mainL09.c
 * Author: Jonathan Pu
 * Hardware: terminal de comunicacion serial
 * Funcionamiento: comunicacion serial del pic a la compu desplegando el valor
 * en el puerto B y puerto A recibiendo el valor desde la terminal 
 * Created on May 4th, 2021
 */

#include <xc.h>
#include <stdint.h>
#include <stdio.h> //libreria para mandar str en comunicacion serial
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
char puerto_a, puerto_b;
/*==============================================================================
                               INTERRUPCIONES Y PROTOTIPOS
 =============================================================================*/
void setup(void);
void putch(char data); //funcion para recibir el dato que se desea transmitir
void mensaje(void);

/*==============================================================================
                                LOOP PRINCIPAL
 =============================================================================*/
void main(void){
    setup();
    
    while (1){
        mensaje();
        
    }
}

/*==============================================================================
                                    FUNCIONES
 =============================================================================*/
void putch(char data){
    while(TXIF == 0);
    TXREG = data; //transmite los datos al recibir un printf en alguna  parte 
    return;
}

void mensaje(void){
    __delay_ms(500); //para que despliegue los datos en el tiempo correcto
    printf("\r Que accion desea ejecutar \r");
    __delay_ms(250);
    printf("(1) Desplegar cadena de caracteres \r");
    __delay_ms(250);
    printf("(2) Cambiar PORTA \r");
    __delay_ms(250);
    printf("(3) Cambiar PORTB \r");
    while (RCIF == 0);
    if (RCREG == '1'){
        __delay_ms(500);
        printf("\r Usted puede leer este mensaje \r");
    }
    if (RCREG == '2'){ //segunda opcion del menu
        printf("\r Presione el caracter para desplegar en PORTA: \r");
        while (RCIF == 0);
        puerto_a = RCREG; //para recibir un caracter
        PORTA = puerto_a;
    }
    if (RCREG == '3'){ //tercera opcion del menu
        printf("\r Presione el caracter para desplegar en PORTB: \r");
        while (RCIF == 0);
        puerto_b = RCREG;
        PORTB = puerto_b;
    }
    else{ //cualquier otra opcion que no este en el menu
        NULL;
    }
    return;
}
/*==============================================================================
                            CONFIGURACION DE PIC
 =============================================================================*/

void setup (void){
    //salida en el puerto B del valor ascii
    TRISA = 0x00;
    TRISB = 0x00;
    ANSELH = 0x00;
    
    //configurar el oscilador interno  
    OSCCONbits.IRCF0 = 1;        //reloj interno de 8mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.SCS = 1;   
    
    //configurar transmisor y receptor asincrono
    SPBRG = 207;         //para el baud rate de 600
    SPBRGH = 0;
    BAUDCTLbits.BRG16 = 1; //8bits baud rate generator is used
    TXSTAbits.BRGH = 1; //high speed
    
    TXSTAbits.SYNC = 0; //asincrono
    //serial port enabled (Configures RX/DT and TX/CK pins as serial)
    RCSTAbits.SPEN = 1; 
    RCSTAbits.CREN = 1; //habilitar la recepcion
    
    TXSTAbits.TX9 = 0; //transmision de 8bits
    TXSTAbits.TXEN = 1; //enable the transmission
    RCSTAbits.RX9 = 0; //recepcion de 8 bits
      
    //PIE1bits.TXIE = 1; //porque quiero las interrupciones de la transmision
    INTCONbits.GIE = 1; //enable de global interrupts
    INTCONbits.PEIE = 1;
    //PIE1bits.RCIE = 1; //interrupciones del receptor
    PIR1bits.TXIF = 0;  //limpiar interrupciones
    PIR1bits.RCIF = 0;
    
    //limpiar puerto
    PORTA = 0x00;
    PORTB = 0x00;
}