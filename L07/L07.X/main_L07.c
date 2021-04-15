/*
 * File:   main_L07.c
 * Author: Jonathan Pu
 * Hardware: 2 contadores de 8 leds, tres 7seg, dos botones
 * Funcionamiento: contador que inc y dec con dos botones, contador que inc
 * con timer0, display que muestra lo de los botones en decimal
 * Created on April 12, 2021, 10:36 PM
 */

#include <xc.h>
#include <stdint.h>
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
void multiplexado(void);
void display1(void);
void display2(void);
void display3(void);
char division(char dividendo);

void __interrupt() isr(void)
{
    if (T0IF == 1)              
    {
     //SE COMENTA PARA LA SEGUNDA PARTE DEL LABORATORIO
      PORTD = PORTD + 1;         //suma 1 al valor del puerto b
     INTCONbits.T0IF = 0;       //limpia la bandera de int del tmr0
     
     //division();
        //AHORA LLAMAMOS AL MULTIPLEXADO
        multiplexado();
        TMR0 = 255;
        INTCONbits.T0IF = 0;
    }   
    //para los dos botones del puerto b del segundo contador
    if (RBIF == 1){             //evaluar bandera de la int del puertoB
        if (PORTBbits.RB0 == 0){        //son pull ups
            PORTC++;           //incrementa
            INTCONbits.RBIF = 0;        //limpiar la bandera despues de la int
         }
    
         if (PORTBbits.RB1 == 0){
             PORTC--;            //decrementa
             INTCONbits.RBIF = 0;       //limpiar la bandera despues de la int
         }
    }
}

/*==============================================================================
                                LOOP PRINCIPAL
 =============================================================================*/
void main(void) {
    setup();
    while(1){
    contador = PORTC; //lo que esta en mi contador de botones a una variable
    division(contador);  
    }
    return;
}
/*==============================================================================
                            CONFIGURACION DE PIC
 =============================================================================*/
void setup(void){
    //Configurar todos los puertos de salidas de los leds y disp con sus transis
    ANSEL = 0x00;
    ANSELH = 0x00;
    TRISA = 0x00;
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;
    //entradas de los botones
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
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
    IOCBbits.IOCB0 = 1;      //interrupciones para los botones en el portb
    IOCBbits.IOCB1 = 1;
    INTCONbits.RBIF = 0;    //limpia bit de int del puertoB
    INTCONbits.GIE = 1;     //habilita las interrupciones globales
    INTCONbits.RBIE = 1;    //habilita la interuupcion del puertoB
    INTCONbits.T0IE = 1;    //habilita la interrupcion del timer0
    INTCONbits.T0IF = 0;    //limpia bit de int del timer 0
    //limpiar todos los puertos antes
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
            
}

/*==============================================================================
                                    FUNCIONES
 =============================================================================*/


void multiplexado(){
 
    PORTE = 0x00; //Para limpiar el puerto de transistores
    transistores = 0b00000000; //para que se vaya al disp1
    if (transistores == 0b00000000){
        display1();
    }
    if (transistores == 0b00000001){ //para que se vaya al disp2
        display2();
    }
    if (transistores == 0b00000010){ //para que se vaya al disp3
        display3();
    }
    
}

void display1(void){
    PORTEbits.RE0 = 1; //apagar y encender los bits correspondientes
    PORTEbits.RE2 = 0;
    PORTA = 0x00;  //para inicializar el puertoa
    PORTA = tabla_7seg[centenas]; //traducir las centenas llamando la pos del
    transistores = 0b00000001; //array, ahi cambia de transistor para el disp2
    return;
}

void display2(void){
    PORTEbits.RE0 = 0;
    PORTEbits.RE1 = 1;
    PORTA = tabla_7seg[decenas];
    transistores = 0b00000010;
    return;
}

void display3(void){
    PORTEbits.RE1 = 0;
    PORTEbits.RE2 = 1;
    PORTA = tabla_7seg[unidades];
    transistores = 0x00;
    return;
}

char division (char dividendo){
    centenas = dividendo/100;//esto me divide entre 100 y se queda con el entero
    residuo = dividendo%100; //el residuo de lo que estoy operando
    decenas = residuo/10; 
    unidades = residuo%10; //se queda con las unidades de las decenas
    //las variables estan en todo el codigo entonces no necesito el return
    return dividendo;
} 