	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON


        16B_REG_H   equ 0x70
        16B_REG_L   equ 0x71
        


        MOVLW 0x03
        MOVWF 0x72
loop    BCF  STATUS,C
        RLF  16B_REG_L, 1
        RLF  16B_REG_H, 0
        DECFSZ 0x72,F
        GOTO loop


end