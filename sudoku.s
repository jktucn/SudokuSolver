			area sudoku, code, readonly
pinsel0  equ  0xe002c000	; controls function of pins
u1start  equ  0xe0010000	; start of UART1 registers
lcr0  equ  0xc		; line control register for UART1
lsr0  equ  0x14		; line status register for UART1
ramstart  equ  0x40000050	; start of onboard RAM for 2104
stackstart  equ  0x40003FFC  ; start of stack
	
			entry
start
			
			ldr sp, = stackstart	; set up stack pointer
			bl UARTConfig			; initialize/configure UART1
			ldr r1, = string1		; starting address of CharData1
			bl Display				; display CharData1
			
			ldr r4, = ramstart		; r4 stores the address of the sudoku question
			mov r1, r4
			bl SaveInput
			ldr r1, = opa ;debug for input length
			str r2, [r1] ;debug for input length
			
			cmp r2, #81				; section for checking sudoku question validity
			blne WrongLength
			mov r1, r4
			bl CheckInput

			mov r1, r4
			mov r2, #0
			bl Solve
			cmp r0, #1
			blne NoSolution
			mov r2, r4
			bl DisplaySol
			
			

			
done		b done			
			
; subroutine UARTConfig
;   Configures the I/O pins first.
;   Then sets up the UART control register.
;   Parameters set to 8 bits, no parity, and 1 stop bit.
;   Registers used:
;   r5 - scratch register
;   r6 - scratch register
;   inputs:  none
;   outputs:  none

UARTConfig
			push {r5, r6, lr}
			ldr r5, = pinsel0	; base address of register
			ldr r6, [r5]		; get contents
			bic r6, r6, #0xf0000		; clear out lower nibble
			orr r6, r6, #0x50000	; sets P0.0 to Tx0 and P0.1 to Rx0
			str r6, [r5]		; r/modify/w back to register
			ldr r5, = u1start
			mov r6, #0x83		; set 8 bits, no parity, 1 stop bit
			strb r6, [r5, #lcr0]	; write control byte to LCR
			mov r6, #0x61		; 9600 baud @ 15MHz VPB clock
			strb r6, [r5]		; store control byte
			mov r6, #3		; set DLAB = 0
			strb r6, [r5, #lcr0]	; Tx and Rx buffers set up
			pop {r5, r6, pc}
			
			
; 	subroutine Transmit
;   Puts one byte into the UART for transmitting
;   Registers used:
;   r5 - scratch register
;   r6 - scratch register
;   inputs:  r0 - byte to transmit
;   outputs:  none
Transmit	; parameter r0, the ascii code to be transmitted
			push {r5, r6, lr}
			ldr r5, = u1start
twait		ldrb r6, [r5, #lsr0]	; get status of buffer
			tst r6, #0x20		; buffer empty?
								; in above instruction, text uses cmp, but should be tst
			beq twait		; spin until buffer is empty
			strb r0, [r5]	; display r0
			pop {r5, r6, pc}

Receive		; return r0, the ascii code received
			push {r5, r6, lr}
			ldr r5, =u1start
rwait		ldrb r6, [r5, #lsr0]	; get status of buffer
			tst r6, #0x1				; buffer full?
			beq rwait					; spin until butter is full
			ldrb r0, [r5]
			pop {r5, r6, pc}
			
			
Display		; display the string stored at address r1
			; parameter r1, the address of the string to be displayed
			push {lr}					
dpstart		ldrb r0, [r1], #1	; load character, increment address
			cmp r0, #0		; null terminated?
			blne Transmit		; send character to UART
			bne dpstart		; continue if not a '0'
			pop {pc}
			
			
Display1	; display the string stored at address r1, output a space in every 3 character
			; parameter r1, the address of the string to be displayed
			push {lr}
			mov r2, #-1
dp1start	add r2, r2, #1
			cmp r2, #3
			bne skipspace
			mov r2, #0
			mov r0, #0x20		; output a space
			bl Transmit
skipspace	ldrb r0, [r1], #1	; load character, increment address
			cmp r0, #0		; null terminated?
			blne Transmit		; send character to UART
			bne dp1start		; continue if not a '0'
			pop {pc}
			
SaveInput	; save the input string at address r1 and return the length of the string in r2
			; parameter r1, the address of the saved input string
			; return r2, the length of the string
			push {lr}
			mov r2, #0
sistart		bl Receive
			bl Transmit
			cmp r0, #13
			addne r2, r2, #1
			strbne r0, [r1], #1
			bne sistart
			mov r0, #0
			strb r0, [r1]
			pop {pc}
			
Clear
			push {lr}
			mov r0, #13		; display a cr
			bl Transmit
			mov r0, #32		; display a space
			mov r1, #0
clearloop	bl Transmit
			add r1, r1, #1
			cmp r1, #100
			blt clearloop
			mov r0, #13
			bl Transmit
			pop {pc}
			
WrongLength
			;push {lr}
			bl Clear
			ldr r1, = string3
			bl Display
			b done
			
WrongData
			bl Clear
			ldr r1, = string4
			bl Display
			b done
			
NoSolution
			bl Clear
			ldr r1, = string5
			bl Display
			b done
			
DisplaySol	bl Clear
			ldr r1, = string2
			bl Display
			mov r1, r2
			bl Display1
			b done
			
CheckInput	; check the input string at address r1
			push {lr}
ciloop		ldrb r2, [r1], #1
			cmp r2, #0
			beq cidone
			cmp r2, #0x30
			bllt WrongData
			cmp r2, #0x39
			blgt WrongData
			b ciloop
cidone		pop {pc}

Solve
			; recersive call to solve the sudoku puzzle
			; parameter r1, the address of the sudoku table
			; parameter r2, the current working index of the table
			; return r0 = 1, found a solution
			; return r0 = 0, no solution
			push {r4-r9, lr}
			mov r4, r1		; the address of the sudoku table
			mov r5, r2		; the current wokring index
			cmp r5, #81
			beq strue
			add r6, r5, #1	; the next wokring index
			ldrb r7, [r4, r5]	; the digit at current index
			cmp r7, #0x30
			beq sguess
			mov r1, r4			; preparing call Solve on next index
			mov r2, r6
			bl Solve
			b sdone
sguess		mov r1, r5			; preparing call GetY
			bl GetY
			mov r7, r0 			; the current Y index
			mov r1, r5			; preparing call GetX
			mov r2, r7
			bl GetX
			mov r8, r0			; the current X index
			; check loop
			mov r9, #0x31		; guess number
sloop		mov r0, r4			; preparing call CheckSquare
			mov r1, r8
			mov r2, r7
			mov r3, r9
			bl CheckSquare
			cmp r0, #0
			beq sloopupdate
			mov r1, r4			; preparing call CheckRow
			mov r2, r7
			mov r3, r9
			bl CheckRow
			cmp r0, #0
			beq sloopupdate
			mov r1, r4			; preparing call CheckCol
			mov r2, r8
			mov r3, r9
			bl CheckCol
			cmp r0, #0
			beq sloopupdate
			strb r9, [r4, r5]
			mov r1, r4			; preparing call Solve on next Index
			mov r2, r6
			bl Solve
			cmp r0, #1
			beq strue
sloopupdate	add r9, r9, #1
			cmp r9, #0x3A
			blt	sloop
			;after loop
			mov r1, #0x30
			strb r1, [r4, r5]
			mov r0, #0
			b sdone
strue		mov r0, #1			
sdone		pop {r4-r9, pc}

GetY		; find Y index of the current index
			; parameter r1, the current index to be translated
			; return r0, the corresponding Y index
			push {lr}
			cmp r1, #8
			bgt getytest2
			mov r0, #0			; i <= 8
			b getydone
getytest2	cmp r1, #17
			bgt getytest3
			mov r0, #1			; i <= 17
			b getydone
getytest3	cmp r1, #26
			bgt getytest4
			mov r0, #2			; i <= 26
			b getydone
getytest4	cmp r1, #35
			bgt getytest5
			mov r0, #3			; i <= 35
			b getydone
getytest5	cmp r1, #44
			bgt getytest6
			mov r0, #4			; i <= 44
			b getydone
getytest6	cmp r1, #53
			bgt getytest7
			mov r0, #5			; i <= 53
			b getydone
getytest7	cmp r1, #62
			bgt getytest8
			mov r0, #6			; i <= 62
			b getydone
getytest8	cmp r1, #71
			movle r0, #7		; i <= 71
			ble getydone
			mov r0, #8			; else
getydone	pop {pc}


GetX		; find X index of the current index
			; parameter r1, the current index to be translated
			; parameter r2, the current Y index
			; return r0, the corresponding X index
			push {lr}
			add r2, r2, r2, lsl #3	; Y * 9
			sub r0, r1, r2		; i - Y * 9
			pop {pc}
			
CheckSquare	; check if the current guess number satisfies the little square
			; parameter r0, the address of the sudoku table
			; parameter r1, the X index
			; parameter r2, the Y index
			; parameter r3, the current guess number
			; return r0 = 0, not satisfied
			; return r0 = 1, satisfied
			push {r4-r7, lr}
			cmp r1, #2
			bgt csxtest1
			mov r4, #0		; X index of the top-left corner of the little square when real X <= 2
			b csytest
csxtest1	cmp r1, #5
			movle r4, #3	; real X <= 5
			movgt r4, #6	; real X else
csytest		cmp r2, #2
			bgt csytest1
			mov r5, #0		; Y index of the top-left corner of the little square when real Y <= 2
			b cscalindex
csytest1	cmp r2, #5
			movle r5, #3	; real Y <= 5
			movgt r5, #6
cscalindex	add r5, r5, r5, lsl #3	; Y * 9
			add r6, r4, r5	; X + Y * 9 index of the top-left corner in sudoku table
			mov r1, #0		; index k
			mov r2, #0		; index j
csloop		add r1, r1, #1
			ldrb r7, [r0, r6]
			cmp r7, r3
			beq csfalse
			cmp r1, #3				
			moveq r1, #0		
			addeq r6, r6, #7
			addne r6, r6, #1
			add r2, r2, #1
			cmp r2, #9
			blt csloop
			mov r0, #1
			b csdone
csfalse		mov r0, #0
csdone		pop {r4-r7, pc}

CheckRow	; check if the current guess number satisfies the row
			; parameter r1, the address of the sudoku table
			; parameter r2, the Y index
			; parameter r3, the current guess number
			; return r0 = 0, not satisfied
			; return r0 = 1, satisfied
			push {r4-r5, lr}
			lsl r4, r2, #3
			add r4, r4, r2		; check index
			mov r0, #0
crloop		ldrb r5, [r1, r4]
			cmp r5, r3
			beq crfalse
			add r4, r4, #1
			add r0, r0, #1
			cmp r0, #9
			blt crloop
			mov r0, #1
			b crdone
crfalse		mov r0, #0
crdone		pop {r4-r5, pc}


CheckCol	; check if the current guess number satisfies the column
			; parameter r1, the address of the sudoku table
			; parameter r2, the X index
			; parameter r3, the current guess number
			; return r0 = 0, not satisfied
			; return r0 = 1, satisfied
			push {r4, lr}
			mov r0, #0
ccloop		ldrb r4, [r1, r2]
			cmp r4, r3
			beq ccfalse
			add r2, r2, #9
			add r0, r0, #1
			cmp r0, #9
			blt ccloop
			mov r0, #1
			b ccdone
ccfalse		mov r0, #0
ccdone		pop {r4, pc}
			
			
string1  	dcb "Enter Question : ", 0
string2  	dcb "Solution : ", 0
string3		dcb "Wrong Length!", 0
string4		dcb "Wrong Data!", 0
string5		dcb "No solution!", 0

			align
				
			area 	data_suppl, data, readwrite
opa			dcd 0
opb 		dcd 0
			end