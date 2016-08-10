local bgb = require "bgb"

local filename = ...
assert(filename, "File not given!")

-- Thank you vaguilar for all your hard work <3
local data = {
	-- random seed
	182, 147, 113, 81, 51, 23, 228, 205, 184, 165,
	
	-- preamble
	253, 253, 253, 253, 253, 253, 253, 253,
	
	-- party data
	248, 0, 54, 253, 1, 62, 88, 197, 195, 0xd6, 0xc5,
	6, 21, 21, 21, 21, 21, 21, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	0xC3, 0xD6, 0xC5, -- Jump to patch list!
	227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	227, 227, 227, 227, 227, 227, 227, 227, 227, 227, 227,
	244, -- this jumps to IsItemInBag
	227, 227, 255, 33, 160, 195, 1, 136, 1, 62, 0,
	205, 224, 54, 17, 24, 218, 33, 89, 196, 205, 85, 25,
	195, 21, 218, 139, 142, 128, 131, 136, 141, 134, 232,
	232, 232, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 64,
	0, 0,
	
	-- preamble
	253, 253, 253, 253, 253,
	
	-- patch list (196 bytes total, 194 bytes available)
	255, 255
}

-- load the downloader program into the data binary
local fil = io.open("downloader/downloader.bin", "rb")
local downloader = fil:read(194)
fil:close()
if #downloader < 194 then
	downloader = downloader..("0"):rep(194-#downloader)
end
for i=1, 194 do
	data[#data+1] = downloader:byte(i)
end

-- then load the actual binary into memory
local fil = io.open(filename, "rb")
local program = fil:read("*a")
fil:close()

-- state

local currentState
local state = {}

setmetatable(state, {__call=function(_, nextState)
	print("Entering state "..nextState)
	currentState = nextState
end})

state "establish"

function state.establish(byte)
	if byte == 1 then
		print "Connection established!"
		state "acknowledge"
		return 2
	end
end

function state.acknowledge(byte)
	if byte == 0 then
		print "Menu"
		state "menu"
	end
	
	return byte
end

function state.menu(byte)
	if byte == 0xd4 then
		print "Trade Center"
		state "trade"
	end
	
	return byte
end

function state.trade(byte)
	if byte == 0xfd then
		state "preamble"
	end
	
	return byte
end

local dataCounter = 1
local function exchangeParties(byte)
	if dataCounter <= #data then
		local r = data[dataCounter]
		dataCounter = dataCounter+1
		return r
	else
		state "done"
	end
	
	return byte
end

function state.preamble(byte)
	if byte ~= 0xfd then
		print "Sending data..."
		state "tradeData"
		return exchangeParties(byte)
	end
	
	return byte
end

state.tradeData = exchangeParties

function state.done(byte)
	if byte == 0x50 then
		print "Downloader started!"
		state "downloader"
		return 0x01 -- downloader version 1
	end
	
	return byte
end

function state.downloader(byte)
	if byte == 0x02 then
		--send msb
		print "Got download length MSB"
		return (#program)>>8
	elseif byte == 0x03 then
		--send lsb
		print "Got download length LSB"
		return (#program)&0xFF
	elseif byte == 0x04 then
		--start download
		print "Beginning Download"
		state "doDownload"
		return 0xFD
	end
	return byte
end

local syncCount = 1
local downloadCounter = 1

local function downloadByte(byte)
	if downloadCounter <= #program then
		local r = program:byte(downloadCounter)
		downloadCounter = downloadCounter+1
		return r
	else
		state "downloadDone"
	end
	
	return byte
end

function state.doDownloadSync(byte)
	if syncCount > 0 then
		syncCount = syncCount-1
		return 0xFD
	else
		state "doDownload"
		return downloadByte(byte)
	end
end

state.doDownload = downloadByte

function state.downloadDone(byte)
	return byte
end

bgb.connect(8765, function(byte)
	local stateCB = state[currentState]
	
	print("Received "..byte)
	
	if stateCB then
		local send = stateCB(byte) or 0
		print("Send "..send)
		return send
	else
		error("Unknown state "..currentState)
	end
end)
