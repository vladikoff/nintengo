; Prints values in various ways to output,
; including numbers and strings.

newline = 10

; Prints indicated register to console as two hex
; chars and space
; Preserved: A, X, Y, flags
print_a:
	php
	pha
print_reg_:
	jsr print_hex
	lda #' '
	jsr print_char_
	pla
	plp
	rts

print_x:
	php
	pha
	txa
	jmp print_reg_

print_y:
	php
	pha
	tya
	jmp print_reg_

print_p:
	php
	pha
	php
	pla
	jmp print_reg_

print_s:
	php
	pha
	txa
	tsx
	inx
	inx
	inx
	inx
	jsr print_x
	tax
	pla
	plp
	rts


; Prints A as two hex characters, NO space after
; Preserved: A, X, Y
print_hex:
	jsr update_crc
	
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	jsr @nibble
	pla
	
	pha
	and #$0F
	jsr @nibble
	pla
	rts
	
@nibble:
	cmp #10
	blt @digit
	adc #6;+1 since carry is set
@digit: adc #'0'
	jmp print_char_


; Prints character and updates checksum UNLESS
; it's a newline.
; Preserved: A, X, Y
print_char:
	cmp #newline
	beq :+
	jsr update_crc
:       pha
	jsr print_char_
	pla
	rts


; Prints space. Does NOT update checksum.
; Preserved: A, X, Y
print_space:
	pha
	lda #' '
	jsr print_char_
	pla
	rts


; Advances to next line. Does NOT update checksum.
; Preserved: A, X, Y
print_newline:
	pha
	lda #newline
	jsr print_char_
	pla
	rts


; Prints string
; Preserved: A, X, Y
.macro print_str str,str2
	.ifnblank str2
	jsr_with_addr print_str_addr,{.byte str,str2,0}
	.else
	jsr_with_addr print_str_addr,{.byte str,0}
	.endif
.endmacro


; Prints string at addr and leaves addr pointing to
; byte AFTER zero terminator.
; Preserved: A, X, Y
print_str_addr:
	pha
	tya
	pha
	
	ldy #0
	beq :+ ; always taken
@loop:  jsr print_char
	jsr inc_addr
:       lda (addr),y
	bne @loop
	
	pla
	tay
	pla
	; FALL THROUGH

; Increments 16-bit value in addr.
; Preserved: A, X, Y
inc_addr:
	inc addr
	beq :+
	rts
:       inc addr+1
	rts


; Prints A as 1-3 digit decimal value, NO space after.
; Preserved: Y
print_dec:
	; Hundreds
	cmp #10
	blt @ones
	cmp #100
	blt @tens
	ldx #'0'-1
:       inx
	sbc #100
	bge :-
	adc #100
	jsr @digit
	
	; Tens
@tens:  sec
	ldx #'0'-1
:       inx
	sbc #10
	bge :-
	adc #10
	jsr @digit
	
	; Ones
@ones:  ora #'0'
	jmp print_char

	; Print a single digit
@digit: pha
	txa
	jsr print_char
	pla
	rts


; Prints one of two characters based on condition.
; SEC; print_cc bcs,'C','-' prints 'C'.
; Preserved: A, X, Y, flags
.macro print_cc cond,yes,no
	; Avoids labels since they're not local
	; to macros in ca65.
	php
	pha
	cond *+6
	lda #no
	bne *+4
	lda #yes
	jsr print_char
	pla
	plp
.endmacro
