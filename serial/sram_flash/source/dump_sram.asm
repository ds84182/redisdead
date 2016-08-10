StartDump:
	; tell the program we are going to dump the flash
	call SendDataChunkSize

	ld de, stringDump
	coord hl, 0, 17
	call PlaceString

	coord hl, 14, 17
	push hl
	ld a, "0"
	ld [hl], a

	xor a
	call DumpBank

	pop hl
	push hl
	ld a, "1"
	ld [hl], a

	ld a, $1
	call DumpBank

	pop hl
	push hl
	ld a, "2"
	ld [hl], a

	ld a, $2
	call DumpBank

	pop hl
	push hl
	ld a, "3"
	ld [hl], a

	ld a, $3
	call DumpBank

	pop hl

	call redrawScreen

	jp promptloop

DumpBank:
	push af
	send flash_setBank
	pop af
	push af
	sendWithoutLoad

	send flash_dumpBank

	OpenSRAM
	pop af
	SetSRAMBank a

	ld a, (bankSize/bufferSize)+1

	; then copy SRAM into a 1300 byte buffer (wOverworldMap) for modification before sending
.dumpLoop
	push af
	call GetSRAMAddressForBufferIndex
	ld de, buffer
	call CopyDataAndFix

	; then send the buffer via ExchangeBytes
	call ExchangeBuffer
	
	pop af
	dec a
	jr nz, .dumpLoop

	; create a patchlist for the SRAM bank
	ld hl, $a000
	ld de, buffer
	ld bc, $2000
	call PatchList_Create

	; then send the patchlist
	call ExchangeBuffer

	send protocolNOP
	send protocolNOP

	CloseSRAM
	ret

CopyDataAndFix:
; Copy bc bytes from hl to de and change $FE to $FF
	ld a, [hli]
	cp $FE
	jr nz, .continue
	ld a, $FF
.continue
	ld [de], a
	inc de
	dec bc
	ld a, c
	or b
	jr nz, CopyDataAndFix
	ret
