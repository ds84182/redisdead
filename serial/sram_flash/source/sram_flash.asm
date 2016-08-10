SECTION "SRAM Flash", ROM0[$0000]

INCLUDE "symbols.asm"
INCLUDE "hram.asm"
INCLUDE "constants.asm"
INCLUDE "charmap.asm"
INCLUDE "protocol.asm"
INCLUDE "sram_handler.asm"

coord: MACRO
	ld \1, wTileMap + 20 * \3 + \2
	ENDM

setcoord: MACRO
	ld [wTileMap + 20 * \2 + \1], \3
	ENDM

send: MACRO
	ld a, \1
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ENDM

sendWithoutLoad: MACRO
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ENDM

buffer EQU wOverworldMap
bufferSize EQU 1300
bankSize EQU $2000
buffersPerBank EQU (bankSize/bufferSize)+1

sram_flash:
	call ClearScreen

	ld de, stringProgram ; source
	coord hl, 0, 0	; dest
	call PlaceString	

	; The serial protocol is quite weird.
	; We send a byte and receive the previous byte.

	; Signal the start of the downloader protocol
	; This returns "Undefined" data
	send protocolFlashID

	; Send a NOP so we can read the result of the protocol starting
	send protocolNOP
	; The received byte will the the version of the flash protocol
	cp protocolFlashVersion
	; If the version doesn't match, report a failure
	ld de, stringProtocolVersionFailure
	jp nz, error

	call redrawScreen

promptloop:
	call JoypadLowSensitivity
	ld a, [hJoyPressed]
	cp D_UP
	jr z, dpadUP
	cp D_DOWN
	jp z, dpadDOWN
	cp B_BUTTON
	jp z, Exit
	cp A_BUTTON
	jp z, menuSelected

	jp promptloop

dpadUP:
	ld a, [selectedMenuItem]
	cp $0
	jr z, .exit
	dec a
	ld [selectedMenuItem], a
	call drawCursor
.exit
	jp promptloop

dpadDOWN:
	ld a, [selectedMenuItem]
	cp $2
	jr z, .exit
	inc a
	ld [selectedMenuItem], a
	call drawCursor
.exit
	jp promptloop

menuSelected:
	ld hl, menuJumpTable
	ld a, [selectedMenuItem]
	add a
	add l
	ld l, a
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, d
	ld l, e
	jp [hl]

SendDataChunkSize:
	send flash_setDataChunkSizeMSB
	send bufferSize>>8
	send flash_setDataChunkSizeLSB
	send bufferSize&$FF
	ret

ExchangeBuffer:
	ld hl, buffer
	ld de, buffer
	ld bc, bufferSize
	jp Serial_ExchangeBytes

GetSRAMAddressForBufferIndex:
	ld hl, $a000
	ld bc, bufferSize
	ld d, a
	ld a, buffersPerBank
	sub d
	ret z
.multiplyLoop
	add hl, bc
	dec a
	jr nz, .multiplyLoop
	ret

CalculateBufferSize:
	; calculates a proper BC depending on if the current HL+BC extends DE
	push af
	push hl
	add hl, bc
	; HL = HL-DE
	ld a, l
	sub e
	ld l, a
	ld a, h
	sbc d
	ld h, a
	bit 7, h ; is it negative?
	; if it is negative, then its good
	; if it is positive, then its bad
	jr nz, .exit
	; BC = BC-HL
	ld a, c
	sub l
	ld c, a
	ld a, b
	sbc h
	ld b, a
.exit
	pop hl
	pop af
	ret

INCLUDE "dump_sram.asm"
INCLUDE "flash_sram.asm"

Exit:
	send protocolStop
	ret

error:
	coord hl, 0, 1 ; destination
	call PlaceString
.errorLoop
	jr .errorLoop

redrawScreen:
	push de
	push hl

	call ClearScreen

	ld de, stringProgram ; source
	coord hl, 0, 0	; dest
	call PlaceString

	ld de, stringMenuDump ; source
	coord hl, 1, 2	; dest
	call PlaceString

	ld de, stringMenuFlash ; source
	coord hl, 1, 3	; dest
	call PlaceString

	ld de, stringMenuExit ; source
	coord hl, 1, 4	; dest
	call PlaceString

	call drawCursor

	pop hl
	pop de
	ret

drawCursor:
	push af
	push hl
	push bc

	ld bc, 20

	ld a, [selectedMenuItem]
	coord hl, 0, 2

	ld [hl], " "
	cp $0
	jr nz, .skipDumpCursor
	ld [hl], "▶"
.skipDumpCursor

	add hl, bc

	ld [hl], " "
	cp $1
	jr nz, .skipFlashCursor
	ld [hl], "▶"
.skipFlashCursor

	add hl, bc

	ld [hl], " "
	cp $2
	jr nz, .skipExitCursor
	ld [hl], "▶"
.skipExitCursor

	pop bc
	pop hl
	pop af
	ret

selectedMenuItem:
	db $0
menuJumpTable:
	dw StartDump
	dw StartFlash
	dw Exit

stringProgram:
	db "PGI:FLASH v1", $50
stringProtocolVersionFailure:
	db "Protocol Version Failure", $50
stringMenuDump:
	db "Dump SRAM", $50
stringMenuFlash:
	db "Flash SRAM", $50
stringMenuExit:
	db "Exit", $50
stringDump:
	db "Dumping Bank", $50
stringFlash:
	db "Flashing Bank", $50

INCLUDE "patch_list.asm"
INCLUDE "serial_utils.asm"
