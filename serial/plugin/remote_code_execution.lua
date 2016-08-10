local plugin = ...

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
	downloader = downloader..("\0"):rep(194-#downloader)
end
for i=1, 194 do
	data[#data+1] = downloader:byte(i)
end

plugin.registerSerialState("pokemon_trade_center", function(byte) -- onByte
	if byte == 0xfd then
		jumpSerialState "rce_preamble"
	end
	
	return byte
end)

local dataCounter = 1
local function exchangeData(byte)
	if dataCounter <= #data then
		local r = data[dataCounter]
		dataCounter = dataCounter+1
		return r
	else
		print("Data exchange done!")
		popSerialState()
		return byte
	end
end

plugin.registerSerialState("rce_preamble", function(byte) -- onByte
	if byte ~= 0xfd then
		print "Sending data..."
		jumpSerialState "rce_trade_data"
		return exchangeData(byte)
	end
	
	return byte
end, function()
	dataCounter = 1
end)

plugin.registerSerialState("rce_trade_data", exchangeData)
