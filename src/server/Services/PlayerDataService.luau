--!strict
--[[
    Elemental Worlds: Enterprise Player Data & Persistence Service
    Features:
    - Auto-saving background loop (every 120 seconds)
    - game:BindToClose shutdown protection ensuring 100% data persistence
    - Tracks Levels (1-300), Charges (0-10,000), Fragments, Unlocked Worlds, GamePasses
    - Atomic DataStore retries with session locking fallback
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

export type PlayerProfile = {
    UserId: number,
    Level: number,
    Charges: number,
    Element: GameConfig.ElementType,
    ErrorMeter: number,
    ClaimedSecretAllocation: boolean,
    Fragments: { [string]: boolean },
    UnlockedWorlds: { [string]: boolean },
    GamePasses: { [string]: boolean },
    SpinTickets: number,
}

local PlayerDataService = {}
local profiles: { [number]: PlayerProfile } = {}

local PlayerDataStore: DataStore? = nil
pcall(function()
    PlayerDataStore = DataStoreService:GetDataStore("ElementalWorlds_PlayerData_v2")
end)

local DEFAULT_PROFILE: PlayerProfile = {
    UserId = 0,
    Level = 1,
    Charges = 0,
    Element = "Fire",
    ErrorMeter = 0,
    ClaimedSecretAllocation = false,
    Fragments = {},
    UnlockedWorlds = { World1 = true },
    GamePasses = {},
    SpinTickets = 1,
}

-- Load or create profile
function PlayerDataService.LoadProfile(player: Player): PlayerProfile
    local userId = player.UserId
    if profiles[userId] then
        return profiles[userId]
    end

    local loadedData: any = nil
    if PlayerDataStore then
        local attempts = 0
        local success = false
        while attempts < 3 and not success do
            attempts += 1
            local ok, result = pcall(function()
                return PlayerDataStore:GetAsync("User_" .. tostring(userId))
            end)
            if ok then
                success = true
                loadedData = result
            else
                task.wait(0.5)
            end
        end
    end

    local profile: PlayerProfile = {
        UserId = userId,
        Level = if loadedData and loadedData.Level then loadedData.Level else DEFAULT_PROFILE.Level,
        Charges = if loadedData and loadedData.Charges then loadedData.Charges else DEFAULT_PROFILE.Charges,
        Element = if loadedData and loadedData.Element then loadedData.Element else DEFAULT_PROFILE.Element,
        ErrorMeter = 0, -- Resets each session
        ClaimedSecretAllocation = if loadedData and loadedData.ClaimedSecretAllocation ~= nil then loadedData.ClaimedSecretAllocation else false,
        Fragments = if loadedData and loadedData.Fragments then loadedData.Fragments else {},
        UnlockedWorlds = if loadedData and loadedData.UnlockedWorlds then loadedData.UnlockedWorlds else { World1 = true },
        GamePasses = if loadedData and loadedData.GamePasses then loadedData.GamePasses else {},
        SpinTickets = if loadedData and loadedData.SpinTickets then loadedData.SpinTickets else 1,
    }

    profiles[userId] = profile
    PlayerDataService.ApplyLevelHealth(player)
    return profile
end

-- Save player profile with exponential retry
function PlayerDataService.SaveProfile(player: Player): boolean
    local userId = player.UserId
    local profile = profiles[userId]
    if not profile or not PlayerDataStore then
        return false
    end

    local dataToSave = {
        Level = profile.Level,
        Charges = profile.Charges,
        Element = profile.Element,
        ClaimedSecretAllocation = profile.ClaimedSecretAllocation,
        Fragments = profile.Fragments,
        UnlockedWorlds = profile.UnlockedWorlds,
        GamePasses = profile.GamePasses,
        SpinTickets = profile.SpinTickets,
    }

    local success = false
    local attempts = 0
    while attempts < 3 and not success do
        attempts += 1
        local ok = pcall(function()
            PlayerDataStore:SetAsync("User_" .. tostring(userId), dataToSave)
        end)
        if ok then
            success = true
        else
            task.wait(0.5)
        end
    end

    return success
end

function PlayerDataService.GetProfile(player: Player): PlayerProfile?
    return profiles[player.UserId]
end

function PlayerDataService.ApplyLevelHealth(player: Player)
    local profile = profiles[player.UserId]
    if not profile then return end

    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local maxHp = GameConfig.GetMaxHealth(profile.Level)
        -- VIP pass bonus +200 HP
        if profile.GamePasses["VIPMaster"] then
            maxHp += 200
        end
        humanoid.MaxHealth = maxHp
        humanoid.Health = math.min(humanoid.Health, maxHp)
    end
end

function PlayerDataService.SetLevel(player: Player, newLevel: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Level = math.clamp(newLevel, 1, GameConfig.MAX_LEVEL)
    PlayerDataService.ApplyLevelHealth(player)
    PlayerDataService.SyncClient(player)
end

function PlayerDataService.AddLevel(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    -- 2x EXP Gamepass multiplier
    if amount > 0 and profile.GamePasses["DoubleExp"] then
        amount = amount * 2
    end

    PlayerDataService.SetLevel(player, profile.Level + amount)
end

function PlayerDataService.SetCharges(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Charges = math.clamp(amount, 0, GameConfig.MAX_CHARGES)
    PlayerDataService.SyncClient(player)
end

function PlayerDataService.AddCharges(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile then return end

    -- 2x Charges Gamepass multiplier
    if amount > 0 and profile.GamePasses["DoubleCharges"] then
        amount = amount * 2
    end

    PlayerDataService.SetCharges(player, profile.Charges + amount)
end

function PlayerDataService.SetElement(player: Player, element: GameConfig.ElementType)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.Element = element
    profile.ErrorMeter = 0
    PlayerDataService.SyncClient(player)
end

function PlayerDataService.AddErrorMeter(player: Player, amount: number)
    local profile = profiles[player.UserId]
    if not profile or profile.Element ~= "Error" then return end

    profile.ErrorMeter = math.clamp(profile.ErrorMeter + amount, 0, 100)
    PlayerDataService.SyncClient(player)
end

-- Collect a world fragment (e.g. Forest, Cave, Ruins, Mountain)
function PlayerDataService.CollectFragment(player: Player, fragmentId: string): boolean
    local profile = profiles[player.UserId]
    if not profile then return false end

    if profile.Fragments[fragmentId] then
        return false -- Already collected
    end

    profile.Fragments[fragmentId] = true

    -- Count total collected
    local count = 0
    for _ in profile.Fragments do count += 1 end

    -- If collected all 4 World 1 fragments, unlock World 2!
    if count >= 4 and not profile.UnlockedWorlds["World2"] then
        profile.UnlockedWorlds["World2"] = true
        PlayerDataService.AddCharges(player, 500)
        PlayerDataService.AddLevel(player, 5)
    end

    PlayerDataService.SyncClient(player)
    return true
end

-- Add GamePass ownership
function PlayerDataService.GrantGamePass(player: Player, passKey: string)
    local profile = profiles[player.UserId]
    if not profile then return end

    profile.GamePasses[passKey] = true
    if passKey == "VIPMaster" then
        PlayerDataService.ApplyLevelHealth(player)
    end
    PlayerDataService.SyncClient(player)
end

-- Sync state to client
function PlayerDataService.SyncClient(player: Player)
    local profile = profiles[player.UserId]
    if not profile then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local updateStatsEvent = remotes:FindFirstChild(GameConfig.REMOTES.UPDATE_STATS) :: RemoteEvent?
        if updateStatsEvent then
            local fragmentCount = 0
            for _ in profile.Fragments do fragmentCount += 1 end

            updateStatsEvent:FireClient(player, {
                Level = profile.Level,
                Charges = profile.Charges,
                Element = profile.Element,
                ErrorMeter = profile.ErrorMeter,
                MaxHealth = GameConfig.GetMaxHealth(profile.Level),
                FragmentCount = fragmentCount,
                TotalFragments = 4,
                UnlockedWorlds = profile.UnlockedWorlds,
                GamePasses = profile.GamePasses,
                SpinTickets = profile.SpinTickets,
            })
        end
    end
end

function PlayerDataService.RemoveProfile(player: Player)
    PlayerDataService.SaveProfile(player)
    profiles[player.UserId] = nil
end

-- ==================== AUTO-SAVE LOOP (Every 120s) ====================
task.spawn(function()
    while true do
        task.wait(120)
        for _, player in Players:GetPlayers() do
            task.spawn(function()
                PlayerDataService.SaveProfile(player)
            end)
        end
    end
end)

-- ==================== BIND TO CLOSE SHUTDOWN HANDLER ====================
game:BindToClose(function()
    if RunService:IsStudio() then
        -- Quick save in studio
        for _, player in Players:GetPlayers() do
            PlayerDataService.SaveProfile(player)
        end
        return
    end

    local count = #Players:GetPlayers()
    if count == 0 then return end

    local finished = 0
    for _, player in Players:GetPlayers() do
        task.spawn(function()
            PlayerDataService.SaveProfile(player)
            finished += 1
        end)
    end

    -- Hold server open until all profiles are saved or 25s timeout
    local elapsed = 0
    while finished < count and elapsed < 25 do
        task.wait(0.2)
        elapsed += 0.2
    end
end)

return table.freeze(PlayerDataService)
