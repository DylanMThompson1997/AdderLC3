; Dylan Thompson DTHO410

; ALGORITHM:
; - load msw1, msw2, lsw1 and lsw2
; - call print30 for each msw/lsw pair
;   - which in turn calls print15 for each number
; - print "================ ================"
; - call add30 for the lsw and msw
;   - which in turn calls add15 for each pair of lsw and msw
; - print result30, the result of add30.
;   - passed through print15 and print30, as per.
; ------------------------------------------
        	.orig   x3000

		lea	r0, start
		jmp	r0

op1_lsw     	.fill   b101010101010101	; must be < 32768
op1_msw     	.fill   b000000000000010	; must be < 32768
op2_lsw     	.fill   b111111111111111	; must be < 32768
op2_msw     	.fill   b000000000000001	; must be < 32768

; STORED VALUES
; Binary Maps
BINARY  .FILL   b100000000000000
        .FILL   b010000000000000
        .FILL   b001000000000000
        .FILL   b000100000000000
        .FILL   b000010000000000
        .FILL   b000001000000000
        .FILL   b000000100000000
        .FILL   b000000010000000
        .FILL   b000000001000000
        .FILL   b000000000100000
        .FILL   b000000000010000
        .FILL   b000000000001000
        .FILL   b000000000000100
        .FILL   b000000000000010
        .FILL   b000000000000001

; Stored Values
ASCII_ZERO  .FILL   x0030
ASCII_ONE   .FILL   x0031
MASK_COUNT  .FILL   x0F     ; loop limit = 15

mask		.fill	b111111111111111
signbit		.fill	b100000000000000
carrybit	.fill	b1000000000000000
carryflag	.stringz " c"
overflowflag	.stringz " v"
equal		.stringz "=============== ==============="
newline		.fill #10
result  	.blkw   1
carry   	.blkw   1
overflow    	.blkw   1
; -------------------------------------------------
print_30	st	r7, pr_30_ret
		add	r6, r1, #0	; move lsw to r6
		jsr	print_15	; do the msw first --- r0 holds parameter
		ld	r0, space
		out			; prints a space
		add	r0, r6, #0	; then the lsw --- move lsw from r6
		jsr	print_15
		and	r0, r0, #0
		and	r1, r1, #0
		and	r2, r2, #0
		and	r3, r3, #0
		and	r4, r4, #0
		and	r5, r5, #0
		and	r6, r6, #0
		ld	r7, pr_30_ret
		ret
space		.stringz " "
pr_30_ret	.blkw	1


print_15	st	r7, pr_15_ret
printop1	AND 	R5, R5, #0      ; clear R5
    		ADD 	R5, R5, R0      ; Store the value to print into R5
    		AND 	R1, R1, #0      ; clear R1, R1 is our loop count
    		LD 	R2, MASK_COUNT  ; load our mask limit into R2
    		NOT 	R2, R2          ; Invert the bits in R2
    		ADD 	R2, R2, #1      ; Become 2's compliment
WHILE_LOOP	ADD 	R3, R1, R2      ; Mask and loop counts
    		BRz 	LOOP_END        ; If =0 then we've looped 8 times and need to exit
    		LEA 	R3, BINARY      ; First memory location in our binary mask array
    		ADD 	R3, R3, R1      ; R1 as index and add that to the first location
    		LDR 	R4, R3, #0      ; load the next binary mask into R4
    		AND 	R4, R4, R5      ; AND the user input with the binary mask
    		BRz 	NO_BIT
    		LD 	R0, ASCII_ONE
    		OUT
    		ADD 	R1, R1, #1      ; add one to our loop counter
    		BRnzp 	WHILE_LOOP    	; loop again
NO_BIT 		LD 	R0, ASCII_ZERO
    		OUT
    		ADD 	R1, R1, #1      ; add one to our loop counter
    		BRnzp 	WHILE_LOOP   	; loop again
LOOP_END	ld	r7, pr_15_ret
		ret
pr_15_ret	.blkw	1


add_15	st	r7, add_15_ret
        	add     r2, r0, r1	; r2 is cresult		; r1 and r0 are the operands that are preloaded before the function runs
		ld	r3, mask
		and	r3, r2, r3	; r3 is result
        	st      r3, result
; carry
		and	r3, r3, #0	; clear r3, carry
		ld	r4, carrybit	; r4 is carrybit
        	and     r4, r2, r4
		brz	nocarry
		add	r3, r3, #1
nocarry        	st      r3, carry
; overflow
		and	r3, r3, #0
		ld	r4, signbit	; r4 is signbit
		and	r0, r0, r4	; r0 no longer op1
		brz	plus1
		add	r3, r3, #1
plus1		add	r0, r3, #0	; r0 sign1
		and	r3, r3, #0
		and	r1, r1, r4	; r1 no longer op1
		brz	plus2
		add	r3, r3, #1
plus2		add	r1, r3, #0	; r1 sign2
		and	r3, r3, #0
		and	r2, r2, r4	; r2 no longer cresult
		brz	plus3
		add	r3, r3, #1
plus3		add	r2, r3, #0	; r2 is signres
		and	r3, r3, #0
; we need to compare sign1(r0) with sign2(r1)
		not	r0, r0
		add	r0, r0, #1	; 2's complement
		add	r1, r1, r0	; subtraction
		brnp	different
; compare signres(r2) with sign1(r0)
		add	r2, r2, r0	; subtraction
		brz	different	; actually the same
		add	r3, r3, #1
different	st	r3, overflow
		ld	r7, add_15_ret
		ret
add_15_ret	.blkw	1


add_30	st	r7, add_30_ret
		add	r6, r0, #0	; move msw to r6
		jsr	add_15	; do the lsw first --- r0 holds parameter
		ld	r0, space
		out			; prints a space
; Do the carry and overflow things
		add	r0, r6, #0	; then the msw --- move msw from r6
		jsr	add_15	
		ld	r7, add_30_ret
		ret
add_30_ret	.blkw	1


start		; This is the main block that controls subroutine calls

		LD 	R0, op1_msw		; Call op1 msw, lsw then print and put a newline
		LD 	R1, op1_lsw
		jsr 	print_30
		ld	r0, newline
		out
		LD 	R0, op2_msw		; Call op2 msw, lsw then print and put a newline
		LD 	R1, op2_lsw
		jsr 	print_30
		ld	r0, newline
		out
		lea	r0, equal		; print equals string
		puts
		ld	r0, newline		; newline before we print
		out

		ld	r0, op1_lsw		; Load the lsw into r0, r1
		ld	r1, op2_lsw
		jsr	add_15			; add them together
		ld 	r0, result
		ld	r1, carry
		ld	r2, overflow
		st	r0, lsw_res		; store the carry, overflow and result of the calculation
		st	r1, lsw_carry
		st	r2, lsw_overflow

		ld	r0, op1_msw		; Same process with the msw
		ld	r1, op2_msw
		jsr	add_15
		ld 	r0, result
		ld	r1, carry
		ld	r2, overflow
		st	r0, msw_res
		st	r1, msw_carry
		st	r2, msw_overflow

		ld	r0, msw_res
		ld	r1, lsw_res
		ld 	r2, lsw_carry
		ld	r3, lsw_overflow
		and	r2, r2, r3
		not	r2, r2
		BRp	add_one
add_one		add	r0, r0, #1
finish		jsr	print_30

		ld	r0, msw_carry
		add	r0, r0 #0
		brp	print_carry
		brnz	c_o_finish
print_carry	lea 	r0, carryflag
		puts
		ld	r0, msw_overflow
		add	r0, r0 #0
		brp	print_overf
		brnz	c_o_finish
print_overf	lea 	r0, overflowflag
		puts

lsw_res		.blkw	1
lsw_carry	.blkw	1
lsw_overflow	.blkw	1
msw_res		.blkw	1
msw_carry	.blkw	1
msw_overflow	.blkw	1

c_o_finish	halt
		.end