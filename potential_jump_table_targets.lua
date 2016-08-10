local fileName, addr = ...
addr = tostring(addr, 16)
local file = io.open(fileName, "rb")
file:seek("set", addr)
local jumpID = 0

while jumpID <= 0x7F do
	local ab = file:read(2)
	if not ab then break end
	local target = string.unpack("<I2", ab)
	
	if target > 0xD000 and target <= 0xDFFF then
		print(string.format("WRAM TARGET, ID: %02X ADDR: %04X", jumpID, target))
	elseif target > 0xA000 and target <= 0xBFFF then
		print(string.format("SRAM TARGET, ID: %02X ADDR: %04X", jumpID, target))
	end
	
	jumpID = jumpID+1
end
