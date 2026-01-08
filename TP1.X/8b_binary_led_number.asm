	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

; ---------------- RAM ----------------
; registers 

; custom flag register
    FLAG_REG    equ     0x70 ; reg addr 
    ; defining bit names
    DIR_FLAG    equ     0
    BIT_1_name  equ     1
    BIT_2_name  equ     2
    BIT_3_name  equ     3
    BIT_4_name  equ     4
    BIT_5_name  equ     5
    BIT_6_name  equ     6
    BIT_7_name  equ     7


    PATTERN_REG equ     0x71 ; current one-hot output pattern (to prevent using the PORT dirreclty)         

    DELAY_L equ	    0x7D
    DELAY_M equ     0x7E
    DELAY_H equ     0x7F




; ---------------- Reset vector ----------------
        ORG     0x0000
        GOTO    init

; ---------------- Init ----------------
init:
        BANKSEL TRISB
        MOVLW	B'11110000'	
	MOVWF	TRISB
	MOVWF	TRISD
	
        BANKSEL PORTB
        CLRF    PORTB
	CLRF    PORTD

        ; input the value to be written in 8bit format 
	; in PATTERN_REG
        MOVLW   d'112'
        MOVWF   PATTERN_REG


; ---------------- Main loop ----------------
binary_led:
        ; output the pattern
        MOVFW   PATTERN_REG
	MOVWF	PORTD   
	SWAPF	PATTERN_REG,W
	MOVWF	PORTB		; MSB on PORTB LSB

        CALL    delay
	CALL	delay

        ; decide direction based on flag bit
        GOTO    binary_led


; ---------------- Simple delay ----------------
delay:
        MOVLW   0xFF
        MOVWF   DELAY_H
dly1:   MOVLW   0xFF
        MOVWF   DELAY_L
dly2:   DECFSZ  DELAY_L, F
        GOTO    dly2
        DECFSZ  DELAY_H, F
        GOTO    dly1
        RETURN
	
end



