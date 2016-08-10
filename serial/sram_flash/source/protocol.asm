; global protocol
protocolStop EQU $0
protocolQuery EQU $1
protocolNOP EQU $FF

; sram_flash protocol
protocolFlashID EQU $51
protocolFlashVersion EQU $1

; dump the sram flash to serial
flash_dumpBank EQU $2
; flash the sram flash from serial
flash_flashBank EQU $3
; size of the send buffer
flash_setDataChunkSizeMSB EQU $4
flash_setDataChunkSizeLSB EQU $5
; set the bank to be dumped (add the bank to the value ($6-$A))
flash_setBank EQU $6

; Dump protocol:
; flash_setBank+0
; flash_setDataChunkSizeMSB
; chunk size msb
; flash_setDataChunkSizeLSB
; chunk size lsb
; flash_dumpBank
; <Serial_ExchangeBytes the size of each chunk, enough to cover datachunksize bytes or more>
; <Serial_ExchangeBytes the size of data chunk, but contains patch list>
; Any extra data from a chunk that exceeds the size of a SRAM bank will be discarded

; Flash protocol:
; flash_setBank+0
; flash_flashBank
; <Serial_ExchangeBytes the size of entire SRAM bank>
; <Serial_ExchangeBytes the size of data chunk, but contains patch list>
