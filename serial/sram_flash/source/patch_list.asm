; utilities to create patchlists for data and to patch data with a patchlist

; PatchList format: (This patches in 0xFE bytes)
; Base offset - 1 byte - If 0x00, it is the end of the patch list
; Patch Address - 2 bytes - Final address is Patch Address+(Base offset-1)
; Base offset is 1 is the patch address happens to have 0xFE in the lsb

; Arguments:
;  hl - Data to create the patch list from
;  bc - Size of the data
;  de - Location of the patch list to be written to
PatchList_Create:
.loop:
	; return if bc == 0
	ld a, c
	or b
	jp z, .exit

	ld a, [hli]
	dec bc
	cp $FE
	jr nz, .loop
	; Patch this byte
	dec hl ; Move HL back to where the data actually is
	ld a, l
	cp $FE ; If the patch address ends with $FE, patch differently

	jr nz, .writePatchNormal

	ld a, $02
	dec hl
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	inc hl
	jr .end

.writePatchNormal
	ld a, $01
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de

.end
	inc hl
	jp .loop
.exit
	ld a, $00
	ld [de], a
	ret

PatchList_Apply:
.loop
	; load a byte from the patch list and increment hl
	ld a, [hli]
	; if a == 0x00, jump to the downloaded code
	and a
	ret z
	; else, push af onto stack
	push af
	; load a 16 bit value from [hl] and increment hl
	ld a, [hli]
	ld b, a
	ld a, [hli]
	; pop af into de
	pop de
	; decrement d (Base Offset)
	dec d
	; add d to a (A == LSB of patch address)
	add d
	; move a to c to create full 16 bit register
	ld c, a
	; write FE at address pointed by bc
	ld a, $FE
	ld [bc], a
	; jump back to the beginning of the patch loop
	jr .loop
