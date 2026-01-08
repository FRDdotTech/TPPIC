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

        ; start with RC0 high (0000 0001)
        MOVLW   b'00000001'
        MOVWF   PATTERN_REG

        ; choose a default direction (example: left)
        BSF     FLAG_REG, DIR_FLAG

; ---------------- Main loop ----------------
running_ligh:
        ; output the pattern
        MOVFW   PATTERN_REG
	MOVWF	PORTD   
	SWAPF	PATTERN_REG,W
	MOVWF	PORTB		; MSB on PORTB LSB

        CALL    delay
	CALL	delay

        ; decide direction based on flag bit
        BTFSC   FLAG_REG, DIR_FLAG ; skip next if bit = 0
        GOTO    rot_left

; ---- rotate right (one-hot with wrap) ----
rot_right:
        BCF     STATUS, C
        RRF     PATTERN_REG, F      ; rotate through carry (carry was 0) [web:9]

        ; if pattern became 0, wrap to bit7
        MOVF    PATTERN_REG, W
        BTFSS   STATUS, Z
        GOTO    running_ligh
        MOVLW   b'10000000'
        MOVWF   PATTERN_REG
        GOTO    running_ligh

; ---- rotate left (one-hot with wrap) ----
rot_left:
        BCF     STATUS, C
        RLF     PATTERN_REG, F      ; rotate through carry (carry was 0) [web:9]

        ; if pattern became 0, wrap to bit0
        MOVF    PATTERN_REG, W
        BTFSS   STATUS, Z
        GOTO    running_ligh
        MOVLW   b'00000001'
        MOVWF   PATTERN_REG
        GOTO    running_ligh

; ---------------- Simple delay ----------------
delay:
        MOVLW   256
        MOVWF   DELAY_H
dly1:   MOVLW   256
        MOVWF   DELAY_L
dly2:   DECFSZ  DELAY_L, F
        GOTO    dly2
        DECFSZ  DELAY_H, F
        GOTO    dly1
        RETURN


	
	
end
