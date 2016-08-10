local fileName = ...
local file = io.open(fileName, "rb")

local pokemonNameBase = 0x1C21E
local targetByte = 8 --8 and 9 are written into the place we need

file:seek("set", pokemonNameBase)

for i=1, 254 do
	local targetAddress = pokemonNameBase+((i-1)*10)
	local data = file:read(10)
	
	local pos = string.unpack("<I2", data, targetByte)
	
	print(i, string.format("%04X", pos), string.format("%02X", data:byte(10)))
end

-- 192 jumps into Serial interrupt
-- 198 jumps into SaveScreenTilesToBuffer2
-- 208 jumps into IsItemInBag
-- 244 jumps to Delay3 (then to 0xD921 (which is inside the block of name pointers we send (127 E3 element)!!!))
