--flash.lua: flashes the save file with the new payload
local savefile, bin = ... --TODO: More universal flash method

os.execute("cp "..savefile.." "..savefile..".bak")

local file = io.open(savefile, "rb+")
local binFile = io.open(bin, "rb")

file:seek("set", 0x2000*3)
file:write(binFile:read("*a"))

file:close()
binFile:close()

--update checksum

os.execute("lua ../save_calcsum.lua "..savefile.." fix")
