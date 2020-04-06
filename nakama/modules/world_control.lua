--- Module that controls the main world. Any non-doc'ed functions to be called internally by Nakama
-- @module world_control

local world_control = {}

local nk = require("nakama")
local OpCodes = {
	update_position = 1,
	update_input = 2,
	update_state = 3,
	update_jump = 4,
	update_color = 5
}

local commands = {}
commands[OpCodes.update_position] = function(data, state)
	local id = data.id
	local position = data.pos
	if state.positions[id] ~= nil then
		state.positions[id] = position
	end
end

commands[OpCodes.update_input] = function(data, state)
	local id = data.id
	local input = data.inp
	if state.inputs[id] ~= nil then
		state.inputs[id].dir = input
	end
end

commands[OpCodes.update_jump] = function(data, state)
	local id = data.id
	if state.inputs[id] ~= nil then
		state.inputs[id].jmp = 1
	end
end

local spawn_height = 463.15
local world_width = 1500

function world_control.match_init(context, setupstate)
	local gamestate = {
		presences = {},
		inputs = {},
		positions = {},
		jumps = {}
	}
	local tickrate = 10
	local label = "Social world"
	return gamestate, tickrate, label
end

function world_control.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	if state.presences[presence.user_id] ~= nil then
		return state, false, "User already logged in."
	end
	return state, true
end

function world_control.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.user_id] = presence

		local object_ids = {
			{
				collection = "player_data",
				key = "position",
				user_id = presence.user_id
			}
		}

		local objects = nk.storage_read(object_ids)
		local pos = nil
		for _, object in ipairs(objects) do
			pos = object.value
			if pos ~= nil then
				break
			end
		end

		if pos == nil then
			pos = {
				["x"] = (math.random()*2-1)*world_width,
				["y"] = spawn_height
			}
		end

		state.positions[presence.user_id] = pos

		state.inputs[presence.user_id] = {
			["dir"] = 0,
			["jmp"] = 0
		}

		local data = {
			["pos"] = state.positions,
			["inp"] = state.inputs
		}
		local encoded = nk.json_encode(data)

		dispatcher.broadcast_message(OpCodes.update_state, encoded, {presence})
	end

	return state
end

function world_control.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		local new_objects = {
			{
				collection = "player_data",
				key = "position",
				user_id = presence.user_id,
				value = state.positions[presence.user_id]
			}
		}
		nk.storage_write(new_objects)

		state.presences[presence.user_id] = nil
		state.positions[presence.user_id] = nil
		state.inputs[presence.user_id] = nil
	end
	return state
end

function world_control.match_loop(context, dispatcher, tick, state, messages)
	for _, message in ipairs(messages) do
		local op_code = message.op_code
		if op_code < OpCodes.update_color then
			local decoded = nk.json_decode(message.data)
			commands[op_code](decoded, state)
		elseif op_code == OpCodes.update_color then
			dispatcher.broadcast_message(OpCodes.update_color, message.data)
		end
	end

	local data = {
		["pos"] = state.positions,
		["inp"] = state.inputs
	}
	local encoded = nk.json_encode(data)

	dispatcher.broadcast_message(OpCodes.update_state, encoded)

	for _, input in pairs(state.inputs) do
		input.jmp = 0
	end

	return state
end

function world_control.match_terminate(context, dispatcher, tick, state, grace_seconds)
	local new_objects = {}
	for k, position in pairs(state.positions) do
		table.insert(new_objects, {
			collection = "player_data",
			key = "position",
			user_id = k,
			value = position
		})
	end

	nk.storage_write(new_objects)

	return state
end

return world_control
