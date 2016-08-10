local fileName = ...
local file = io.open(fileName, "rb")

local JUMP_TABLE_TABLE = 0x3140

file:seek("set", JUMP_TABLE_TABLE)
local jumpID = 0

local ROM_TARGETS = {}

while jumpID <= 0x7F do
	local ab = file:read(2)
	if not ab then break end
	local target = string.unpack("<I2", ab)
	
	if target >= 0xD000 and target <= 0xDFFF then
		--print(string.format("WRAM TARGET, ID: %02X ADDR: %04X", jumpID, target))
	elseif target >= 0xA000 and target <= 0xBFFF then
		--print(string.format("SRAM TARGET, ID: %02X ADDR: %04X", jumpID, target))
	elseif target >= 0x4000 and target <= 0x8FFF then
		print(string.format("ROMX TARGET, ID: %02X ADDR: %04X", jumpID, target))
		ROM_TARGETS[#ROM_TARGETS+1] = {jumpID, target}
	end
	
	jumpID = jumpID+1
end

local GLORY = 0xDB3E --glory address

for _, target in pairs(ROM_TARGETS) do
	--look in the first 16 rom banks for good targets--
	for bank = 0, 16 do
		file:seek("set", target[2]+(bank*0x4000))
		local jumpID = 0

		while jumpID <= 0x7F do
			local ab = file:read(2)
			if not ab then break end
			local addr = string.unpack("<I2", ab)
	
			if addr >= 0xD000 and addr <= 0xDFFF then
				print(string.format("WRAM TARGET, ID: %02X ADDR: %04X TABLE: %02X BANK: %02X (%04X)", jumpID, addr, target[1], bank+1, target[2]+(bank*0x4000)+(jumpID*2)))
				
				if addr == GLORY then
					print("Go home everyone... We've struck gold.")
					os.exit()
				end
			end
	
			jumpID = jumpID+1
		end
	end
end
