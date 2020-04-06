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

local function register_character_name(context, payload)
	local object_ids = {
		{
			collection = "global_data",
			key = "names",
			user_id = nil
		}
	}
	
	local name = payload
	
	local objects = nk.storage_read(object_ids)
	local names
	
	for _, object in ipairs(objects) do
		names = objects.value
		if names ~= nil then
			break
		end
	end
	
	if names ~= nil then
		for _, current_name in ipairs(names) do
			if current_name == name then
				return "-1"
			end
		end
		
		table.insert(names, name)
	else
		names = { name }
	end
	
	local new_objects = {
		{
			collection = "global_data",
			key = "names",
			user_id = nil,
			value = names
		}
	}
		
	nk.storage_write(new_objects)
	
	return "0"
end

local function remove_character_name(context, payload)
	local object_ids = {
		{
			collection = "global_data",
			key = "names",
			user_id = nil,
		}
	}
	
	local name = payload
	
	local objects = nk.storage_read(object_ids)
	local names
	
	for _, object in ipairs(objects) do
		names = objects.value
		if names ~= nil then
			break
		end
	end
	
	if names ~= nil then
		local idx
		for k, current_name in ipairs(names) do
			if current_name == name then
				idx = k
				break
			end
		end
		
		if idx == nil then
			return "-1"
		end
		
		table.remove(names, idx)
	end
	
	local new_objects = {
		{
			collection = "global_data",
			key = "names",
			user_id = nil,
			value = names
		}
	}
	
	nk.storage_write(new_objects)
	
	return "0"
end

--- Returns the ID of the world match so users can join it
local function get_world_id(context, payload)
	return get_first_world()
end

nk.register_rpc(get_world_id, "get_world_id")
nk.register_rpc(register_character_name, "register_character_name")
nk.register_rpc(remove_character_name, "remove_character_name")
