-- Module that controls the game world. The world's state is updated every `tickrate` in the
-- `match_loop()` function.

local world_control = {}

local nk = require("nakama")

function world_control.match_init(context, params)
    local state = {
        presences = {}
    }
    local tick_rate = 10
    local label = "Game world"

    return state, tick_rate, label
end

function world_control.match_join(context, dispatcher, tick, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = presence
    end
    return state
end

function world_control.match_leave(context, dispatcher, tick, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = nil
    end
    return state
end

function world_control.match_loop(context, dispatcher, tick, state, messages)
    return state
end

function world_control.match_terminate(context, dispatcher, tick, state, grace_seconds)
    return state
end

function world_control.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    if state.presences ~= nil and state.presences[presence.user_id] ~= nil then
        return state, false, "User already logged in."
    end
    return state, true
end

return world_control
