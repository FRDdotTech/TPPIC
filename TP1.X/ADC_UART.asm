;	Programme du tutorial TP FIP2
;	


	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

 
 
    org 0x0 ; reset addr
	GOTO jump_start
	
irq org	0x004
    ; context save
	banksel STATUS
	MOVWF   ctx_w
	MOVFW   STATUS
	MOVWF   ctx_status
	; set uart_tx flag
	btfss	PIR1, TMR1IF
	BCF	UART_TX_EN, 0
false	BSF	UART_TX_EN, 0
	; restore context
	MOVFW   ctx_status
	MOVWF   STATUS
	MOVFW   ctx_w
	BCF	PIR1, TMR1IF
	RETFIE
    
    
	org	0x100
	
jump_start	
	BCD1		equ 0x71
	BCD01		equ 0x72
	BCD_TEMP	equ 0x74
	
	ADC_CON		equ 0x75
	ADC_TEMP	equ 0x76
    
	UART_TX_EN	equ 0x78
    
	ctx_w		equ 0x20
	ctx_status	equ 0x21
		; configuration du port B&D en sortie (8LED)

	banksel TRISB		; port B en sortie
	CLRF	TRISB		
	banksel PORTB		;Clear PORTC
	CLRF	PORTB	
	
	banksel TRISD		; port B en sortie
	CLRF	TRISD		
	banksel PORTD		;Clear PORTC
	CLRF	PORTD
	
	; configuration de l'ADC
	
	banksel ADCON1
	MOVLW	B'00001110'	;Left justify,1 analog channel
	MOVWF	ADCON1		;VDD and VSS references

	banksel ADCON0	
	MOVLW	B'01000001'	;Fosc/8, A/D enabled
	MOVWF	ADCON0
	
	; USART CONFIG
	
	;---CONFIGURE TXSTA
	;
	;7- CSRC	0
	;6- TX9		0
	;5- TXEN	1
	;4- SYNC	0
	;3- NOT USED	0
	;2- BRGH	1
	;1- TRMT	0
	;0- TX9D	0
	banksel TXSTA
	MOVLW	B'00100100' 
	MOVWF	TXSTA

	;---CONFIGURE RCSTA
	;
	;7- SPEN	1
	;6- RX9		0
	;5- SREN	0
	;4- CREN	0
	;3- ADDEN	0
	;2- FERR	0
	;1- OERR	0
	;1- RX9D	0
	banksel RCSTA
	MOVLW	B'10000000' ;ENABLE SERIAL PORT
	MOVWF	RCSTA ;RECEIVE STATUS REG
	
	;---CONFIGURE SPBRG FOR DESIRED BAUD RATE
	banksel SPBRG
	MOVLW	D'50' ;WE WILL USE 9600bps 
	MOVWF	SPBRG ;BAUD AT 8MHZ
	
	; TIMER1 SETUP
	banksel T1CON
	MOVLW	B'00111101'
	MOVWF	T1CON
	
	;TIMER1 IT SETUP
	banksel INTCON
	MOVLW	B'11000000'
	MOVWF	INTCON
	
	banksel PIE1
	MOVLW	B'00000001'
	MOVWF	PIE1
	
	
	
	; ---main()
loop	
		CALL	ADC
		CALL	BCD
		CALL	UART_TX_IT
		GOTO	loop
	
ADC:	    ; wait unitil ADC convertion is done 
		CLRF    BCD01
		CLRF    BCD1
		CLRF	BCD_TEMP
		CLRF	ADC_TEMP
		banksel ADCON0
start	
		BSF 	ADCON0,GO	; start ADC conv
non		
		BTFSC	ADCON0,GO	; while CONV NOK
		GOTO	non
oui		
		MOVFW 	ADRESH
		MOVWF	ADC_CON
		MOVWF	PORTD   
		SWAPF	ADRESH,W
		MOVWF	PORTB		; MSB on PORTB LSB
		RETURN
	
    
DELAY:			;PAS Utilis�
	MOVLW	0xFF
	MOVWF	TMR1
	
D1	
	MOVLW	0x0F
	MOVWF	TMR0
	
D0	
	DECFSZ	TMR0
	GOTO	D0
	
	DECFSZ	TMR1
	GOTO	D1	
	
	RETURN
	
	
UART_TX_IT:
	BTFSS	UART_TX_EN, 0
	RETURN
	BCF		UART_TX_EN, 0
	banksel TXREG
	MOVFW	BCD1
	CALL	UART_TX
	MOVLW	d'44'
	CALL	UART_TX
	MOVFW	BCD01
	CALL	UART_TX
	MOVLW	d'86'
	CALL	UART_TX
	MOVLW	d'10'
	CALL	UART_TX
	RETURN
	
UART_TX:	; wait for transmit standby
wait	
	nop
	banksel PIR1
	BTFSS	PIR1, TXIF
	GOTO 	wait
	MOVWF	TXREG
	;CALL	DELAY
	RETURN
	
BCD:
	nop		;unit� BCD
	MOVFW	ADC_CON
	MOVWF	ADC_TEMP
ret
	MOVLW	d'5'
	SUBWF	ADC_TEMP
	BTFSC	STATUS, C
	GOTO	dec_pp
	MOVFW	BCD1
	ADDLW	d'48'
	MOVWF	BCD1
	
	MOVFW	BCD01
	ADDLW	d'48'
	MOVWF	BCD01
	RETURN
	

unit_pp	
	INCF    BCD1
	CLRF    BCD01
	
    

dec_pp	
	INCF    BCD01
	MOVFW	BCD01
	MOVWF	BCD_TEMP
	MOVLW	D'10'
	SUBWF	BCD_TEMP
	BTFSC	STATUS, Z
	GOTO	unit_pp
	GOTO	ret
	

end


