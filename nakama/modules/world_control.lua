--- Module that controls the main world. Updated every tick rate using match_loop

local world_control = {}

local nk = require("nakama")

--- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {
    update_position = 1,
    update_input = 2,
    update_state = 3,
    update_jump = 4,
    do_spawn = 5,
    update_color = 6,
    initial_state = 7
}

--- Command pattern table for boiler plate updates that uses data and state.
local commands = {}

--- Updates the position in the game state
commands[OpCodes.update_position] = function(data, state)
    local id = data.id
    local position = data.pos
    if state.positions[id] ~= nil then
        state.positions[id] = position
    end
end

--- Updates the horizontal input direction in the game state
commands[OpCodes.update_input] = function(data, state)
    local id = data.id
    local input = data.inp
    if state.inputs[id] ~= nil then
        state.inputs[id].dir = input
    end
end

--- Updates whether a character jumped in the game state
commands[OpCodes.update_jump] = function(data, state)
    local id = data.id
    if state.inputs[id] ~= nil then
        state.inputs[id].jmp = 1
    end
end

--- Updates the character color in the game state once the player's picked a character
commands[OpCodes.do_spawn] = function(data, state)
    local id = data.id
    local color = data.col
    if state.colors[id] ~= nil then
        state.colors[id] = color
    end
end

--- Updates the character color in the game state after a player's changed colors
commands[OpCodes.update_color] = function(data, state)
    local id = data.id
    local color = data.col
    if state.colors[id] ~= nil then
        state.colors[id] = color
    end
end

local spawn_height = 463.15
local world_width = 1500

function world_control.match_init(_, _)
    local gamestate = {
        presences = {},
        inputs = {},
        positions = {},
        jumps = {},
        colors = {},
        names = {}
    }
    local tickrate = 10
    local label = "Social world"
    return gamestate, tickrate, label
end

function world_control.match_join_attempt(_, _, _, state, presence, _)
    if state.presences[presence.user_id] ~= nil then
        return state, false, "User already logged in."
    end
    return state, true
end

function world_control.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = presence

        state.positions[presence.user_id] = {
            ["x"] = 0,
            ["y"] = 0
        }

        state.inputs[presence.user_id] = {
            ["dir"] = 0,
            ["jmp"] = 0
        }

        state.colors[presence.user_id] = "1,1,1,1"

        state.names[presence.user_id] = "User"

    end

    return state
end

function world_control.match_leave(_, _, _, state, presences)
    for _, presence in ipairs(presences) do
        local new_objects = {
            {
                collection = "player_data",
                key = "position_" .. state.names[presence.user_id],
                user_id = presence.user_id,
                value = state.positions[presence.user_id]
            }
        }
        nk.storage_write(new_objects)

        state.presences[presence.user_id] = nil
        state.positions[presence.user_id] = nil
        state.inputs[presence.user_id] = nil
        state.jumps[presence.user_id] = nil
        state.colors[presence.user_id] = nil
        state.names[presence.user_id] = nil
    end
    return state
end

function world_control.match_loop(_, dispatcher, _, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code
        if op_code < OpCodes.initial_state then
            local decoded = nk.json_decode(message.data)
            commands[op_code](decoded, state)

            if op_code == OpCodes.do_spawn then
                local object_ids = {
                    {
                        collection = "player_data",
                        key = "position_" .. decoded.nm,
                        user_id = message.sender.user_id
                    }
                }

                local objects = nk.storage_read(object_ids)

                local position
                for _, object in ipairs(objects) do
                    position = object.value
                    if position ~= nil then
                        state.positions[message.sender.user_id] = position
                        break
                    end
                end

                if position == nil then
                    state.positions[message.sender.user_id] = {
                        ["x"] = (math.random()*2-1)*world_width,
                        ["y"] = spawn_height
                    }
                end

                state.names[message.sender.user_id] = decoded.nm

                local data = {
                    ["pos"] = state.positions,
                    ["inp"] = state.inputs,
                    ["col"] = state.colors,
                    ["nms"] = state.names
                }

                local encoded = nk.json_encode(data)
                dispatcher.broadcast_message(OpCodes.initial_state, encoded, {message.sender})

                dispatcher.broadcast_message(OpCodes.do_spawn, message.data)
            elseif op_code == OpCodes.update_color then
                dispatcher.broadcast_message(OpCodes.update_color, message.data)
            end
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

function world_control.match_terminate(_, _, _, state, _)
    local new_objects = {}
    for k, position in pairs(state.positions) do
        table.insert(new_objects, {
            collection = "player_data",
            key = "position_" .. state.names[k],
            user_id = k,
            value = position
        })
    end

    nk.storage_write(new_objects)

    return state
end

return world_control
