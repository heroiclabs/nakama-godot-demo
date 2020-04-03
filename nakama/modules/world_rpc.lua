--- Defines RPC commands and builds the initial match that contains the world.
-- @script world_rpc

local nk = require("nakama")

local function get_first_world()
	local matches = nk.match_list()
	local current_match = matches[1]

	if current_match == nil then
		return nk.match_create("world_control", {})
	else
		return current_match.match_id
	end
end

--- Returns the ID of the world match so users can join it
local function get_world_id(context, payload)
	return get_first_world()
end

nk.register_rpc(get_world_id, "get_world_id")
