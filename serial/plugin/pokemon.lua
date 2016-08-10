local plugin = ...

plugin.registerSerialState("protocol_01", nil, function() -- onEnter
	print("Pokemon Protocol started!")
	
	jumpSerialState "pokemon_acknowledge"
end).version = 0x02

plugin.registerSerialState("pokemon_acknowledge", function(byte) -- onByte
	if byte == 0x00 then
		print("Pokemon Protocol acknowledged!")
		
		jumpSerialState "pokemon_menu"
	end
	
	return byte
end)

plugin.registerSerialState("pokemon_menu", function(byte) -- onByte
	if byte == 0xd4 then
		jumpSerialState "pokemon_trade_center" --implemented by another plugin
	elseif byte == 0xd5 then
		jumpSerialState "pokemon_colosseum" --implemented by another plugin
	elseif byte == 0xd6 then
		popSerialState()
	end
	
	return byte
end)
