; Archivo: main_t0.s
; Dispositivo: PIC16F887
; Autor: Jonathan Pu
; Compilador: pic-as (v2.30), MPLABX V5.45
; Programa: display 7 segmentos que coincide con 4leds y una alarma
; Hardware: 4 leds en el puerto C y un display 7 segmentos en D, alarme en E
; con pushbuttons en A para los leds
; Creado: 15 feb, 2021
; Ultima modificacion: 12 feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;*******************************************************************************
; bits de configuracion
;*******************************************************************************
    ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT            ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
PSECT udata_shr ;Common memory
 display_seven:	DS 2 ;variable para incrementar display
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
	
PSECT code, delta=2, abs
    ORG 114h
  
main:
    BANKSEL ANSEL	;configuracion para que sean digitales
    CLRF    ANSEL
    BANKSEL ANSELH
    CLRF    ANSELH
    
    BANKSEL TRISA	;configuracion de pines de entrada en pull-up
    BSF	    TRISA, 0
    BSF	    TRISA, 1
    BSF	    TRISA, 6
    BSF	    TRISA, 7
    BANKSEL TRISB	;configuracion de pines de salida para contador led
    BCF	    TRISB, 0
    BCF	    TRISB, 1
    BCF	    TRISB, 2
    BCF	    TRISB, 3
    BANKSEL TRISD	;configuracion de pines de display 7 segmentos
    BCF	    TRISD, 0
    BCF	    TRISD, 1
    BCF	    TRISD, 2
    BCF	    TRISD, 3
    BCF	    TRISD, 4
    BCF	    TRISD, 5
    BCF	    TRISD, 6
    BCF	    TRISD, 7
    BANKSEL TRISE	;configuracion para led de alarma
    BCF	    TRISE, 0
       
    BANKSEL PORTA	;limpiar puertos para iniciar el programa
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTD
    CLRF    PORTE
    
    BANKSEL OSCCON
    BCF	    IRCF0
    BSF	    IRCF1
    BCF	    IRCF2
    BSF	    SCS
     
    BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA
    BSF	    PS0
    BSF	    PS1
    BSF	    PS2
    
    BANKSEL PORTA
    CALL    reiniciar
    
	
;*******************************************************************************
; loop principal
;*******************************************************************************
   
    mainloop:
	BTFSS	T0IF		;revisa el overflow del timer0
	GOTO	$-1
	CALL	reiniciar	;borra el overflow del timer 0
	INCF	PORTB, 1	;incrementa el puerto b y lo guarda en ese registro
	CALL	reiniciar	;pushes para incrementar el 7seg
	BTFSS	PORTA, 0	;revisa el push 1 que incrementa
	CALL	incrementar_display
	BTFSS	PORTA, 1	;push 2 para decrementar
	CALL	decrementar_display
	BCF	PORTE, 0	;esto hace que se pueda apagar el led de alarma
	CALL	alarma		;subrutina de alarma
	GOTO	mainloop
	
;*******************************************************************************
; subrutinas
;*******************************************************************************
    reiniciar:
	BTFSS	T0IF		;revisa el overflow del timer0
	MOVLW	134     ;para los 500ms con el clock 250kHz
	MOVWF   TMR0	;mover este valor inicial al timer0
	BCF	T0IF	;
	RETURN
	
    incrementar_display:
	BTFSS	PORTA, 0
	GOTO	$-1
	INCF	display_seven
	MOVF	display_seven, W    ;para que funcione el 7seg se usa la variable para 'traducir' a hex
	CALL	tabla_disp
	MOVWF	PORTD, 1
	RETURN

    decrementar_display:	    ;rutina para decrementar usando la misma tabla
	BTFSS	PORTA, 1
	GOTO	$-1
	DECF	display_seven
	MOVF	display_seven, W
	CALL	tabla_disp
	MOVWF	PORTD, 1
	RETURN
	
    alarma:
	MOVF	display_seven, 0    
	SUBWF	PORTB, 0
	BTFSC	STATUS, 2	    ;este bit revisa si el resultado es 0 y se hace el carry
	CALL	led		    ;subrutina para probar el led
	RETURN
	
    led:
	BANKSEL PORTE		    
	CLRF	PORTE		    ;inicializar puerto e
	BSF	PORTE, 0	    ;encender el led
	CLRF	PORTB		    ;reiniciar contador en puerto b
	RETURN			    
	
	
END