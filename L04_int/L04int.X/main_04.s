; Archivo: main_04.s
; Dispositivo: PIC16F887
; Autor: Jonathan Pu
; Compilador: pic-as (v2.30), MPLABX V5.45
; Programa: contador de 4 leds y display con int de B y un 7seg con int de Tmr0
; Hardware: 2 pb en puerto b, 4 leds en portA, 7seg en puerto C y D
; Creado: 21 feb, 2021
; Ultima modificacion: _______ feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;*******************************************************************************
; bits de configuracion
;*******************************************************************************

    ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = ON            ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

   ; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

 
;*******************************************************************************
; macros (para las interrupciones)
;*******************************************************************************
 int_contador macro
    BTFSS   PORTB, 0
    INCF    PORTA
    BTFSS   PORTB, 1
    DECF    PORTA
    ENDM
    
 reiniciar macro
    BTFSS   T0IF	 ;revisa el overflow del timer0
    MOVLW   134	         ;para los 500ms con el clock 250kHz
    MOVWF   TMR0	 ;mover este valor inicial al timer0
    BCF	    T0IF	 ;
    ENDM    
;*******************************************************************************
; configuracion de variables
;*******************************************************************************
 
 PSECT udata_shr ;Common memory
    display_seven:	DS 2 ;variable para incrementar display
    W_TEMP:	DS 1 ;variable para int y que guarde W
    STATUS_TEMP:	DS 1 ;variable para int y que guarde STATUS
 
;*******************************************************************************
; interrupt vector
;*******************************************************************************
PSECT intVect, class=code, abs, delta=2
ORG 04h	    ;posicion 004h para el interrupt
push:
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP
    
isr:
    BANKSEL PORTB
    int_contador	    ;macro para inc y dec
    BCF	    RBIF	    ;limpia el pin porque cambio de estado en la subrutina
    
pop:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE		    ;stack is poped in the PC
	
;*******************************************************************************
; reset vector
;*******************************************************************************
PSECT resVect, class=code, abs, delta=2
ORG 00h	    ;posicion 0000h para el reset
    resetVec:
	PAGESEL main
	goto main
	
;*******************************************************************************
; configuracion de pines
;*******************************************************************************
PSECT code, delta=2, abs
	ORG 100h

tabla_disp:  ;tabla para el display de 7seg
	CLRF	PCLATH
	BSF	PCLATH, 0   ;PCLATH = 01 PCL =02
	ANDLW	0x0f
	ADDWF	PCL	    ;PCL=PCLATH +PCL+W
	RETLW	00111111B   ;0
	RETLW	00000110B   ;1
	RETLW	01011011B   ;2
	RETLW	01001111B   ;3
	RETLW	01100110B   ;4
	RETLW	01101101B   ;5
	RETLW	01111101B   ;6
	RETLW	00000111B   ;7
	RETLW	01111111B   ;8
	RETLW	01101111B   ;9
	RETLW	01110111B   ;A
	RETLW	01111100B   ;B
	RETLW	00111001B   ;C
	RETLW	01011110B   ;D
	RETLW	01111001B   ;E
	RETLW	01110001B   ;F
    
	ORG 118h
main:
    ;configurar los pines de los leds y 7seg
    BANKSEL TRISA
    BCF	    TRISA, 0
    BCF	    TRISA, 1
    BCF	    TRISA, 2
    BCF	    TRISA, 3
    
    MOVLW   00000000B
    MOVWF   TRISC
    
    MOVLW   00000000B
    MOVWF   TRISD
    
    ;configurar los pines para los dos push
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH
    BANKSEL TRISB
    BSF	    TRISB, 0
    BSF	    TRISB, 1
    BANKSEL OPTION_REG		
    BCF	    OPTION_REG, 7	    ;PORTB pull-ups are enabled by individual PORT latch values
    BANKSEL WPUB
    BSF	    WPUB, 0		    ;hay que configurar todos de manera individual
    BSF	    WPUB, 1
    BCF	    WPUB, 2
    BCF	    WPUB, 3
    BCF	    WPUB, 4
    BCF	    WPUB, 5
    BCF	    WPUB, 6
    BCF	    WPUB, 7
    
   ;configurar timer0
   BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA		;prescaler asignado al timer0
    BSF	    PS0		;prescaler tenga un valor 1:256
    BSF	    PS1
    BSF	    PS2
    
    ;configurar reloj interno
    BANKSEL OSCCON
    BCF	    IRCF0	;el reloj interno 250kHz
    BSF	    IRCF1
    BCF	    IRCF2
    BSF	    SCS
    
    ;configurar interrupcion del puerto B
    BANKSEL IOCB
    MOVLW   00000011B	    ;habilita el interrupt on change para los pines RB0 y RB1
    MOVWF   IOCB
   ; BANKSEL INTCON	
    ;MOVF    PORTB, 0
    ;BSF	    RBIF	;no hay ningun cambio de estado aun*********************
    
    ;configurar bits para interrupciones en general
    BSF	    GIE	    ;habilita las interrupciones globales
    BSF	    RBIE    ;habilita la interrupcion del puertoB
    BSF	    T0IF    ;habilita la interrupcion del timer0
    
    ;limpiar todos los puertos
    BANKSEL PORTA   
    CLRF    PORTA
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTB
    
    
;*******************************************************************************
; loop principal
;*******************************************************************************
main_loop:
    
    GOTO    main_loop
    
;*******************************************************************************
; subrutinas de interrupcion
;*******************************************************************************
/*int_contador:
    BTFSS   PORTB, 0
    INCF    PORTA
    BTFSS   PORTB, 1
    DECF    PORTA
    RETURN*/
    
    
END