local plugin = ...

-- config defaults
config.sram_directory = config.sram_directory or "sram_dump"

local lfs = require "lfs"

local program = nil
local patch = nil

local bank = 0
local bankSize = 0x2000
local chunkSize = 256
local dumpChunks = {}
local currentChunk
local flashPosition = 1
local ignoreFirstByte = false
local ignoreSecondByte = false

local function init()
	lfs.mkdir(config.sram_directory)

	bank = 0
	chunkSize = 256
	currentChunk = nil
	flashPosition = 1
	ignoreFirstByte = false
	ignoreSecondByte = false
	dumpChunks = {}
end

local function dumpBank()
	local fil = io.open(config.sram_directory.."/bank"..bank..".bin", "wb")

	-- first, read the patch list and patch the chunks
	local patchlist = dumpChunks[#dumpChunks]
	local i = 1
	while patchlist[i] and patchlist[i] ~= 0 do
		local base = patchlist[i]
		local offset = (patchlist[i+1]<<8|patchlist[i+2])-0xA000+base
		print("Patch at "..offset)
		-- find the chunk that contains that offset
		local chunk = (offset//chunkSize)+1
		print("Patch chunk "..chunk)
		dumpChunks[chunk][offset%chunkSize] = 0xFE
		i = i+3
	end

	--then dump the chunks
	local dump = {}
	for i=1, #dumpChunks-1 do
		local chunk = dumpChunks[i]
		for i=1, chunkSize do
			chunk[i] = string.char(chunk[i])
		end
		dump[i] = table.concat(chunk)
	end
	dump = table.concat(dump):sub(1, bankSize)
	fil:write(dump)
	fil:close()

	dumpChunks = {}
	currentChunk = nil
end

plugin.registerSerialState("protocol_51", nil, function() -- onEnter
	print("FLASHServer started!")

	init()

	jumpSerialState "flash_command"
end).version = 0x01

plugin.registerSerialState("flash_command", function(byte)
	if byte == 0x00 then
		-- leave protocol
		popSerialState()
	elseif byte == 0x02 then
		--dump bank
		print "Dump Bank"
		pushSerialState "flash_dump_bank"
		return 1
	elseif byte == 0x03 then
		--flash bank
		print "Flash Bank"
		pushSerialState "flash_flash_bank"
		return 1
	elseif byte == 0x04 then
		--set data chunk size msb
		print "Set Data Chunk Size MSB"
		pushSerialState "flash_set_data_chunk_size_msb"
		return (chunkSize)>>8
	elseif byte == 0x05 then
		--set data chunk size lsb
		print "Set Data Chunk Size LSB"
		pushSerialState "flash_set_data_chunk_size_lsb"
		return (chunkSize)&0xFF
	elseif byte == 0x06 then
		--set bank
		print "Set Bank"
		pushSerialState "flash_set_bank"
		return bank
	end

	--TODO: handleGlobalSerialCommand

	return byte
end)

plugin.registerSerialState("flash_set_data_chunk_size_msb", function(byte)
	chunkSize = (chunkSize&0xFF)|(byte<<8)
	popSerialState()
	return 1
end)

plugin.registerSerialState("flash_set_data_chunk_size_lsb", function(byte)
	chunkSize = (chunkSize&0xFF00)|(byte)
	popSerialState()
	return 1
end)

plugin.registerSerialState("flash_set_bank", function(byte)
	bank = byte
	popSerialState()
	return 1
end)

plugin.registerSerialState("flash_dump_bank", function(byte)
	if ignoreFirstByte then
		ignoreFirstByte = false
		currentChunk = {}
		return 0xFD
	elseif ignoreSecondByte then -- we ignore the second byte sent because the protocol sends
		-- the first byte again in order to receive our 0xFD response, before sending the real first
		-- byte
		ignoreSecondByte = false
	elseif #currentChunk < chunkSize then
		currentChunk[#currentChunk+1] = byte
	else
		dumpChunks[#dumpChunks+1] = currentChunk
		print("Chunk #"..(#dumpChunks).."/"..((bankSize//chunkSize)+2).." finished")
		if #dumpChunks >= (bankSize//chunkSize)+2 then -- the last chunk is the patch list
			print("Bank dump finished")

			dumpBank()

			popSerialState()
		else
			ignoreFirstByte = true
			ignoreSecondByte = true
		end
	end

	return byte
end, function()
	ignoreFirstByte = true
	ignoreSecondByte = true
end)

plugin.registerSerialState("flash_flash_bank", function(byte)
	if ignoreFirstByte then
		ignoreFirstByte = false
		return 0xFD
	elseif flashPosition <= #currentChunk then
		flashPosition = flashPosition+1
		return currentChunk:byte(flashPosition-1)
	else
		currentChunk = table.remove(dumpChunks, 1)
		flashPosition = 1
		print("Chunk #"..(((bankSize//chunkSize)+2)-#dumpChunks).."/"..((bankSize//chunkSize)+2).." finished")
		if not currentChunk then
			print("Bank dump finished")
			dumpChunks = {}

			popSerialState()
		else
			ignoreFirstByte = true
			ignoreSecondByte = true
		end
	end
	
	return byte
end, function()
	-- load the rom bank into dumpChunks, and load the patchBytes in there too
	local file = io.open(config.sram_directory.."/bank"..bank..".bin", "rb")
	local bankData = file:read("*a")
	file:close()
	
	-- pad or curtail the bank data
	if #bankData < bankSize then
		bankData = bankData..("\255"):rep(bankSize-#bankData)
	elseif #bankData > bankSize then
		bankData = bankData:sub(1, bankSize)
	end
	
	-- create a patch from the bank data
	local patchBytes = {}
	bankData = bankData:gsub("()\254", function(index)
		local addr = index-1+0xA000
		
		if addr&0xFF == 0xFE then
			-- if the address is somehow 0xFE...
			patchBytes[#patchBytes+1] = string.char(2, addr>>8, (addr&0xFF)-1)
		else
			-- else
			patchBytes[#patchBytes+1] = string.char(1, addr>>8, addr&0xFF)
		end
		
		return "\255"
	end)
	
	patchBytes[#patchBytes+1] = "\0"
	local patch = table.concat(patchBytes)
	
	print(patch:gsub(".", function(c)
		return string.format("%02X", c:byte())
	end))
	
	local s, e = patch:find("\254")
	if s then
		error("Patch is broken!")
	end
	
	dumpChunks = {}
	currentChunk = nil
	
	local function addChunk(chunk)
		if #chunk > chunkSize then error("Added chunk thats greater than chunk size!") end
		chunk = chunk..("\255"):rep(chunkSize-#chunk)
		dumpChunks[#dumpChunks+1] = chunk
	end
	
	for i=1, bankSize, chunkSize do
		addChunk(bankData:sub(i, i+chunkSize-1))
	end
	
	addChunk(patch)
	
	currentChunk = table.remove(dumpChunks, 1)
	flashPosition = 1
	ignoreFirstByte = true
	ignoreSecondByte = true
end)

--[[local downloadCounter = 1

plugin.registerSerialState("spd_download", function(byte)
	if downloadCounter <= #program then
		local r = program:byte(downloadCounter)
		downloadCounter = downloadCounter+1
		return r
	else
		downloadCounter = 1
		jumpSerialState "spd_patch"

		return 0xFD
	end
end, function() -- onEnter
	downloadCounter = 1
end)

plugin.registerSerialState("spd_patch", function(byte)
	if downloadCounter <= #patch then
		local r = patch:byte(downloadCounter)
		downloadCounter = downloadCounter+1

		if downloadCounter > #patch then
			popSerialState()
		end

		return r
	else
		popSerialState()
		return byte
	end
end)]]
