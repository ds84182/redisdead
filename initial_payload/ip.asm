SECTION "Initial Payload", ROM0[$0000]

sram_callguard:: ; 20 bytes.
	; The town map code writes to MBC stuff controlling the SRAM for no good reason
	; So entry points need to offer sram_callguards
	; This can also be used for invoking save routines while running from SRAM
	ld bc, .return
	push bc
	jp [hl]
.return
	; reenable sram
	ld a, $0a ;enable sram code
	ld [$0000], a ;do the enable
	
	ld a, $1
	ld [$6000], a ;sram banking mode
	
	inc a
	inc a
	ld [$4000], a ;sram bank 3
	
	ret

payload::
	;this payload will execute some startup code (enable SRAM, Bank 3)
	;then will jump to the payload
	
	;TODO: Compare current box id selected, return out if not box 0 (wCurrentBoxNum)
	;7 bytes
	;ld a, [$d5a0] ;wCurrentBoxNum
	;and $3f
	;ret nz
	
	ld a, $0a ;enable sram code
	ld [$0000], a ;do the enable
	
	ld a, $1
	ld [$6000], a ;sram banking mode
	
	inc a
	inc a
	ld [$4000], a ;sram bank 3
	
	ld bc, sram_callguard ; give the sram code a pointer to our callguard
	ld de, payload ; also give the payload entrypoint for global installation purposes
	call $a000 ;call our sram code
	
	;disable sram
	
	xor a
	ld [$6000], a ;sram banking mode
	ld [$0000], a ;disable
	
	ret ;return to game
	
	ds 7 ; payload two: electric boogaloo
	; this is the start of the pewter exploit
	; we have very little space between the two
	; so we must be careful
	jp payload
