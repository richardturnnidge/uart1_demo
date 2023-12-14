;	UART1 input demo
; 	Richard Turnnidge 2023

; 	Reads a command byte, then a hex pair gets turned into a data byte
;	Example, 82 (ascii 'R') could be 'right potentiometer', with hex value B5 (181) for the data byte
;	'uart1_command' contains the command byte
;	'uart1_data' contains the un-hexed data byte 
;	All command bytes need to be above 70 for simplicty of decoding in this version

; ---------------------------------------------
;
;	MACROS
;
; ---------------------------------------------

	macro MOSCALL afunc
	ld a, afunc
	rst.lil $08
	endmacro

; ---------------------------------------------
;
;	INITIALISE
;
; ---------------------------------------------

	.assume adl=1						; big memory mode
	.org $40000						; load code here

	jp start_here						; jump to start of code

	.align 64						; MOS header
	.db "MOS",0,1

; ---------------------------------------------
;
;	INITIAL SETUP CODE HERE
;
; ---------------------------------------------

start_here:
								; store everything as good practice	
	push af							; pop back when we return from code later
	push bc
	push de
	push ix
	push iy


	call CLS 						; clear screen
	call openUART1						; init the UART1 serial port
	call hidecursor						; hide the cursor

	ld hl, text_data
	ld bc, end_text_data - text_data
	rst.lil $18						; print default text to screen

; ---------------------------------------------
;
;	MAIN LOOP
;
; ---------------------------------------------

MAIN_LOOP:	
	MOSCALL $08						; get IX pointer to sysvars
	ld a, (ix + 05h)					; ix+5h is 'last key pressed'
	cp 27							; is it ESC key?
	jp z, exit_here						; if so exit cleanly

	call uart1_handler					; get any new data from UART1

	ld a, (uart1_received)					; check if we got anything
	cp 0
	jr z, MAIN_LOOP						; nothing new, loop round again

								; got some new data
	ld a, (uart1_command)					; grab latest command				
	ld b, 9
	ld c, 2
	call display_A						; display it

	ld a, (uart1_data)					; grab latest command				
	ld b, 9
	ld c, 4
	call display_A						; display it	

	jp MAIN_LOOP



; ---------------------------------------------
; Adapted from Hexload source

uart1_handler:		
	DI
	PUSH	AF
	IN0	A,(REG_LSR)				; Get the line status register
	AND	UART_LSR_RDY				; Check for characters in buffer
	JR	Z, noData 				; Nothing received
			
	LD	A,1   					; we got new data
	LD	(uart1_received),a 			; so set flag fro new data
	IN0	A,(REG_RBR)				; Read the character from the UART receive buffer
	LD	(uart1_buffer),A  			; store new byte of data
	POP	AF
	EI

	ld a, (uart1_buffer)				; check it is a control code. Exit if not
	cp 70 						; all control codes are higher than 70 for simplicity
							; a hex code will be 48-57 (0-0) or 65-70 (A-F)
	jr c, noData					; was less than 70, therefore dud code and exit

	ld (uart1_command), a 				; store command byte

							; next get two more bytes
	MOSCALL $17 					; wait for a byte
	sub 48 						; turn ascii into int value 0=48

	cp 10						; is A less than 10? (58+)
	jr c, n1					; carry on if less
	sub 7						; add to get 'A' char if larger than 10
n1:							
	ld d, a 					; store first byte value

	MOSCALL $17 					; wait for a byte

	sub 48
	cp 10						; is A less than 10? (58+)
	jr c, n2					; carry on if less
	sub 7						; add to get 'A' char if larger than 10
n2:
	SLA a
	SLA a
	SLA a
	SLA a 						; move to upper nibble
	
	add a, d 					; add the two nibbles
	LD (uart1_data), A 				; store the value for later use
	RET

noData:
	XOR 	A,A
	LD	(uart1_received),A			; note that nothing is available	
	POP	AF
	EI

	RET
			
uart1_buffer:		.db	1			; 64 byte receive buffer
uart1_received:		.db	1			; boolean
uart1_data:		.db	1			; final pot value received
uart1_command: 		.db 	0			; current command received

; ---------------------------------------------
;
;	UART CODE
;
; ---------------------------------------------

openUART1:
	ld ix, UART1_Struct
	MOSCALL $15					; open uart1
	ret 

; ---------------------------------------------

closeUART1:
	MOSCALL $16 					; close uart1
	ret 

; ---------------------------------------------

UART1_Struct:	
	.dl 	9600					; baud (stored as three byte LONG)
	.db 	8 					; data bits
	.db 	1 					; stop bits
	.db 	0 					; parity bits
	.db 	0					; flow control
	.db 	0					; interrupt bits

; ---------------------------------------------
;
;	EXIT CODE CLEANLY
;
; ---------------------------------------------

exit_here:

	call closeUART1
	call CLS
							; reset all values before returning to MOS
	pop iy
	pop ix
	pop de
	pop bc
	pop af
	ld hl,0

	ret						; return to MOS here

; ---------------------------------------------
;
;	OTHER ROUTINES	
;
; ---------------------------------------------

CLS:
	ld a, 12
	rst.lil $10					; CLS
	ret 

; ---------------------------------------------

hidecursor:
	push af
	ld a, 23
	rst.lil $10
	ld a, 1
	rst.lil $10
	ld a,0
	rst.lil $10	;VDU 23,1,0
	pop af
	ret

; ---------------------------------------------
;
;	DEBUG ROUTINES
;
; ---------------------------------------------
	
display_A:					; debug A to screen as HEX byte pair at pos BC
	ld (debug_char), a			; store A
						; first, print 'A=' at TAB 36,0
	ld a, 31				; TAB at x,y
	rst.lil $10
	ld a, b					; x=b
	rst.lil $10
	ld a,c					; y=c
	rst.lil $10				; put tab at BC position

	ld a, (debug_char)			; get A from store, then split into two nibbles
	and 11110000b				; get higher nibble
	rra
	rra
	rra
	rra					; move across to lower nibble
	add a,48				; increase to ascii code range 0-9
	cp 58					; is A less than 10? (58+)
	jr c, nextbd1				; carry on if less
	add a, 7				; add to get 'A' char if larger than 10
nextbd1:	
	rst.lil $10				; print the A char

	ld a, (debug_char)			; get A back again
	and 00001111b				; now just get lower nibble
	add a,48				; increase to ascii code range 0-9
	cp 58					; is A less than 10 (58+)
	jp c, nextbd2				; carry on if less
	add a, 7				; add to get 'A' char if larger than 10	
nextbd2:	
	rst.lil $10				; print the A char
	
	ld a, (debug_char)
	ret					; head back

debug_char: 	.db 0

; ---------------------------------------------
;
;	TEXT AND DATA	
;
; ---------------------------------------------

text_data:

	.db 31, 0, 0, "Serial Read on UART1"
	.db 31, 0, 2, "Command:"
	.db 31, 0, 4, "Data:"

end_text_data:

; ---------------------------------------------
;
;	PORT CONSTANTS - FOR REFERENCE, NOT ALLL ARE USED
;
; ---------------------------------------------

PORT:			EQU	$D0		; UART1
				
REG_RBR:		EQU	PORT+0		; Receive buffer
REG_THR:		EQU	PORT+0		; Transmitter holding
REG_DLL:		EQU	PORT+0		; Divisor latch low
REG_IER:		EQU	PORT+1		; Interrupt enable
REG_DLH:		EQU	PORT+1		; Divisor latch high
REG_IIR:		EQU	PORT+2		; Interrupt identification
REG_FCT:		EQU	PORT+2;		; Flow control
REG_LCR:		EQU	PORT+3		; Line control
REG_MCR:		EQU	PORT+4		; Modem control
REG_LSR:		EQU	PORT+5		; Line status
REG_MSR:		EQU	PORT+6		; Modem status
REG_SCR:		EQU 	PORT+7		; Scratch
TX_WAIT:		EQU	16384 		; Count before a TX times out
UART_LSR_ERR:		EQU 	$80		; Error
UART_LSR_ETX:		EQU 	$40		; Transmit empty
UART_LSR_ETH:		EQU	$20		; Transmit holding register empty
UART_LSR_RDY:		EQU	%01		; Data ready




