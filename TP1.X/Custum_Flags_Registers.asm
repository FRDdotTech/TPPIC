

	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON


    ; custom flag register
    FLAG_REG    equ     0x70 ; reg addr 
    ; defining bit names
    BIT_0_name  equ     0
    BIT_1_name  equ     1
    BIT_2_name  equ     2
    BIT_3_name  equ     3
    BIT_4_name  equ     4
    BIT_5_name  equ     5
    BIT_6_name  equ     6
    BIT_7_name  equ     7


end