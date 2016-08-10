; macros to handle SRAM
OpenSRAM: MACRO
	ld a, $0a
	ld [$0000], a ; enable SRAM
	ld a, $01
	ld [$6000], a ; put SRAM in banking mode
	ENDM

SetSRAMBank: MACRO
	ld [$4000], \1
	ENDM

SelectSRAMBank: MACRO
	ld a, \1
	SetSRAMBank a
	ENDM

CloseSRAM: MACRO
	xor a
	ld [$6000], a ; disable SRAM banking mode
	ld [$0000], a ; disable SRAM
	ENDM
