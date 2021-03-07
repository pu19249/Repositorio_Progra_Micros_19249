; Archivo: main_04.s
; Dispositivo: PIC16F887
; Autor: Jonathan Pu
; Compilador: pic-as (v2.30), MPLABX V5.45
; Programa: contador de 8 leds y display con int de B y 5 7seg con int de Tmr0
; Hardware: 2 pb en puerto b, 8 leds en portA, 7seg en puerto C y D
; Creado: 03 marzo, 2021
; Ultima modificacion: 06 marzo, 2021
    
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
	 
//<editor-fold defaultstate="collapsed" desc="variables">
    PSECT udata_shr ;Common memory
display_seven:	DS 2 ;variable para incrementar display
W_TEMP:		DS 1 ;variable para int y que guarde W
STATUS_TEMP:	DS 1 ;variable para int y que guarde STATUS
dos7seg:	DS 2 ;variable para separar displays
transistores:	DS 1 ;pines para los transistores de los display
dos7seg_disp:	DS 2 ;la variable que ya me lo muestra en el display
    
    PSECT udata_bank0	;variables en banco 0
tres7seg:		DS 3 ;variables para separar 3 displays
decenas:		DS 1 ;
centenas:		DS 1 ;
unidades:		DS 1 ;
dividendo:		DS 1 ;
    
//</editor-fold>

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
//<editor-fold defaultstate="collapsed" desc="PUSH-ISR-POP">
push:
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP
    
isr:
    BANKSEL PORTB
    BTFSC   RBIF	    ;revisa si hubo interrupcion en el puerto B
    CALL    int_contador    ;subrutina para inc y dec
    BTFSC   T0IF	    ;revisa si hubo overflow en el timer0
    CALL    int_tmr0	    ;subrutina timer0

pop:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE		    ;stack is poped in the PC
	
	//</editor-fold>

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Configuracion de pines
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
	
//<editor-fold defaultstate="collapsed" desc="tabla 7segmentos">
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
    //</editor-fold>

//<editor-fold defaultstate="collapsed" desc="configuracion del main">
main:
    ;Configurar pines del puerto A como salida
    BANKSEL TRISA
    CLRF    TRISA
    ;Configurar pines del puerto C y D como salidas para los displays
    CLRF    TRISC
    CLRF    TRISD
    ;Configuracion de dos pines como entradas
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH
    BSF	    TRISB, 0
    BSF	    TRISB, 1
    ;Configuracion de los pines para los transistores
   
    BCF	    TRISB, 6
    BCF	    TRISB, 7
    BANKSEL TRISE
    BCF	    TRISE, 0
    BCF	    TRISE, 1
    BCF	    TRISE, 2
  
    
    ;Usar los pull ups internos para estos pines
    BANKSEL OPTION_REG		
    BCF	    OPTION_REG, 7   ;PORTB pull-ups are enabled by individual PORT latch values
    BANKSEL WPUB
    MOVLW   00000011B	    ;hay que configurar todos de manera individual
    MOVWF   WPUB
    
      ;configurar timer0
    BANKSEL OPTION_REG
    BCF	    T0CS	    ;oscilador interno
    BCF	    PSA		    ;prescaler asignado al timer0
    BSF	    PS0		    ;prescaler tenga un valor 1:256
    BSF	    PS1
    BSF	    PS2
   
    
    ;Configurar el reloj interno
    BANKSEL OSCCON
    BCF	    IRCF0	    ;el reloj interno 250kHz
    BSF	    IRCF1
    BCF	    IRCF2
    BSF	    SCS		    ;internal oscillator is used for system clock
    ;configurar interrupcion del puerto B
    BANKSEL IOCB
    MOVLW   00000011B	    ;habilita el interrupt on change para los pines RB0 y RB1
    MOVWF   IOCB    
    BANKSEL INTCON	
    BCF	    RBIF	    ;no hay ningun cambio de estado aun - como limpiar puertos
    
 
    ;configurar bits para interrupciones en general
    BSF	    GIE		    ;habilita las interrupciones globales
    BSF	    RBIE	    ;habilita la interrupcion del puertoB
    BSF	    T0IE	    ;habilita la interrupcion del timer0
    BCF	    T0IF	    ;limpiar puerto para el timer0
    
    ;limpiar todos los puertos
    BANKSEL PORTA   
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    //</editor-fold>

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Loop principal
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
    
//<editor-fold defaultstate="collapsed" desc="main loop">
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Loop principal
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
loop:
    BANKSEL	PORTA
    CALL	multiplexar
    CALL	separar_displays
    BANKSEL	PORTA		;mis proximas operaciones son de variables en el banco0
    CALL	division_centenas
    GOTO	loop
	//</editor-fold>

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Subrutinas
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

;subrutina de division que guarda en 3 variables en formato decimal, el valor del contador
//<editor-fold defaultstate="collapsed" desc="rutina de division">
division_centenas:
    CLRF	centenas	    ;para asegurar que se inicia en cero el proceso
    MOVF	PORTA, 0
    MOVWF	dividendo	    ;con esto hare las operaciones
    MOVLW	100		    ;le resto una vez 100
    SUBWF	dividendo, 0	    ;lo guardo en W
    BTFSC	STATUS, 0	    ;Skip if clear, porque cuando haya un resultado valido se activara
    INCF	centenas	    ;cuantas centenas caben en el numero
    BTFSC	STATUS, 0	    ;
    MOVWF	dividendo	    ;el resultado de la resta estaba en W ahora en dividendo
    BTFSC	STATUS, 0	    ;un tercer BTFSC para ver hasta cuando repito la operacion
				    ;o si sigue a decenas
    GOTO	$-7		    ;se repite si cabe otra centena
    CALL	division_decenas
    RETURN 
    
division_decenas:
    CLRF	decenas	            ;para asgurar que se inicia en cero el proceso
    ;MOVF	PORTA, 0	    ;esto no porque llama el numero completo
    ;MOVWF	dividendo	    ;con esto hare las operaciones
    MOVLW	10		    ;le resto una vez 100
    SUBWF	dividendo, 0	    ;lo guardo en W
    BTFSC	STATUS, 0	    ;Skip if clear, porque cuando haya un resultado valido se activara
    INCF	decenas		    ;cuantas centenas caben en el numero
    BTFSC	STATUS, 0	    ;
    MOVWF	dividendo	    ;el resultado de la resta estaba en W ahora en dividendo
    BTFSC	STATUS, 0	    ;un tercer BTFSC para ver hasta cuando repito la operacion o si sigue a decenas
    GOTO	$-7		    ;se repite si cabe otra centena
    CALL	division_unidades
    RETURN
division_unidades:
    CLRF	unidades	    ;para asgurar que se inicia en cero el proceso
    ;MOVF	PORTA, 0	    ;esto no porque llama otra vez el numero completo
    ;MOVWF	dividendo	    ;con esto hare las operaciones
    MOVLW	1		    ;le resto una vez 100
    SUBWF	dividendo, F	    ;lo guardo en W
    BTFSC	STATUS, 0	    ;Skip if clear, porque cuando haya un resultado valido se activara
    INCF	unidades	    ;cuantas centenas caben en el numero
    BTFSS	STATUS, 0	    ;es cuando ya se completo el numero     
    RETURN
    GOTO	$-6		    ;se repite si cabe otra centena
    
 //</editor-fold>

int_contador:
    BTFSS   PORTB, 0
    INCF    PORTA
    BTFSS   PORTB, 1
    DECF    PORTA
    BCF	    RBIF		;limpia el pin porque cambio de estado en la subrutina
    RETURN

reiniciar:
    MOVLW	254     ;para los 10ms con el clock 250kHz
    MOVWF	TMR0	;mover este valor inicial al timer0
    BCF		T0IF	;
    RETURN
    
//<editor-fold defaultstate="collapsed" desc="multiplexar y preparar displays">
    multiplexar:				    ;rutina para multiplexar los display
    MOVF	PORTA, 0
    ANDLW	00001111B	
    MOVWF	dos7seg		;guardo lo que tengo en mi resultado del AND a W
    SWAPF	PORTA, 0	;lo vuelvo a guardar en W
    ANDLW	00001111B		;
    MOVWF	dos7seg+1	;esto permite que tome la parte alta de mi registro de 2bytes
    RETURN

separar_displays:
    MOVF	dos7seg, 0
    CALL	tabla_disp
    MOVWF	dos7seg_disp
    MOVF	dos7seg+1, 0
    CALL	tabla_disp
    MOVWF	dos7seg_disp+1
    ;traduccion para los otros tres displays
    ;BANKSEL	PORTA
    MOVF	centenas, 0
    CALL	tabla_disp
    MOVWF	tres7seg
    MOVF	decenas, 0
    CALL	tabla_disp
    MOVWF	tres7seg+1
    MOVF	unidades, 0
    CALL	tabla_disp
    MOVWF	tres7seg+2
    RETURN//</editor-fold>

    
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;			Rutinas de interrupcion
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
    
//<editor-fold defaultstate="collapsed" desc="desplegar valores en 7segmentos">
int_tmr0:
    CALL	reiniciar
    BCF		PORTB, 6	 ;para que inicien limpios los transistores
    BCF		PORTB, 7
    BCF		PORTE, 0
    BCF		PORTE, 1
    BCF		PORTE, 2	 ;limpiar transistores en puerto E
    
    BTFSC	transistores, 0  ;esto hace que si se salta esta linea va al display2
    GOTO	display2	 ;de lo contrario va al display1 porque sigue en las lineas de codigo
    
    BTFSC	transistores, 1 ;   
    GOTO	display2_1
    
    BTFSC	transistores, 2
    GOTO	display2_2
    
    BTFSC	transistores, 3
    GOTO	display2_3
    
display1:
    MOVF	dos7seg_disp, 0   ;este display no requiere de bandera de transistor
    MOVWF	PORTC		  ;
    BSF		PORTB, 6	    
    GOTO	otrodisp

display2:
    MOVF	dos7seg_disp+1, 0
    MOVWF	PORTC
    BSF		PORTB, 7
    GOTO	otrodisp1
    
display2_1:
    MOVF	tres7seg, 0
    MOVWF	PORTD
    BSF		PORTE, 0
    GOTO	otrodisp2
display2_2:
    MOVF	tres7seg+1, 0
    MOVWF	PORTD
    BSF		PORTE, 1
    GOTO	otrodisp3
display2_3:
    MOVF	tres7seg+2, 0
    MOVWF	PORTD
    BSF		PORTE, 2
    GOTO	otrodisp4	
;como tengo 8 bits el xor me hace que se vayan encendiendo los transistores en orden
otrodisp:
    MOVLW	00000001B
    XORWF	transistores, 1
    RETURN
otrodisp1:
    MOVLW	00000011B
    XORWF	transistores, 1
    RETURN
otrodisp2:
    MOVLW	00000110B
    XORWF	transistores, 1
    RETURN
otrodisp3:
    MOVLW	00001100B
    XORWF	transistores, 1
    RETURN
otrodisp4:
    CLRF	transistores		;esto hace que se muestre el primer display
    RETURN//</editor-fold>
   
END