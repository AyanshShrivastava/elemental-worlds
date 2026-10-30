--!strict
--[[
    Elemental Worlds: Cooldown Service
    Server-authoritative cooldown management per player per ability slot.
]]

local CooldownService = {}

-- Map of [UserId][Slot] = ExpiryTimestamp (os.clock())
local activeCooldowns: { [number]: { [string]: number } } = {}

function CooldownService.IsOnCooldown(player: Player, slot: string): (boolean, number)
    local userCooldowns = activeCooldowns[player.UserId]
    if not userCooldowns then
        return false, 0
    end

    local expiryTime = userCooldowns[slot]
    if not expiryTime then
        return false, 0
    end

    local currentTime = os.clock()
    if currentTime < expiryTime then
        return true, expiryTime - currentTime
    end

    -- Expired
    userCooldowns[slot] = nil
    return false, 0
end

function CooldownService.StartCooldown(player: Player, slot: string, durationSeconds: number)
    local userId = player.UserId
    if not activeCooldowns[userId] then
        activeCooldowns[userId] = {}
    end

    activeCooldowns[userId][slot] = os.clock() + durationSeconds
end

function CooldownService.ResetCooldown(player: Player, slot: string)
    local userCooldowns = activeCooldowns[player.UserId]
    if userCooldowns then
        userCooldowns[slot] = nil
    end
end

function CooldownService.ClearPlayer(player: Player)
    activeCooldowns[player.UserId] = nil
end

return table.freeze(CooldownService)
