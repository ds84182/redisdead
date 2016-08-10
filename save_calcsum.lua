local save, option = ...

local saveFile = io.open(save, "rb+")

local checksumRegions = {
	{name = "savedata", bank = 1, first = 0x598, last = 0x1522, sum = 0x1523},
	
	--{name = "box0", bank = 2, first = 0x000, last = 0x425, sum = 0x1a4d},
}

for _, checksum in pairs(checksumRegions) do
	print("Region "..checksum.name..":")
	saveFile:seek("set", checksum.first+(checksum.bank*0x2000))
	local data = saveFile:read(checksum.last-checksum.first+1)
	
	local computedChecksum = 255
	for i=1, #data do
		computedChecksum = computedChecksum-data:byte(i)
	end
	computedChecksum = computedChecksum%256
	
	print(("\tComputed Checksum: %02X"):format(computedChecksum))
	
	saveFile:seek("set", checksum.sum+(checksum.bank*0x2000))
	local actualChecksum = saveFile:read(1):byte()
	print(("\tActual Checksum: %02X"):format(actualChecksum))
	
	print(("\tChecksum %s!"):format(computedChecksum == actualChecksum and "OK" or "BAD"))
	
	if option == "fix" and computedChecksum ~= actualChecksum then
		print("\tFixing checksum...")
		saveFile:seek("set", checksum.sum+(checksum.bank*0x2000))
		saveFile:write(string.char(computedChecksum))
	end
	
	print()
end

saveFile:close()
