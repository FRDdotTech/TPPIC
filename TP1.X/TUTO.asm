;	Programme du tutorial TP FIP2
;	


	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

	
	


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


start	bsf 	ADCON0,GO	; demarrage de la conversion
non		mov	ADCON0,GO	; attendre la fin de conversion
		goto	non
oui		swapf	ADRESH,W	; quel est le role de cette instruction ???
		movwf	PORTB		; ecriture sur le port B (affichage sur les LEDs
		goto start			; boucler sur la procedure de lecture

		end					; du programme (directive d'assemblage)
