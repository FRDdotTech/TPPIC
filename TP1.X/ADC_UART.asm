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
	btfsc	PIR1, TMR1IF	;test TIMER1 interrupt
	goto t1_it
	btfsc	PIR1, RCIF	; test UART_RX Interrupt
	goto rx_it
	goto leave
	
t1_it	
	btfss	UART_MODE, 0	; if mode if pulling don't set tx_enable
	goto	en_tmr
	decf	TMR_CNT,
	btfss	STATUS, Z
	goto	en_tmr
	bsf	UART_TX_EN, 0
	movlw	d'30'
	movwf	TMR_CNT
	
en_tmr	BCF	PIR1, TMR1IF
	goto leave
	
rx_it	
	movfw	RCREG
	movwf	UART_RX_BUF
	BSF	UART_RX_EN, 0
	goto leave
	
leave	; restore context
	MOVFW   ctx_status
	MOVWF   STATUS
	MOVFW   ctx_w
	RETFIE
    
    
	org	0x100
	
jump_start	
	BCD1		equ 0x71
	BCD01		equ 0x72
	BCD_TEMP	equ 0x74
	
	ADC_CON		equ 0x75
	ADC_TEMP	equ 0x76
    
	UART_TX_EN	equ 0x78
	UART_RX_EN	equ 0x79
	UART_MODE	equ 0x7A    ; 0 -> interupt; 1 -> pulling
	UART_RX_BUF	equ 0x73
	UART_RX_TMP	equ 0x7B
	UART_TX_EN_TMP	equ 0x7C
	
	TMR_CNT		equ 0x7D
    
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
	;7- CSRC		0
	;6- TX9			0
	;5- TXEN		1
	;4- SYNC		0
	;3- NOT USED	0
	;2- BRGH		1
	;1- TRMT		0
	;0- TX9D		0
	banksel TXSTA
	MOVLW	B'00100100' 
	MOVWF	TXSTA

	;---CONFIGURE RCSTA
	;
	;7- SPEN	1
	;6- RX9		0
	;5- SREN	0
	;4- CREN	1
	;3- ADDEN	0
	;2- FERR	0
	;1- OERR	0
	;0- RX9D	0
	banksel RCSTA
	MOVLW	B'10010000' ;ENABLE SERIAL PORT
	MOVWF	RCSTA ;RECEIVE STATUS REG
	
	;---CONFIGURE SPBRG FOR DESIRED BAUD RATE
	banksel SPBRG
	MOVLW	D'50' ;WE WILL USE 9600bps 
	MOVWF	SPBRG ;BAUD AT 8MHZ


	; TIMER1 SETUP
	;
	;7- NOT USED	0
	;6- NOT USED	0
	;5- T1CKPS1		1
	;4- T1CKPS1		1
	;3- T1OSCEN		1
	;2- T1SYNC		1
	;1- TMR1CS		0
	;0- TMR1ON		1
	banksel T1CON
	MOVLW	B'00111101'
	MOVWF	T1CON
	
	; ITERRUPT SETUP
	;
	;7- GIE			1
	;6- PIE			1
	;5- T0IE		0
	;4- INTE		0
	;3- RBIE		0
	;2- T0IF		0
	;1- INTF		0
	;0- RBIF		0
	banksel INTCON
	MOVLW	B'11000000'
	MOVWF	INTCON
	
	; PERIPHERAL ITERRUPT SETUP
	;
	;7- PSPIE		0
	;6- ADIE		0
	;5- RCIE		1
	;4- TXIE		0
	;3- SSPIE		0
	;2- CCP1IE		0
	;1- TMR2IE		0
	;0- TMR1IE		1
	banksel PIE1
	MOVLW	B'00100001'
	MOVWF	PIE1
	
	
	clrf	UART_RX_TMP
	
	clrf	UART_TX_EN_TMP
	
	clrf	UART_TX_EN
	
	movlw	d'3'
	movwf	TMR_CNT
	
	
	
	
	; ---main()
loop	
		CALL	ADC
		CALL	BCD
		CALL	ACK_RX
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
	
    
DELAY:			;not used
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




ACK_RX:
	btfss	UART_RX_EN, 0
	return
	movfw	UART_RX_BUF
	movwf	UART_RX_TMP
	call	UART_TX
	movlw	d'10'
	call	UART_TX
	bcf	UART_RX_EN, 0
	call	T_AUTO
	call	T_PULL
	call	T_REQ
	return

	


T_AUTO:
	movlw	d'65'
	subwf	UART_RX_TMP
	btfss	STATUS, Z
	return
	BCF		UART_MODE, 0

	
T_PULL:
	movfw	UART_RX_BUF
	movwf	UART_RX_TMP
	movlw	d'82'
	subwf	UART_RX_TMP
	btfss	STATUS, Z
	return
	BSF		UART_MODE, 0
	BSF		UART_TX_EN, 0

T_REQ:
	btfss	UART_MODE,0
	    return
	movfw	UART_RX_BUF
	movwf	UART_RX_TMP
	movlw	d'100'
	subwf	UART_RX_TMP
	btfss	STATUS, Z
	return
	BSF	UART_TX_EN, 0

UART_TX_IT:
    
	BTFSC	UART_TX_EN, 0
	return
	BCF	UART_TX_EN, 0
	
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
	
UART_TX:	
wait	
	nop
	banksel PIR1
	BTFSS	PIR1, TXIF	; while transmit busy
	GOTO 	wait
	MOVWF	TXREG
	;CALL	DELAY
	RETURN
	
BCD:
	nop
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
	DECF    BCD01
	
    

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


