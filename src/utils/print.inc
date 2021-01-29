;*************************************************************************
;
;		Utility file for showing symbols on display
;
;*************************************************************************


;---------------------------------
; Char table
.include "utils\chars.inc"

;---------------------------------
; Display initialization
displayInit:
	LDI	R16, 0xB7
	STS	LCDCRB, R16
	LDI	R16, 0x10
	STS	LCDFRR, R16
	LDI	R16, 0x0F
	STS	LCDCCR, r16
	LDI	R16, 0x80
	STS	LCDCRA, R16
	RET

;---------------------------------
; Show char on display
;
; R16 - char, R17 - position on display
; Function stores and refreshes
; the registers
showChar:
	PUSH	R0
	PUSH	R1
	PUSH	R16
	PUSH	R17
	PUSH	R18
	PUSH	R19
	PUSH	XL
	PUSH	XH
	PUSH	ZL
	PUSH	ZH
	SUBI	R17, 2
	CPI	R16, ' '
	BREQ	space
	CPI	R16, '*'
	BRLO	undef
	CPI	R16, '_' + 2
	BRSH	undef
	JMP	prep

;---------------------------------
; Undefined symbol
;
; Function activates all segments
; on display
undef:
	LDI	R16, '`'
	JMP	prep

;---------------------------------
; Space symbol " "
;
; Using undefined comma instead
; of space symbol
space:
	LDI	R16, ','

;---------------------------------
; Prepare for displaying a symbol
prep:
	SUBI	R16, '*'			; Convert symbol to char table index
	LSL	R16
	LSL	R16  				; R16 *= 4
	LDI	ZL, low(table << 1)
	LDI	ZH, high(table << 1)
	CLR	R0
	ADD	ZL, R16
	ADC 	ZH, R0
	; Compute position
	LDI 	XL, LCDDR0
	CLR	XH
	MOV 	R18, R17			; Save position
	LSR 	R17
	ADD 	XL, R17				; Segment base
	LDI 	R19, 4				; Bytes from char table
	LDI 	R16, 0xf0			; Mask (for saving near symbols on display)
	SBRC 	R18, 0				; Skip mask swapping if char is even
	SWAP 	R16

;---------------------------------
; Show prepared char
show:
	LPM	R0, Z+
	SBRC	R18, 0				; Skip swap if char is even
	SWAP	R0
	LD	R1, X
	AND	R1, R16				; Clear segments for our symbol
	OR	R1, R0				; Activate segment based on our symbol
	ST	X, R1				; Write to display
	ADIW	XL, 5				; Next segment row
	DEC	R19
	BRNE	show

	POP	ZH
	POP	ZL
	POP	XH
	POP	XL
	POP	R19
	POP	R18
	POP	R17
	POP	R16
	POP	R1
	POP	R0

	RET

