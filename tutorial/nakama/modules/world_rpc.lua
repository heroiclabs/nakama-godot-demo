-- Defines remote procedures accessible for clients to call to get information before joining the
-- game world.

local nakama = require("nakama")

-- Returns the first existing match in namaka's match list or creates one if there is none.
local function get_world_id(_, _)
    local matches = nakama.match_list()
    local current_match = matches[1]

    if current_match == nil then
        return nakama.match_create("world_control", {})
    else
        return current_match.match_id
    end
end

-- RPC registered to Nakama
nakama.register_rpc(get_world_id, "get_world_id")
