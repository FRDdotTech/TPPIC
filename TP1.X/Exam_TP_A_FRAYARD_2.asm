


;	Programme du tutorial TP FIP2
;	


	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

	
	; custom flag register
    FLAG_REG    equ     0x70 ; reg addr 
    ; defining bit names
    ADC_H       equ     0
    ADC_M       equ     1
    ADC_L       equ     2
    BIT_3_name  equ     3
    BIT_4_name  equ     4
    BIT_5_name  equ     5
    BIT_6_name  equ     6
    BIT_7_name  equ     7

    ADC_VAL     equ     0x71
    ADC_VAL_TMP equ     0x72


	; Start at the reset vector
	org	0x000
	nop

	; configuration du port B en sortie (4LED)
	banksel TRISB		; port B en sortie
	clrf	TRISB		
	banksel PORTB		;Clear PORTC
	clrf	PORTB		
	
	; configuration de l'ADC
	banksel ADCON1
	movlw	B'00001110'	;Left justify,1 analog channel
	movwf	ADCON1		;VDD and VSS references
	banksel ADCON0	
	movlw	B'01000001'	;Fosc/8, A/D enabled
	movwf	ADCON0


start	
	bsf 	ADCON0,GO	; demarrage de la conversion
non	
	BTFSC	ADCON0,GO			; attendre la fin de conversion
	goto	non
oui	
	movfw   ADRESH
        movwf	ADC_VAL		; ecriture sur le port B (affichage sur les LEDs
        movwf   ADC_VAL_TMP
	call update_flag


update_flag:
    MOVLW	d'200'
	SUBWF	ADC_VAL_TMP
	BTFSC	STATUS, C
    goto    led_h
    MOVLW	d'100'
	SUBWF	ADC_VAL_TMP
	BTFSC	STATUS, C
    goto    led_m
    MOVLW	d'50'
	SUBWF	ADC_VAL_TMP
	BTFSC	STATUS, C
    goto    led_l


led_h:
    BCF     FLAG_REG, ADC_L
    BCF     FLAG_REG, ADC_M
    BSF     FLAG_REG, ADC_H
    MOVLW   b'00001000'
    MOVWF   PORTB
    goto start

led_m:
    BCF     FLAG_REG, ADC_L
    BSF     FLAG_REG, ADC_M
    BCF     FLAG_REG, ADC_H
    MOVLW   b'00000110'
    MOVWF   PORTB
    goto start

led_l:
    BSF     FLAG_REG, ADC_L
    BCF     FLAG_REG, ADC_M
    BCF     FLAG_REG, ADC_H
    MOVLW   b'00000001'
    MOVWF   PORTB
    goto start



end