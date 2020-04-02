--- Module that controls the main world. Any non-doc'ed functions to be only called internally by Nakama
-- @module world_control
local world_control = {}
local nk = require("nakama")
local OpCodes = {
	update_position = 1,
	request_position = 2,
	update_input = 3
}
local spawn_height = 463.15
local world_width = 1500

function world_control.match_init(context, setupstate)
	local gamestate = {
		presences = {},
		positions = {}
	}
	local tickrate = 5
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
		
		local pos = {(math.random()*2-1)*world_width, spawn_height}
		
		local data = {["id"] = presence.user_id, ["pos"]= pos}
		state.positions[presence.user_id] = pos
		local encoded = nk.json_encode(data)
		
		dispatcher.broadcast_message(OpCodes.update_position, encoded, {presence})
	end
	
	return state
end

function world_control.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.user_id] = nil
		state.positions[presence.user_id] = nil
	end
	return state
end

function world_control.match_loop(context, dispatcher, tick, state, messages)
	for _, message in ipairs(messages) do
		local op_code = message.op_code
		if op_code == OpCodes.request_position then
			local decoded = nk.json_decode(message.data)
			local id = decoded.id
			
			local pos = {0, 0}
			
			if state.positions[id] ~= nil then
				pos = state.positions[id]
			end
			
			local data = {["id"]= id, ["pos"]= pos}
			local encoded = nk.json_encode(data)
			
			dispatcher.broadcast_message(OpCodes.update_position, encoded, {message.sender})
		elseif op_code == OpCodes.update_position then
			local decoded = nk.json_decode(message.data)
			local id = decoded.id
			
			state.positions[id] = decoded.pos
			
			dispatcher.broadcast_message(OpCodes.update_position, message.data)
		end
	end
	return state
end

function world_control.match_terminate(context, dispatcher, tick, state, grace_seconds)
	return state
end

return world_control
