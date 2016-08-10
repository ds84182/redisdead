SECTION "Haxxtime", ROM0[$0000]

INCLUDE "charmap.asm"

INCLUDE "symbols.asm"
INCLUDE "constants.asm"
INCLUDE "hram.asm"

coord: MACRO
	ld \1, wTileMap + 20 * \3 + \2
	ENDM

callfar: MACRO
	ld b, \1_BANK
	ld hl, \1
	call Bankswitch
	ENDM

; TODO: Maybe callfarguards?
callguard: MACRO
	ld hl, \1
	call var_sram_callguard_prelude
	ENDM

text   EQUS "db $00," ; Start writing text.
next   EQUS "db $4e," ; Move a line down.
line   EQUS "db $4f," ; Start writing at the bottom line.
para   EQUS "db $51," ; Start a new paragraph.
cont   EQUS "db $55," ; Scroll to the next line.
done   EQUS "db $57"  ; End a text box.
prompt EQUS "db $58"  ; Prompt the player to end a text box (initiating some other event).

;requirements:
;caller has to give sram callguard function address in bc

main::
	;for right now, display a message on the screen after saving the tile buffer
	;then wait for a to be pressed
	;then return to the game and disable sram
	
	push bc
	
	; hold select to start
	ld a, [hJoyHeld]
	and SELECT
	pop bc
	jp nz, .continue ; if select is down, continue
	ret ; else return
	
.continue
	
	; store sram callguard address
	ld hl, var_sram_callguard
	ld [hl], c
	inc hl
	ld [hl], b
	
	; global installation
	ld a, $1
	ld [wNPCMovementScriptPointerTableNum], a ; use pallet movement table
	ld a, $17
	ld [wNPCMovementScriptFunctionNum], a ; this index jumps to the box payload
	ld a, $11
	ld [wNPCMovementScriptBank], a ; the secondary jump table is in rom bank 17
	
	; call SaveScreenTilesToBuffer2
	
	ld a, $01
	ld [wAutoTextBoxDrawingControl], a ; No text box border
	
	callfar DisplayTextIDInit

refreshscreen::
	
	call ClearScreen ; Clear Screen
	call UpdateSprites ; Update Sprites
	
	coord bc, 0, 0
	ld hl, text_screen
	call TextCommandProcessor
	
promptloop::
	call JoypadLowSensitivity
	ld a, [hJoy5]
	and B_BUTTON
	jr nz, exit
	ld a, [hJoy5]
	and A_BUTTON
	jp nz, do_teleport
	jp promptloop

exit::	
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	
	call CloseTextDisplay
	
	ret

do_teleport::
	; mark all towns as visited
	ld a, $ff
	ld [wTownVisitedFlag], a
	ld [wTownVisitedFlag+1], a
	
	; ChooseFlyDestination sets SRAM bank to 0, for some reason
	callguard ChooseFlyDestination
	
	; if the player decided to fly, then fly
	ld a,[wd732]
	bit 3, a ; did the player decide to fly?
	jp nz, exit
	
	; else, jump to screen setup
	jp refreshscreen

text_screen::
	text "sramhax build 0"
	next "A - Fly"
	next "B - Exit"
	done

var_sram_callguard_prelude:: ;jump instruction
	db $C3
var_sram_callguard:: ; address of the sram callguard function
	ds 2
