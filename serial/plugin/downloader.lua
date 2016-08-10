local plugin = ...

-- config defaults
config.download_binary = config.download_binary or "hello_sample/hello.bin"

local program = nil
local patch = nil

local function loadProgram()
	local fil = io.open(config.download_binary, "rb")
	program = fil:read("*a")
	fil:close()
	
	local patchBytes = {}
	program = program:gsub("()\254", function(index)
		local addr = index-1+0xDA00 --TODO: Ability to specify program base
		
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
	
	patch = table.concat(patchBytes)
	
	print(patch:gsub(".", function(c)
		return string.format("%02X", c:byte())
	end))
	
	local s, e = patch:find("\254")
	if s then
		error("Patch is broken!")
	end
end

plugin.registerSerialState("protocol_50", nil, function() -- onEnter
	print("SPDServer started!")
	
	loadProgram()
	
	jumpSerialState "spd_command"
end).version = 0x02

plugin.registerSerialState("spd_command", function(byte)
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
		jumpSerialState "spd_download"
		return 0xFD
	elseif byte == 0x05 then
		--send msb
		print "Got patch list length MSB"
		return (#patch)>>8
	elseif byte == 0x06 then
		--send lsb
		print "Got patch list length LSB"
		return (#patch)&0xFF
	end
	
	--TODO: handleGlobalSerialCommand
	
	return byte
end)

local downloadCounter = 1

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
end)
