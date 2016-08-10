local socket = require "socket"

local bgb = {}

local function sendData(sock, b1, b2, b3, b4, time)
	sock:send(string.pack("<BBBBI4", b1, b2, b3, b4, time))
end

local function unpackData(str)
	return string.unpack("<BBBBI4", str)
end

function bgb.connect(port, callback)
	local sock = socket.tcp()
	sock:setoption("tcp-nodelay", true)
	assert(sock:connect("localhost", port))
	
	-- send version
	sendData(sock, 1, 1, 4, 0, 0)
	
	local s, e = pcall(function()
		while true do
			local b1, b2, b3, b4, time = unpackData(assert(sock:receive(8)))
			
			if b1 == 1 then
				-- handshake, unused for now
			elseif b1 == 101 then
				-- sync gamepad
			elseif b1 == 104 then
				-- byte received from master
				local result = callback(b2)
				if result then
					-- send data
					sendData(sock, 105, result, 0x80, 0, 0)
				else
					-- send ack
					sendData(sock, 106, 1, 0, 0, 0)
				end
			elseif b1 == 106 then
				sendData(sock, b1, b2, b3, b4, time)
			elseif b1 == 108 then
				sendData(sock, 108, 1, 0, 0, 0)
			end
		end
	end)
	
	if not s then print(e) end
	
	sock:close()
	
	print("Connection closed.")
end

return bgb
