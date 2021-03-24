; Archivo: main_04.s
; Dispositivo: PIC16F887
; Autor: Jonathan Pu
; Compilador: pic-as (v2.30), MPLABX V5.45
; Programa: tmr1, tmr0 y tmr2 para temporizar leds y 7seg
; Hardware: 2 7seg y un led intermitentes
; Creado: 23 marzo, 2021
; Ultima modificacion: 23 marzo, 2021
    
    
    
PROCESSOR 16F887
#include <xc.inc>
    
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;				bits de configuracion
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

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

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Declaracion de variables
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
	 

    PSECT udata_shr	    ;Common memory

W_TEMP:		DS 1	    ;variable para int y que guarde W
STATUS_TEMP:	DS 1	    ;variable para int y que guarde STATUS
dos7seg:	DS 2	    
transistores:	DS 1	    ;pines para los transistores de los display
dos7seg_disp:	DS 2	    ;la variable que ya me lo muestra en el display 
timer1:		DS 1	    ;variable para la parte 1
titilar:	DS 1
  
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Vector de reset
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
  
  PSECT resVect, class=code, abs, delta=2
ORG 00h	    ;posicion 0000h para el reset
    resetVec:
	PAGESEL main
	goto main
	
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Interrupciones
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
PSECT intVect, class=code, abs, delta=2
ORG 04h	    ;posicion 004h para el interrupt

push:
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP
    
isr:
    BANKSEL PORTB
    
    BTFSC   TMR1IF
    CALL    reiniciar1
    BTFSC   T0IF
    CALL    int_t0
    
    BTFSC   TMR2IF
    CALL    int_t2
    BANKSEL TMR2
    BCF	    TMR2IF
    


pop:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE		    ;stack is poped in the PC

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Configuracion de pines
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
	
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
    
    
main: 
    ;CONFIGURAR SALIDAS DE LOS DISPLAYS Y TRANSISTORES Y LED
    BANKSEL	TRISC
    MOVLW	00000000B
    MOVWF	TRISC
    
    BCF		TRISD, 0
    BCF		TRISD, 1
    
    BCF		TRISE, 0
    

    
    ;CONFIGURAR TIMERS
    
    ;configurar bits para interrupciones en general
    BANKSEL	INTCON
    BSF	    GIE		    ;habilita las interrupciones globales
    BSF	    T0IE	    ;habilita la interrupcion del timer0
    BCF	    T0IF	    ;limpiar puerto para el timer0
    BCF	    TMR1IF	    ;limpiar la bandera para el tmr1
    
    ;configurar TMR0
    BANKSEL OPTION_REG
    BCF	    T0CS	    ;oscilador interno
    BCF	    PSA		    ;prescaler asignado al timer0
    BSF	    PS0		    ;prescaler tenga un valor 1:256
    BSF	    PS1
    BSF	    PS2
    
    ;configurar TMR1
    BANKSEL T1CON
    BSF	    T1CKPS1	    ;prescaler de 1:8 para el timer1
    BSF	    T1CKPS0
    BCF	    TMR1CS	    ;internal clock FOSC/4
    BSF	    TMR1ON	    ;enables timer1
     
    ;configurar TMR2
    BANKSEL T2CON
    MOVLW   1001110B	    ;primeros 4bits para postscaler (10), timer2 is on,
			    ;prescaler is 16
    MOVWF   T2CON	    ;muevo los valores al registro
    
;    ;habilitar interrupciones para TMR1 y TMR2
    BANKSEL PIE1
    BSF	    TMR2IE	    ;enables the timer2 to pr2 match interrupt
    BSF	    TMR1IE	    ;enables the timer1 overflow interrupt
    BANKSEL PIR1
    BCF	    TMR2IF	    ;limpiar banderas para timer2
    BCF	    TMR1IF	    ;limpiar bandera de interrupcio para timer1
   
    BANKSEL	PORTE
    CLRF	PORTE
    CLRF	PORTD
    CLRF	PORTC
 
    
    
    
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			    LOOP PRINCIPAL
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
    loop:
	CALL	    multiplexar
	
	;CALL	    mostrar_display
	BTFSS	    titilar, 0		;si esta en 1 se va a revisar si esta en 0
	CALL	    mostrar_display	;se encendio en el timer2 entonces apaga todo
	BTFSC	    titilar, 0		
	CALL	    apagar_disp
	GOTO	    loop
    
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			SUBRUTINAS DE INTERRUPCION
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
	
apagar_disp:
    ;apaga todo lo que me salia desplegado
    BCF		PORTE, 0
    MOVLW	0
    MOVWF	dos7seg_disp
    MOVWF	dos7seg_disp+1
    RETURN
    
multiplexar:
    MOVF	timer1, 0
    ANDLW	00001111B	
    MOVWF	dos7seg+0	;guardo lo que tengo en mi resultado del AND a W
    SWAPF	timer1, 0	;lo vuelvo a guardar en W
    ANDLW	00001111B		;
    MOVWF	dos7seg+1	;esto permite que tome la parte alta de mi registro de 2bytes
    RETURN
	
mostrar_display:
    MOVF	dos7seg, 0
    CALL	tabla_disp
    MOVWF	dos7seg_disp+0
    MOVF	dos7seg+1, 0
    CALL	tabla_disp
    MOVWF	dos7seg_disp+1
    BSF		PORTE, 0	  ;para que se encienda en este estado
    RETURN
	
timer2_re:
    BANKSEL	PR2
    MOVLW	100
    MOVWF	PR2	    ;para que sean 250ms
;    BANKSEL	TMR2
;    BCF		TMR2IF
;    
    RETURN
 

 int_t2:
    ;CALL	timer2_re
    
    BTFSC	titilar, 0	    ;estas banderas me sirven para cambiar de 
    GOTO	apagar		    ;estado
    
    encender:
    BSF		titilar, 0	    ;si no estaba encendida enciende y asi cambia
    RETURN
    apagar:
    BCF		titilar, 0	    ;sino la apaga (en el proximo ciclo)
    RETURN


reiniciar1:
    BANKSEL	TMR1L
    MOVLW	0xE1
    MOVWF	TMR1L
    MOVLW	0x7C
    MOVWF	TMR1H
	
    INCF	timer1
    BCF		TMR1IF
    RETURN
	
reiniciar:
    MOVLW	254     ;para los 10ms con el clock 250kHz
    MOVWF	TMR0	;mover este valor inicial al timer0
    BCF		T0IF	;
    RETURN
	
int_t0:
    CALL	reiniciar
    BCF		PORTD, 0	 ;para que inicien limpios los transistores
    BCF		PORTD, 1
   
    
    BTFSC	transistores, 0  ;esto hace que si se salta esta linea va al display2
    GOTO	display1	 ;de lo contrario va al display1 porque sigue en las lineas de codigo
      
display0:
    MOVF	dos7seg_disp+0, 0   ;este display no requiere de bandera de transistor
    MOVWF	PORTC		  ;
    BSF		PORTD, 0	    
    GOTO	otrodisp

display1:
    MOVF	dos7seg_disp+1, 0
    MOVWF	PORTC
    BSF		PORTD, 1

otrodisp:
    MOVLW	00000001B
    XORWF	transistores, 1
    RETURN
	
END