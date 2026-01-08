	list p=16f877
include "p16f877.inc"

;
; blink an LED using blocking delay
;


; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

; ---------------- RAM ----------------
; registers 

; custom flag register
    FLAG_REG    equ     0x70 ; reg addr 
    ; defining bit names
    DELAY_RDY   equ     0
    BIT_1_name  equ     1
    BIT_2_name  equ     2
    BIT_3_name  equ     3
    BIT_4_name  equ     4
    BIT_5_name  equ     5
    BIT_6_name  equ     6
    BIT_7_name  equ     7
        

    DELAY_CNT equ     0x7F ; use to make iterration to acheive the desired delay time




; ---------------- Reset vector ----------------
        ORG     0x0000
        GOTO    init

; ---------------- Init ----------------
init:

        ; only use 1 led
        BANKSEL TRISB
        MOVLW	B'11111110'	
	MOVWF	TRISB
	
        BANKSEL PORTB
        CLRF    PORTB

        ; TIMER1 SETUP
	;
	;7- NOT USED	0
	;6- NOT USED	0
	;5- T1CKPS1		1
	;4- T1CKPS1		1
	;3- T1OSCEN		1
	;2- T1SYNC		1
	;1- TMR1CS		0
	;0- TMR1ON		0
	banksel T1CON
	MOVLW	B'00111101'
	MOVWF	T1CON


; ---------------- Main loop ----------------
blinky:
        ; output the pattern

        BSF     PORTB, 0
        CALL    delay
        BCF     PORTB, 0
        CALL    delay

        ; 
        GOTO    blinky


; ---------------- Simple delay ----------------
delay:
        clrf    TMR1L
        CLRF    TMR1H
        BSF     T1CON, TMR1ON
        BTFSS   PIR1, TMR1IF
        goto    delay
        BSF     T1CON, TMR1ON
        DECFSZ  DELAY_CNT
        goto    delay
        BCF     T1CON, TMR1ON
        RETURN
	
end



