local args = {...}

local symbols = {}
--DB3E

for line in io.lines(table.remove(args, 1)) do
	local bank, address, name = line:match("(%x%x):(%x%x%x%x) (.+)")
	
	if bank then
		bank, address = tonumber(bank, 16), tonumber(address, 16)
	
		if not symbols[address] then
			symbols[address] = {[bank] = name}
		else
			symbols[address][bank] = name
		end
	end
end

local function findSymbol(address)
	local lastBank = {}
	local foundSymbolsByBank = {}
	for addr, bankNames in pairs(symbols) do
		for bank, name in ipairs(bankNames) do
			if lastBank[bank] and lastBank[bank] < address and addr > address then
				foundSymbolsByBank[#foundSymbolsByBank+1] = {
					name,
					address-addr
				}
				lastBank[bank] = math.huge
			end
			
			lastBank[bank] = addr
		end
	end
	
	return foundSymbolsByBank
end

local function formatFoundSymbols(found)
	local formatList = {}
	
	for i=1, #found do
		formatList[i] = found[i][1].."+"..found[i][2]
	end
	
	return table.concat(formatList, "\n")
end

local found = findSymbol(0xDB3E)
print(formatFoundSymbols(found))
