#!/usr/bin/lua5.3

do
	--The run anywhere bootstrap--
	--Revision 2--

	local function split(a, patt)
		local tab = {}
		for s in a:gmatch("([^"..patt.."]+)") do
			tab[#tab+1] = s
		end
		return tab
	end

	local function absolutePath(a, b)
		if b:sub(1,1) == "/" then return absolutePath(b,"") end
		
		local at = split(a, "/")
		local bt = split(b, "/")
	
		local ct = {}
	
		for i=1, #at do
			local p = at[i] --TODO: Rename at to am, i to d
			if p == ".." then
				ct[#ct] = nil
			elseif p ~= "." then
				ct[#ct+1] = p
			end
		end
	
		for i=1, #bt do
			local p = bt[i] --TODO: Rename bt to bm
			if p == ".." then
				ct[#ct] = nil
			elseif p ~= "." then
				ct[#ct+1] = p
			end
		end
	
		return "/"..table.concat(ct, "/")
	end
	
	local realPath = absolutePath(require "lfs".currentdir(), arg[0].."/..")
	
	package.path = package.path..";"..realPath.."/?.lua"
end

--linkhax: fuck rgblink bullshit

local parser = require "argparse"("linkhax", "Links RGB2 object files together because RGBLINK is terrible")
parser:argument("input"):args "+"
parser:option "-o" "--output"
parser:option "-b" "--base"

local args = parser:parse()
args.base = tonumber(args.base, 16)

local SYM_LOCAL = 0
local SYM_IMPORT = 1
local SYM_EXPORT = 2

local SECT_WRAM0 = 0
local SECT_VRAM = 1
local SECT_ROMX = 2
local SECT_ROM0 = 3
local SECT_HRAM = 4
local SECT_WRAMX = 5
local SECT_SRAM = 6

local PATCH_BYTE = 0
local PATCH_WORD_L = 1
local PATCH_LONG_L = 2
local PATCH_WORD_B = 3
local PATCH_LONG_B = 4

local INT_MAX = 4294967295

local function testRange(ax, ay, bx, by)
	return not (ax >= by or bx >= ay)
end

function loadObject(file)
	local magic = file:read(4)
	assert(magic == "RGB2", "Invalid object file")
	
	local numSyms = string.unpack("<I4", file:read(4))
	local numSec = string.unpack("<I4", file:read(4))
	
	local object = {}
	
	local symbols, sections = {}, {}
	
	object.symbols = symbols
	object.sections = sections
	
	for i=1, numSyms do
		local name = {}
		while true do
			local chr = file:read(1)
			if chr == "\0" then break end
			name[#name+1] = chr
		end
		name = table.concat(name)
		
		local type = file:read(1):byte()
		
		local sym = {name = name, type = type, object = object}
		
		if type ~= SYM_IMPORT then
			sym.sectionID = string.unpack("<I4", file:read(4))
			sym.offset = string.unpack("<I4", file:read(4))
		end
		
		symbols[#symbols+1] = sym
	end
	
	for i=1, numSec do
		local size = string.unpack("<I4", file:read(4))
		local type = file:read(1):byte()
		local org = string.unpack("<I4", file:read(4))
		
		local bank = string.unpack("<I4", file:read(4))
		
		local section = {
			size = size,
			type = type,
			org = org,
			bank = bank,
			object = object
		}
		
		if type == SECT_ROM0 or type == SECT_ROMX then
			section.data = file:read(size)
			section.patches = {}
			
			local numPatch = string.unpack("<I4", file:read(4))
			for i=1, numPatch do
				local name = {}
				while true do
					local chr = file:read(1)
					if chr == "\0" then break end
					name[#name+1] = chr
				end
				name = table.concat(name)
				
				local line = string.unpack("<I4", file:read(4))
				local offset = string.unpack("<I4", file:read(4))
				local type = file:read(1):byte()
				local rpnSize = string.unpack("<I4", file:read(4))
				local rpn = file:read(rpnSize)
				
				section.patches[i] = {
					name = name,
					line = line,
					offset = offset,
					type = type,
					rpnSize = rpnSize,
					rpn = rpn
				}
			end
		end
		
		sections[#sections+1] = section
	end
	
	return object
end

local globalSymbols = {}
local globalSections = {}

--TODO: If section org == INT_MAX, allocate at next avail
--section addr

function addObject(object)
	for i=1, #object.sections do
		local section = object.sections[i]
		
		if not globalSections[section.type] then
			globalSections[section.type] = {}
		end
		
		for i, v in pairs(globalSections[section.type]) do
			if testRange(i, i+v.size, section.org+args.base, section.org+args.base+section.size) then
				error("Sections overlap")
			end
		end
		
		section.org = section.org+args.base
		globalSections[section.type][section.org] = section
	end
	
	for i=1, #object.symbols do
		local sym = object.symbols[i]
		
		if sym.type ~= SYM_IMPORT then
			if globalSymbols[sym.name] then error("Symbol declared twice") end
			globalSymbols[sym.name] = sym
			
			sym.section = object.sections[sym.sectionID+1]
		end
	end
end

--print(require "serpent".block(args))

local obj = loadObject(io.open(args.input[1], "rb"))
--print(require "serpent".block(obj))
addObject(obj)

--print(require "serpent".block(globalSymbols))
--print(require "serpent".block(globalSections))

for addr, section in pairs(globalSections[3]) do
	for _, patch in ipairs(section.patches) do
		local stack = {}
		
		local function readRPN(i)
			local val = patch.rpn:byte(i)
			
			if val == 0x80 then --const
				stack[#stack+1] = string.unpack("<I4", patch.rpn, i+1)
				return i+5
			elseif val == 0x81 then --symbol
				local symid = string.unpack("<I4", patch.rpn, i+1)
				local sym = globalSymbols[section.object.symbols[symid+1].name]
				if not sym then
					error("Symbol "..section.object.symbols[symid+1].name.." undeclared")
				end
				stack[#stack+1] = sym.section.org+sym.offset
				return i+5
			else
				error(val)
			end
		end
		
		local rpnindex = 1
		while rpnindex <= #patch.rpn do
			rpnindex = readRPN(rpnindex)
		end
		
		local value = stack[1]
		local strval
		
		if patch.type == PATCH_BYTE then
			strval = string.char(value%256)
		elseif patch.type == PATCH_WORD_L then
			strval = string.pack("<I2", value)
		elseif patch.type == PATCH_WORD_B then
			strval = string.pack(">I2", value)
		elseif patch.type == PATCH_LONG_L then
			strval = string.pack("<I4", value)
		elseif patch.type == PATCH_LONG_B then
			strval = string.pack(">I4", value)
		end
		
		section.data = section.data:sub(1, patch.offset)..strval..section.data:sub(patch.offset+#strval+1)
	end
end

--now, to export sections

local out = io.open(args.output, "wb")

local allSections = {}
--TODO: This
for i, v in pairs(globalSections[3]) do
	v.org = i
	allSections[#allSections+1] = v
end
table.sort(allSections, function(a, b)
	return a.org < b.org
end)

local currentAddress = args.base

for i=1, #allSections do
	local sec = allSections[i]
	
	out:write(string.rep("\0", sec.org-currentAddress))
	
	out:write(sec.data)
	
	currentAddress = sec.org+sec.size
end

out:close()

print("  Link done, "..(currentAddress-args.base).." bytes") --TODO: Fix
