;	Programme du tutorial TP FIP2
;	


	list p=16f877
include "p16f877.inc"
	
; CONFIG
; __config 0xFF39
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_ON

 
 
    org 0x0 ; reset addr
	goto jump_start
	
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
	movfw	UART_TX_EN
	addlw	d'1'
	btfss	UART_MODE, 0	; if mode if pulling don't set tx_enable
	movwf	UART_TX_EN
	BCF	PIR1, TMR1IF
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
    
	ctx_w		equ 0x20
	ctx_status	equ 0x21
		; configuration du port B&D en sortie (8LED)

	banksel TRISB		; port B en sortie
	clrf	TRISB		
	banksel PORTB		;Clear PORTC
	clrf	PORTB	
	
	banksel TRISD		; port B en sortie
	clrf	TRISD		
	banksel PORTD		;Clear PORTC
	clrf	PORTD
	
	; configuration de l'ADC
	
	banksel ADCON1
	movlw	B'00001110'	;Left justify,1 analog channel
	movwf	ADCON1		;VDD and VSS references

	banksel ADCON0	
	movlw	B'01000001'	;Fosc/8, A/D enabled
	movwf	ADCON0
	
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
	;4- CREN	1
	;3- ADDEN	0
	;2- FERR	0
	;1- OERR	0
	;1- RX9D	0
	banksel RCSTA
	MOVLW	B'10010000' ;ENABLE SERIAL PORT
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
	MOVLW	B'00100001'
	MOVWF	PIE1
	
	movlw	d'0'
	movwf	UART_RX_TMP
	
	movlw	d'0'
	movwf	UART_TX_EN_TMP
	
	movlw	d'0'
	movwf	UART_TX_EN
	
	
	
	
	; ---main()
loop	call	ADC
	call	BCD
	call	ACK_RX
	call	UART_TX_IT
	goto	loop
	
ADC:	    ; wait unitil ADC convertion is done 
		clrf    BCD01
		clrf    BCD1
		clrf	BCD_TEMP
		clrf	ADC_TEMP
		banksel ADCON0
start   
        BSF     ADCON0,GO   ; start ADC conv
non     
        BTFSC   ADCON0,GO   ; while CONV NOK
        GOTO    non
oui     
        MOVFW   ADRESH
        MOVWF   ADC_CON
        MOVWF   PORTD   
        SWAPF   ADRESH,W
        MOVWF   PORTB       ; MSB on PORTB LSB
        RETURN

	
    
DELAY:			;PAS Utilis�
	MOVLW	0xFF
	MOVWF	TMR1
	
D1	MOVLW	0x0F
	MOVWF	TMR0
	
D0	DECFSZ	TMR0
	goto	D0
	
	DECFSZ	TMR1
	goto	D1	
	
	return

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
	BCF	UART_MODE, 0

	
T_PULL:
	movfw	UART_RX_BUF
	movwf	UART_RX_TMP
	movlw	d'82'
	subwf	UART_RX_TMP
	btfss	STATUS, Z
	return
	BSF	UART_MODE, 0
	BSF	UART_TX_EN, 0

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
	movfw	UART_TX_EN
	movwf	UART_TX_EN_TMP
	movlw	'3'
	subwf	UART_TX_EN_TMP
	BTFSS	STATUS, Z
	return
	BCF	UART_TX_EN, 0
	
	banksel TXREG
	movfw	BCD1
	call	UART_TX
	movlw	d'44'
	call	UART_TX
	movfw	BCD01
	call	UART_TX
	movlw	d'86'
	call	UART_TX
	movlw	d'10'
	call	UART_TX
	return
	
UART_TX:	; wait for transmit standby
wait	nop
	banksel PIR1
	BTFSS	PIR1, TXIF
	goto wait
	MOVWF	TXREG
	;call	DELAY
	return
	
BCD:
	nop
	MOVFW	ADC_CON
	MOVWF	ADC_TEMP
ret
	movlw	d'5'
	subwf	ADC_TEMP
	btfsc	STATUS, C
	goto	dec_pp
	movfw	BCD1
	addlw	d'48'
	movwf	BCD1
	
	movfw	BCD01
	addlw	d'48'
	movwf	BCD01
	return
	

unit_pp	incf    BCD1
	clrf    BCD01
	
    

dec_pp	incf    BCD01
	movfw	BCD01
	movwf	BCD_TEMP
	movlw	D'10'
	subwf	BCD_TEMP
	btfsc	STATUS, Z
	goto	unit_pp
	goto	ret
	

end


