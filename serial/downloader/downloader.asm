SECTION "Downloader", ROM0[$0000]

INCLUDE "hram.asm"
INCLUDE "charmap.asm"

wTileMap EQU $c3a0

coord: MACRO
	ld \1, wTileMap + 20 * \3 + \2
	ENDM

; protocol protocol
protocolStop EQU $0
protocolQuery EQU $1
protocolNOP EQU $FF

; downloader protocol
protocolDownloaderID EQU $50
protocolDownloaderVersion EQU $2

downloader_getSizeMSB EQU $2
downloader_getSizeLSB EQU $3
downloader_start EQU $4
downloader_getPatchSizeMSB EQU $5
downloader_getPatchSizeLSB EQU $6

downloadTargetAddress EQU $da00
patchlistAddress EQU $d887

; PatchList format: (This patches in 0xFE bytes)
; Base offset - 1 byte - If 0x00, it is the end of the patch list
; Patch Address - 2 bytes - Final address is Patch Address+(Base offset-1)
; Base offset is 1 is the patch address happens to have 0xFE in the lsb

Serial_SyncAndExchangeNybble EQU $227f
Serial_ExchangeByte EQU $219a
Serial_ExchangeBytes EQU $216f
FillMemory EQU $36e0

downloader::
	call $190f		; ClearScreen

	ld de, stringMessage ; source
	coord hl, 0, 0	; dest
	call $1955		; PlaceString

	; The serial protocol is quite weird.
	; We send a byte and receive the previous byte.

	; Signal the start of the downloader protocol
	; This returns "Undefined" data
	ld a, protocolDownloaderID
	ld [hSerialSendData], a
	call Serial_ExchangeByte

	; Send a NOP so we can read the result of the protocol starting
	ld a, protocolNOP
	ld [hSerialSendData], a
	call Serial_ExchangeByte

	; The received byte will the the version of the downloader protocol
	; We CANNOT use cp because 0xFE bytes are not allowed through the serial protocol
	; without a patch list
	; We don't want to rely on the game's internal patching functionality because it has a limited range
	; Any changes to this code could potentially break it
	sub protocolDownloaderVersion
	; If the version doesn't match, report a failure
	ld de, stringProtocolVersionFailure
	jp nz, error

	; Send getPatchSizeMSB, Recv NOP
	ld a, downloader_getPatchSizeMSB
	ld [hSerialSendData], a
	call Serial_ExchangeByte

	; Send getPatchSizeLSB, Recv PATCH MSB
	ld a, downloader_getPatchSizeLSB
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ld b, a

	; Send getSizeMSB, Recv PATCH LSB
	ld a, downloader_getSizeMSB
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ld c, a

	push bc ; save the patch size on stack

	; clear the memory for the patch list
	xor a
	ld hl, patchlistAddress
	call FillMemory

	; Send getSizeLSB, Recv SIZE MSB
	ld a, downloader_getSizeLSB
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ld b, a

	; Send start, Recv SIZE LSB
	ld a, downloader_start
	ld [hSerialSendData], a
	call Serial_ExchangeByte
	ld c, a

	; clear the memory for the download target
	push bc
	xor a
	ld hl, downloadTargetAddress
	call FillMemory
	pop bc

	; next, exchange bytes into the target address
	ld hl, downloadTargetAddress
	ld de, downloadTargetAddress
	call Serial_ExchangeBytes

	pop bc ; pop the patchlist size off the stack

	; next, exchange bytes into the patch list
	ld hl, patchlistAddress
	ld de, patchlistAddress
	call Serial_ExchangeBytes

	; then patch
	ld hl, patchlistAddress
.patchloop
	; load a byte from the patch list and increment hl
	ld a, [hli]
	; if a == 0x00, jump to the downloaded code
	and a
	jr z, .exit
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
	; indirectly load 0xFE into a
	ld a, $FD
	inc a
	; write FE at address pointed by bc
	ld [bc], a
	; jump back to the beginning of the patch loop
	jr .patchloop

.exit
	call downloadTargetAddress
	jp downloader

error:
	coord hl, 0, 1 ; destination
	call $1955      ; PlaceString
.errorLoop
	jr .errorLoop

stringMessage::
	db "PGI:SPD v1", $50
stringProtocolVersionFailure::
	db "PVF", $50
