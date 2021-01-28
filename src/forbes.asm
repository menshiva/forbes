.include "m169def.inc"

.org 0x1000
.include "utils\print.inc"

.cseg

.def displayChar = R16
.def displayCharPos = R17
.def seed = R18
.def randNum = R19
.def pressedButton = R20
.def buttonLocker = R21
.def mode = R22
.def lastChar = R23
.def gameResult = R24
.def tmp = R25

.org 0x0000
 	RJMP start

.org 0x100
	; 0 HARD, 1 EASY
	gamemode: .db 0

start:
    ; Stack init
	LDI displayChar, 0xFF
	OUT SPL, displayChar
	LDI displayChar, 0x04
	OUT SPH, displayChar

    ; Display init
	CALL displayInit
	; Joystick init
	CALL init_joy

	; Save gamemode to mode
	LDI R30, low(2 * gamemode)
	LDI R31, high(2 * gamemode)
	LPM mode, Z

	; Print 'Start' on display
	CALL clearDisplay
	CALL print_start
	LDI buttonLocker, 1

	start_loop:
		INC seed
		; Read center button status
		CALL read_joy
    	CPI pressedButton, 1
		; If center button is pressed
    	BRNE startCenterBtnNotPressed
		; If buttonLocker == 0 then buttonLocker = 1 and break loop
		; Else continue loop
			CPI buttonLocker, 0
			BRNE start_loop
			INC buttonLocker
			RJMP endStartCheckButton
			; If center button is not pressed
		startCenterBtnNotPressed:
			; If buttonLocker == 1 then buttonLocker = 0
			; Else continue loop
			CPI buttonLocker, 1
			BRNE start_loop
			DEC buttonLocker
			RJMP start_loop

	endStartCheckButton:

	CALL clearDisplay
	CALL forbes_diplay_init
	LDI displayCharPos, 6

	roll_loop:
		INC seed
		CALL getRandFromSeed ; Store random number in randNum
		MOV displayChar, randNum
		CALL showChar

		; Check if button pressed and wait for time
		; Time is longer when gamemode is 1
		LDI R26, 0x10
		CPI mode, 1
		BRNE wait
		SUBI R26, -0xEF
		wait:
			; Read center button status
			CALL read_joy
    		CPI pressedButton, 1
			; If center button is pressed
    		BRNE centerBtnNotPressed
			; If buttonLocker == 0 then buttonLocker = 1 and displayCharPos -= 1 to set next roll
			; Else continue loop
				CPI buttonLocker, 0
				BRNE endCheckButton
				INC buttonLocker

				; Compare last char with current.
				; If they are the same - set gameResult to 1
				; Else set gameResult to 0.
				; And copy current char to lastChar
				CP displayChar, lastChar
				BRNE setZeroResult
				LDI gameResult, 1
				RJMP endSetResult
				setZeroResult:
				LDI gameResult, 0
				endSetResult:
				MOV lastChar, displayChar

				DEC displayCharPos
				; If displayCharPos == 3 then break loop
				CPI displayCharPos, 3
				BREQ printResult

				RJMP roll_loop
			; If center button is not pressed
			centerBtnNotPressed:
				; If buttonLocker == 1 then buttonLocker = 0
				; Else continue loop
				CPI buttonLocker, 1
				BRNE endCheckButton
				DEC buttonLocker

			endCheckButton:

		DEC R26
		BRNE wait

		RJMP roll_loop

	; If gameResult == 1 then blink_winner() else blink_loser()
	printResult:
		CPI gameResult, 1
		BREQ win
			CALL blink_loser
			RJMP final_loop
		win:
			CALL blink_winner
		
	final_loop:
		; Read center button status
		CALL read_joy
    	CPI pressedButton, 1
		; If center button is pressed
    	BRNE finalCenterBtnNotPressed
		; If buttonLocker == 0 then buttonLocker = 1 and goto start
		; Else continue loop
			CPI buttonLocker, 0
			BRNE start_loop
			INC buttonLocker
			RJMP start
			; If center button is not pressed
		finalCenterBtnNotPressed:
			; If buttonLocker == 1 then buttonLocker = 0
			; Else continue loop
			CPI buttonLocker, 1
			BRNE final_loop
			DEC buttonLocker
			RJMP final_loop

end:
	; Infinite loop
	RJMP end

; Generate random number
getRandFromSeed:
	ADD randNum, seed
	SWAP seed
	CLC
	; while (randNum > 15) randNum -= 16
	normalizeRandomNumber:
		CPI randNum,16
   		BRLO finishNormalize
		SUBI randNum, 16
		RJMP normalizeRandomNumber
	; Convert randNum to char
	finishNormalize:
		SUBI randNum, -'0'
		; If randNum is < ('9' + 1), then goto first_skip.
		; Else randNum += ('A' - ('9' + 1)) (to get 'A', 'B', 'C', etc.)
		CPI randNum, 58
		BRLO endConvertingChar
		SUBI randNum, -7
	endConvertingChar:
	RET

; Blink 'WINNER' 3 times
blink_winner:
	LDI tmp, 0
	blinkWin:
		CALL clearDisplay
		CALL waitHalfSec
		CALL print_winner
		CALL waitHalfSec
		INC tmp
		CPI tmp, 3
		BRNE blinkWin
	RET

; Blink 'LOSER' 3 times
blink_loser:
	LDI tmp, 0
	blinkLose:
		CALL clearDisplay
		CALL waitHalfSec
		CALL print_loser
		CALL waitHalfSec
		INC tmp
		CPI tmp, 3
		BRNE blinkLose
	RET

; Function to print 'START' on display
print_start:
	LDI displayCharPos, 2
	LDI displayChar, 'S'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'T'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'A'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'R'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'T'
	CALL showChar
	RET

; Function to print 'WINNER' on display
print_winner:
	LDI displayCharPos, 2
	LDI displayChar, 'W'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'I'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'N'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'N'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'E'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'R'
	CALL showChar
	RET

; Function to print 'LOSER' on display
print_loser:
	LDI displayCharPos, 2
	LDI displayChar, 'L'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'O'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'S'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'E'
	CALL showChar
	INC displayCharPos
	LDI displayChar, 'R'
	CALL showChar
	RET

; Function to print start rolls positions on display (0 0 0)
forbes_diplay_init:
	LDI displayCharPos, 4
	LDI displayChar, '0'
	CALL showChar
	INC displayCharPos
	LDI displayChar, '0'
	CALL showChar
	INC displayCharPos
	LDI displayChar, '0'
	CALL showChar
	RET

; Function to clear display.
; for (int i = 2; i < 8; ++i) print(' ')
clearDisplay:
	LDI displayCharPos, 2
	LDI displayChar, ' '
	startClear:
		CALL showChar
		INC displayCharPos
		CPI displayCharPos, 8
		BREQ endClear
		RJMP startClear
	endClear:
	RET

; Joystick init function
init_joy:
    IN R17, DDRE
    ANDI R17, 0b11110011
    IN R16, PORTE
    ORI R16, 0b00001100
    OUT DDRE, R17
    OUT PORTE, R16
    LDI R16, 0b00000000
    STS DIDR1, R16
    IN R17, DDRB
    ANDI R17, 0b00101111
    IN R16, PORTB
    ORI R16, 0b11010000
    OUT DDRB, R17
    OUT PORTB, R16
	RET

; Put joystick pressed button to R20
read_joy:
    PUSH R16
    PUSH R17
	joy_reread:
    	IN R16, PINB
    	LDI pressedButton, 255
	joy_wait:
		DEC pressedButton
    	BRNE joy_wait
    	IN R17, PINB
    	ANDI R16, 0b00010000
    	ANDI R17, 0b00010000
    	CP R16, R17
    	BRNE joy_reread
    	LDI R20, 0
    	CPI R16, 0
    	BRNE joy_no_enter
    	LDI pressedButton, 1
	joy_no_enter:
		POP R17
		POP R16
	RET

; Function to sleep for 500 ms.
; CPU frequency = 2 MHz = 2*10^6 ticks.
; 2*10^6 ticks ~ 3 ticks * 10 * 255 * 255 instructions.
waitHalfSec:
	LDI R28, 0xFF
	waitHalf2:
		LDI R27, 0xFF
			waitHalf:
				DEC R27
	   			BRNE waitHalf
		DEC R28
		BRNE waitHalf2
	RET
