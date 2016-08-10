--turns a symbol file into defines--

local args = {...}

for line in io.lines(table.remove(args, 1)) do
	local bank, address, name = line:match("(%x%x):(%x%x%x%x) (.+)")
	
	if bank then
		name = name:gsub("%.", "_")
		print(name.." EQU $"..address)
		print(name.."_BANK EQU $"..bank)
	end
end
