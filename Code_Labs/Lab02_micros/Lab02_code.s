; Archivo: Lab02_code.s
; Dispositivo: PIC16F887
; Autor: Jonathan Pu
; Compilador: pic-as (v2.30), MPLABX V5.45
;
; Programa: contador con pushbuttons
; Hardware: LEDS en el puerto C, D, E, push en A
;
; Creado: 09 feb, 2021
; Ultima modificacion: 12 feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;--------------------------configuration bits-----------------------------------
    ; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
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
  
PSECT udata_shr; common memory
  cont1:    DS 1; 1 byte
  cont2:    DS 1
  cont_small: DS 1 ;1 byte
  cont_big: DS 1
  resultado: DS 1
    
PSECT resVect, class=code, abs, delta=2
;--------------------------vector reset-----------------------------------------
    
ORG 00h	    ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs
ORG 100h    ;posicion para el codigo

;----------------------configuracion de los pines-------------------------------
 
main:
    ;entradas del puerto A
    ;bcf	    STATUS, 5 ;banco00
    ;bcf	    STATUS, 6
    ;clrf    PORTA
    BANKSEL ANSEL
    clrf    ANSEL
    BANKSEL ANSELH
    clrf    ANSELH  ;puertos digitales
    
    ;bsf	    STATUS, 5;banco01
    ;bcf	    STATUS, 6
    BANKSEL TRISA
    bsf	    TRISA, 0 ;RA0 como input
    bsf	    TRISA, 1 ;RA1 como input
    bsf	    TRISA, 2 ;RA2 como input
    bsf	    TRISA, 3 ;RA3 como input
    bsf	    TRISA, 4 ;RA4 como input
    bsf	    TRISA, 6 ;RA6 como input
    bsf	    TRISA, 7 ;RA7 como input
    
    ;puerto B como salida
    ;bcf    STATUS, 5;banco00
    ;bcf    STATUS, 6
    ;clrf   PORTB
    ;bsf    STATUS, 5;banco01
    ;bcf    STATUS, 6
    BANKSEL TRISB
    bcf	    TRISB, 0
    bcf	    TRISB, 1
    bcf	    TRISB, 2
    bcf	    TRISB, 3
    
    ;salidas del puerto C
    ;bcf    STATUS, 5;banco00
    ;bcf    STATUS, 6
    ;clrf   PORTC
    ;bsf    STATUS, 5;banco01
    ;bcf    STATUS, 6
    BANKSEL TRISC
    bcf	    TRISC, 0 ;RC0 como salida
    bcf	    TRISC, 1 ;RC1 como salida
    bcf	    TRISC, 2 ;RC2 como salida
    bcf	    TRISC, 3 ;RC3 como salida
    
    ;salidas del puerto D
    ;bcf    STATUS, 5;banco00
    ;bcf    STATUS, 6
    ;clrf   PORTD
    ;bsf    STATUS, 5;banco01
    ;bcf    STATUS, 6
    BANKSEL TRISD
    bcf	    TRISD, 0 ;RD0 como salida
    bcf	    TRISD, 1 ;RD1 como salida
    bcf	    TRISD, 2 ;RD2 como salida
    bcf	    TRISD, 3 ;RD3 como salida
    ;bcf	    TRISD, 4 ;RD4 como salida
    
    BANKSEL TRISE
    bcf	    TRISE, 0  ;RE0 como salida
    ;regresar al banco 0 para operar
    ;bcf    STATUS, 5	;banco00
    ;bcf    STATUS, 6
    BANKSEL PORTA
    clrf    PORTA
    BANKSEL PORTB
    clrf    PORTB
    BANKSEL PORTC
    clrf    PORTC
    BANKSEL PORTD
    clrf    PORTD
    BANKSEL PORTE
    clrf    PORTE
    BANKSEL STATUS
    clrf    STATUS
;----------------------------loop principal-------------------------------------
    loop:
	btfss PORTA, 0 ;salta la instruccion si esta en 1 porque es pullup
	call debounce
	btfss PORTA, 1    ;esto replica lo mismo del anterior pero para el otro push
	call anti_dec
	btfss PORTA, 2	    ;push tres que incrementa contador 2
	call debounce_2
	btfss PORTA, 3	    ;push cuatro que decrementa contador 2 
	call anti_dec_2   
	btfss PORTA, 4	    ;este es el push de la suma
	call debounce_suma
	goto loop

;--------------------------sub-rutinas------------------------------------------
	
   ;antirrebotes para incremento push1 y push3 respectivamente
    debounce:
	call delay_big      ;esto hace que espere para que se estabilice el ruido
	btfss PORTA, 0	    ;verificar el pin RA0
	goto $-1	    ;se queda evaluando si esta en 1 no avanza hasta que cambia a 0
	incf  PORTB, 1	    ;guarda el resultado en el registro PORTB
	btfsc PORTB, 4
	clrf  PORTB
	return
	
    debounce_2:
	call delay_big      ;esto hace que espere para que se estabilice el ruido
	btfss PORTA, 2	    ;
	goto $-1	    ;se queda evaluando si esta en 1 no avanza hasta que cambia a 0
	incf  PORTC, 1
	return
	
    ;antirrebotes para decrementos para push2 y push4 respectivamente
    anti_dec:
	call delay_big
	btfss PORTA, 1
	goto $-1
	decf PORTB, 1	    ;esto replica el antirrebote pero decrementa
	return
	
    anti_dec_2:
	call delay_big
	btfss PORTA, 3
	goto $-1
	decf PORTC, 1	    ;esto replica el antirrebote pero decrementa
	;decfsz PORTC, 1
	return
	
    ;el puerto B tiene el contador 1 y el puerto C el contador 2
    debounce_suma:
	call delay_big
	btfss PORTA, 4
	goto $-1
	movf PORTB, 0	    ;esto hace que mueva el registro a W
	addwf PORTC, 0	    ;suma w que tiene el puerto B y lo guarda en el registro PORTC mismo 
	movwf PORTD	    ;mueve el resultado al puerto D
	return
	
	
    ;---------------delays que eliminan el ruido para los push------------------
    
    delay_big:
	movlw   200		    ;valor inicial del contador
	movwf   cont_big
	call    delay_small	    ;rutina de delay
	decfsz  cont_big, 1	    ;decrementar el contador
	goto    $-2		    ;ejecutar dos lineas atras
	return
	
    delay_small:
	movlw 249		    ;valor inicial del contador
	movwf cont_small
	decfsz cont_small, 1	    ;decrementar el contador
	goto $-1		    ;ejecutar la linea anterior
	return
	
end