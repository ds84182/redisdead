local bgb = require "bgb"
local readline = require "readline"

config = {}

commands = {}
serialStates = {}
serialStateStack = {}
currentSerialState = nil

local function addSerialState(name, onByte, onEnter, onLeave, onSuspend, onResume)
	serialStates[name] = {
		onByte = onByte,
		onEnter = onEnter,
		onLeave = onLeave,
		onSuspend = onSuspend,
		onResume = onResume
	}

	return serialStates[name]
end

function executeSerialState(byte)
	local state = serialStates[currentSerialState]

	if state then
		return state.onByte and state.onByte(byte) or 0
	else
		error("Unknown state "..tostring(currentSerialState))
	end
end

function jumpSerialState(new)
	local state = serialStates[currentSerialState]
	if state.onLeave then state.onLeave(new) end

	local prev = currentSerialState
	currentSerialState = new

	state = serialStates[currentSerialState]
	print("Entered "..currentSerialState)
	if state.onEnter then state.onEnter(prev) end
end

function pushSerialState(new)
	local state = serialStates[currentSerialState]
	if state.onSuspend then state.onSuspend(new) end

	local prev = currentSerialState
	serialStateStack[#serialStateStack+1] = prev
	currentSerialState = new

	state = serialStates[currentSerialState]
	print("Entered "..currentSerialState)
	if state.onEnter then state.onEnter(prev) end
end

function popSerialState()
	local back = table.remove(serialStateStack)

	if not back then return false end

	local state = serialStates[currentSerialState]
	if state.onLeave then state.onLeave(back) end

	local prev = currentSerialState
	currentSerialState = back

	state = serialStates[currentSerialState]
	print("Resumed "..currentSerialState)
	if state.onResume then state.onResume(prev) end

	return true
end

require "plugins"

plugins.load "pokemon"
plugins.load "remote_code_execution"
plugins.load "downloader"
plugins.load "sram_flash"

addSerialState("main", function(byte)
	local protocol = string.format("protocol_%02X", byte)
	if serialStates[protocol] then
		pushSerialState(protocol)
		return serialStates[protocol].version or 0 -- send protocol version or 0
	end

	return 255
end)

currentSerialState = "main"

commands.exit = function() os.exit() end
commands.quit = commands.exit
commands.q = commands.exit

function commands.config(key, value)
	if key and value then
		config[key] = value
	elseif key then
		print(key..": "..tostring(config[key]))
	else
		for key, value in pairs(config) do
			print(key..": "..tostring(value))
		end
	end
end

function commands.load(plugin)
	local s, e = plugins.load(plugin)

	if not s then
		print(e)
	else
		print("plugin loaded successfully")
	end
end

function commands.unload(plugin)
	local s, e = plugins.unload(plugin)

	if not s then
		print(e)
	else
		print("plugin unloaded successfully")
	end
end

function commands.reload(plugin)
	local s, e = plugins.unload(plugin)

	if not s then
		print(e)
		return
	end

	local s, e = plugins.load(plugin)

	if not s then
		print(e)
	else
		print("plugin reloaded successfully")
	end
end

function commands.start(port)
	port = tonumber(port) or 8765
	bgb.connect(port, function(byte)
		print("Received "..byte)

		local ret = executeSerialState(byte) or 0

		print("Send "..ret)

		return ret
	end)
end

function commands.goto_state(state)
	pushSerialState(state)
end

while true do
	local cmdline = readline.readline("> ")
	readline.add_history(cmdline)

	local arguments = {}
	for s in cmdline:gmatch("%S+") do
		arguments[#arguments+1] = s
	end
	local command = table.remove(arguments, 1)

	local commandfunc = commands[command]

	if commandfunc then
		local s, e = xpcall(commandfunc, debug.traceback, table.unpack(arguments))

		if not s then
			print(e)
		end
	else
		print("Unknown command "..command)
	end
end
