StartFlash:
	; tell the program we want to flash
	send flash_setDataChunkSizeMSB
	send bufferSize>>8
	send flash_setDataChunkSizeLSB
	send bufferSize&$FF
	
	ld de, stringFlash
	coord hl, 0, 17
	call PlaceString

	; 15, 17
	coord hl, 15, 17
	push hl
	ld a, "0"
	ld [hl], a

	xor a
	call FlashBank

	pop hl
	push hl
	ld a, "1"
	ld [hl], a

	ld a, $1
	call FlashBank

	pop hl
	push hl
	ld a, "2"
	ld [hl], a

	ld a, $2
	call FlashBank

	pop hl
	push hl
	ld a, "3"
	ld [hl], a

	ld a, $3
	call FlashBank

	pop hl

	call redrawScreen

	jp promptloop

FlashBank:
	push af
	send flash_setBank
	pop af
	push af
	sendWithoutLoad

	send flash_flashBank

	OpenSRAM
	pop af
	SetSRAMBank a

	; zero fill the buffer
	xor a
	ld hl, buffer
	ld bc, bufferSize
	call FillMemory

	ld a, buffersPerBank

.flashLoop
	; exchange SRAM bytes into our buffer
	push af
	call ExchangeBuffer

	; then copy the data from the buffer into SRAM
	pop af
	push af
	call GetSRAMAddressForBufferIndex
	ld de, bankSize+$a000
	call CalculateBufferSize
	ld d, h
	ld e, l
	ld hl, buffer
	call CopyData
	
	pop af
	dec a
	jr nz, .flashLoop

	; then get the patchlist
	call ExchangeBuffer

	; then apply the patchlist
	ld hl, buffer
	call PatchList_Apply

	send protocolNOP
	send protocolNOP

	CloseSRAM
	ret
