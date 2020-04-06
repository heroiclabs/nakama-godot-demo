--- Defines remote procedures accessible for clients to call to get non-world information.
-- @script world_rpc

local nk = require("nakama")

local function get_name_collection()
    local object_ids = {
        {
            collection = "global_data",
            key = "names"
        }
    }

    local objects = nk.storage_read(object_ids)

    local names
    for _, object in pairs(objects) do
        names = object.value
        if names ~= nil then
            break
        end
    end

    if names ~= nil then
		return names
    else
        return {["names"]={}}
    end
end

local function write_names(names)
    local new_objects = {
        {
            collection = "global_data",
            key = "names",
            value = {["names"]=names},
            permission_read = 2,
            permission_write = 0
        }
    }

    nk.storage_write(new_objects)
end

-- Register a name inside non-user owned storage that contains all names so far. Returns "0" if the name is already taken. Returns "1" if it's been registered successfully.
local function register_character_name(_, payload)
    local names = get_name_collection().names

    local name = payload

    for _, current_name in ipairs(names) do
        if current_name == name then
            return "0"
        end
    end

    table.insert(names, name)

    write_names(names)

    return "1"
end

local function remove_character_name(_, payload)
    local names = get_name_collection().names

    local name = payload

    local idx
    for k, current_name in ipairs(names) do
        if current_name == name then
            idx = k
            break
        end
    end

    if idx ~= nil then
        table.remove(names, idx)

        write_names(names)
    end

    return "1"
end

-- Finds the ID of the first match in the listings. If no match is found, creates one and returns that.
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
local function get_world_id(_, _)
    return get_first_world()
end

nk.register_rpc(get_world_id, "get_world_id")
nk.register_rpc(register_character_name, "register_character_name")
nk.register_rpc(remove_character_name, "remove_character_name")
