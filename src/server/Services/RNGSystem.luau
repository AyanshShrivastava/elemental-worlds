--!strict
--[[
    Elemental Worlds: RNG & Element Spin System
    Controls element spinning with exact rate enforcement:
    Fire: 19.96%, Aqua: 19.96%, Earth: 19.96%, Light: 19.96%, Wind: 19.96%, Error: 0.10%, Time: 0.10%.
    Tracks the first 5,000 secret allocations atomically.
    Owner-only test controls and global roll broadcasts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

type ElementType = GameConfig.ElementType

local RNGSystem = {}

-- Secret allocation counter
local secretAllocationCount = 0
local SecretAllocationStore: DataStore? = nil
pcall(function()
    SecretAllocationStore = DataStoreService:GetDataStore("ElementalWorlds_SecretClaims_v1")
    if SecretAllocationStore then
        local count = SecretAllocationStore:GetAsync("GlobalClaimCount")
        if count and type(count) == "number" then
            secretAllocationCount = count
        end
    end
end)

-- Current active rates (Can only be modified by Owner)
local currentRates: { [ElementType]: number } = {
    Fire = 0.1996,
    Aqua = 0.1996,
    Earth = 0.1996,
    Light = 0.1996,
    Wind = 0.1996,
    Error = 0.0010,
    Time = 0.0010,
}

-- Broadcast global announcement to all connected clients
local function BroadcastAnnouncement(message: string)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local announceEvent = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
        if announceEvent then
            announceEvent:FireAllClients(message)
        end
    end
end

-- Checks and grants the one-time secret allocation if eligible
function RNGSystem.TryClaimSecretAllocation(player: Player): ElementType?
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return nil end

    -- Check if player already claimed or if cap reached
    if profile.ClaimedSecretAllocation or secretAllocationCount >= GameConfig.SECRET_ALLOCATION_MAX_PLAYERS then
        return nil
    end

    -- Atomic increment in DataStore
    if SecretAllocationStore then
        local success, newCount = pcall(function()
            return SecretAllocationStore:IncrementAsync("GlobalClaimCount", 1)
        end)
        if success and newCount then
            secretAllocationCount = newCount
            if secretAllocationCount > GameConfig.SECRET_ALLOCATION_MAX_PLAYERS then
                return nil -- Cap reached in parallel
            end
        end
    else
        secretAllocationCount += 1
    end

    -- 50/50 between Error and Time
    local roll = math.random()
    local secretElement: ElementType = if roll < 0.5 then "Error" else "Time"

    profile.ClaimedSecretAllocation = true
    PlayerDataService.SetElement(player, secretElement)
    PlayerDataService.SaveProfile(player)

    BroadcastAnnouncement(string.format("[SPECIAL ALLOCATION] [%s] received %s (Slot #%d/%d)!", player.Name, string.upper(secretElement), secretAllocationCount, GameConfig.SECRET_ALLOCATION_MAX_PLAYERS))
    return secretElement
end

-- Standard element roll using server RNG
function RNGSystem.RollElement(player: Player): ElementType
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return "Fire" end

    -- Check if eligible for first 5,000 secret allocation first
    local secretResult = RNGSystem.TryClaimSecretAllocation(player)
    if secretResult then
        return secretResult
    end

    -- Normal RNG Spin (0.0 to 1.0)
    local roll = math.random()
    local cumulative = 0.0
    local chosenElement: ElementType = "Fire"

    local elements: { ElementType } = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
    for _, elem in elements do
        cumulative += currentRates[elem]
        if roll <= cumulative then
            chosenElement = elem
            break
        end
    end

    -- Update player profile
    PlayerDataService.SetElement(player, chosenElement)
    PlayerDataService.SaveProfile(player)

    -- Announce secret roll globally if Error or Time was rolled naturally
    if chosenElement == "Error" or chosenElement == "Time" then
        BroadcastAnnouncement(string.format("[%s] rolled %s!", player.Name, string.upper(chosenElement)))
    end

    return chosenElement
end

-- OWNER-ONLY: Override rates for testing
function RNGSystem.SetRates(ownerPlayer: Player, newRates: { [ElementType]: number }): boolean
    if ownerPlayer.UserId ~= GameConfig.OWNER_USER_ID then
        return false -- Only owner can modify RNG
    end

    for elem, rate in newRates do
        if currentRates[elem] ~= nil then
            currentRates[elem] = rate
        end
    end
    return true
end

-- OWNER-ONLY: Reset rates to default
function RNGSystem.ResetRates(ownerPlayer: Player): boolean
    if ownerPlayer.UserId ~= GameConfig.OWNER_USER_ID then
        return false
    end

    for elem, rate in GameConfig.SPIN_RATES do
        currentRates[elem] = rate
    end
    return true
end

-- OWNER-ONLY: Test simulate N spins
function RNGSystem.SimulateSpins(ownerPlayer: Player, count: number): { [ElementType]: number }?
    if ownerPlayer.UserId ~= GameConfig.OWNER_USER_ID then
        return nil
    end

    local counts: { [ElementType]: number } = {
        Fire = 0, Aqua = 0, Earth = 0, Light = 0, Wind = 0, Error = 0, Time = 0
    }

    local elements: { ElementType } = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
    for _ = 1, count do
        local roll = math.random()
        local cum = 0.0
        for _, elem in elements do
            cum += currentRates[elem]
            if roll <= cum then
                counts[elem] += 1
                break
            end
        end
    end

    return counts
end

return table.freeze(RNGSystem)
