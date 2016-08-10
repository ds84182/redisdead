plugins = {loaded = {}}

function plugins.load(name)
	if plugins.loaded[name] then return false, "plugin already loaded" end

	local func, err = loadfile("plugin/"..name..".lua")

	if not func then
		return false, err
	end

	local plugin = {
		name = name,
		func = func,
		registeredSerialStates = {}
	}

	plugins.loaded[name] = plugin

	function plugin.registerSerialState(name, onByte, onEnter, onLeave, onSuspend, onResume)
		if serialStates[name] then
			error("Serial State "..name.." already exists!")
		end

		plugin.registeredSerialStates[name] = true

		serialStates[name] = {
			plugin = plugin,
			onByte = onByte,
			onEnter = onEnter,
			onLeave = onLeave,
			onSuspend = onSuspend,
			onResume = onResume
		}

		return serialStates[name]
	end

	local s, e = pcall(func, plugin)

	if not s then
		local us, ue = plugins.unload(name)

		if not us then
			return false, e.."\n"..ue
		end

		return false, e
	end

	return true
end

function plugins.unload(name)
	local plugin = plugins.loaded[name]

	if not plugin then return true end

	for state in pairs(plugin.registeredSerialStates) do
		if currentSerialState == state then
			if not popSerialState() then
				currentSerialState = "main"
			end
		end

		local i = 1
		while i <= #serialStateStack do
			if serialStateStack[i] == state then
				table.remove(serialStateStack, i)
			else
				i = i+1
			end
		end
	end

	plugins.loaded[name] = nil

	return true
end
