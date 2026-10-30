--!strict
--[[
    Elemental Worlds: Player Data Service
    Server-authoritative player state, level scaling, charges, and persistence.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

export type PlayerProfile = {
    UserId: number,
    Level: number,
    Charges: number,
    Element: GameConfig.ElementType,
    ErrorMeter: number, -- 0 to 100
    ClaimedSecretAllocation: boolean,
}

local PlayerDataService = {}
local profiles: { [number]: PlayerProfile } = {}

-- Safe DataStore instantiation
local PlayerDataStore: DataStore? = nil
pcall(function()
    PlayerDataStore = DataStoreService:GetDataStore("ElementalWorlds_PlayerData_v1")
end)

local DEFAULT_PROFILE: PlayerProfile = {
    UserId = 0,
    Level = 1,
    Charges = 0,
    Element = "Fire",
    ErrorMeter = 0,
    ClaimedSecretAllocation = false,
}

-- Load or create profile
function PlayerDataService.LoadProfile(player: Player): PlayerProfile
    local userId = player.UserId
    if profiles[userId] then
        return profiles[userId]
    end

    local loadedData: PlayerProfile? = nil
    if PlayerDataStore then
        local success, data = pcall(function()
            return PlayerDataStore:GetAsync("User_" .. tostring(userId))
        end)
        if success and data and type(data) == "table" then
            loadedData = data
        end
    end

    local profile: PlayerProfile = {
        UserId = userId,
        Level = (loadedData and loadedData.Level) or DEFAULT_PROFILE.Level,
        Charges = (loadedData and loadedData.Charges) or DEFAULT_PROFILE.Charges,
        Element = (loadedData and loadedData.Element) or DEFAULT_PROFILE.Element,
        ErrorMeter = 0, -- Resets on join
        ClaimedSecretAllocation = (loadedData and loadedData.ClaimedSecretAllocation) or false,
    }

    profiles[userId] = profile

    -- Sync stats to character health
    PlayerDataService.ApplyLevelHealth(player)

    return profile
end

-- Save player profile to DataStore
function PlayerDataService.SaveProfile(player: Player)
    local userId = player.UserId
    local profile = profiles[userId]
    if not profile or not PlayerDataStore then
        return
    end

    local dataToSave = {
        Level = profile.Level,
        Charges = profile.Charges,
        Element = profile.Element,
        ClaimedSecretAllocation = profile.ClaimedSecretAllocation,
    }

    pcall(function()
        PlayerDataStore:SetAsync("User_" .. tostring(userId), dataToSave)
    end)
end

function PlayerDataService.GetProfile(player: Player): PlayerProfile?
    return profiles[player.UserId]
end

-- Update MaxHealth and current Health based on level: Base 100 + 10*(Level-1)
function PlayerDataService.ApplyLevelHealth(player: Player)
    local profile = profiles[player.UserId]
    if not profile then return end

    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local maxHp = GameConfig.GetMaxHealth(profile.Level)
        humanoid.MaxHealth = maxHp
        humanoid.Health = math.min(humanoid.Health, maxHp)
    end
end

-- Set Level safely
function PlayerDataService.SetLevel(player: Player, newLevel: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Level = math.clamp(newLevel, 1, GameConfig.MAX_LEVEL)
    PlayerDataService.ApplyLevelHealth(player)
    PlayerDataService.SyncClient(player)
end

-- Add Level safely
function PlayerDataService.AddLevel(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end
    PlayerDataService.SetLevel(player, profile.Level + amount)
end

-- Set Charges safely (capped at 10,000)
function PlayerDataService.SetCharges(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Charges = math.clamp(amount, 0, GameConfig.MAX_CHARGES)
    PlayerDataService.SyncClient(player)
end

-- Add Charges safely
function PlayerDataService.AddCharges(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end
    PlayerDataService.SetCharges(player, profile.Charges + amount)
end

-- Set Equipped Element
function PlayerDataService.SetElement(player: Player, element: GameConfig.ElementType)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Element = element
    profile.ErrorMeter = 0 -- Reset error meter when switching elements
    PlayerDataService.SyncClient(player)
end

-- Add or set Error Meter (0 to 100)
function PlayerDataService.AddErrorMeter(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile or profile.Element ~= "Error" then return end

    profile.ErrorMeter = math.clamp(profile.ErrorMeter + amount, 0, 100)
    PlayerDataService.SyncClient(player)
end

-- Send stats to player's client HUD
function PlayerDataService.SyncClient(player: Player)
    local profile = profiles[player.UserId]
    if not profile then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local updateStatsEvent = remotes:FindFirstChild(GameConfig.REMOTES.UPDATE_STATS) :: RemoteEvent?
        if updateStatsEvent then
            updateStatsEvent:FireClient(player, {
                Level = profile.Level,
                Charges = profile.Charges,
                Element = profile.Element,
                ErrorMeter = profile.ErrorMeter,
                MaxHealth = GameConfig.GetMaxHealth(profile.Level),
            })
        end
    end
end

-- Cleanup on player leave
function PlayerDataService.RemoveProfile(player: Player)
    PlayerDataService.SaveProfile(player)
    profiles[player.UserId] = nil
end

return table.freeze(PlayerDataService)
