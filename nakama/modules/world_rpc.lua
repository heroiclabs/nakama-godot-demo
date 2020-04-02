--- Defines RPC commands and builds the initial match that contains the world.
-- @script world_rpc

local nk = require("nakama")

local function get_first_world()
	local world_id = nil
	
	local matches = nk.match_list()
	for _, match in ipairs(matches) do
		world_id = match.match_id
		break
	end
	
	if world_id == nil then
		world_id = nk.match_create("world_control", {})
	end
	
	return world_id
end

local world_id = get_first_world()

--- Returns the ID of the world match so users can join it
local function get_world_id(context, payload)
	return world_id
end

nk.register_rpc(get_world_id, "get_world_id")
