--!strict
--[[
    Elemental Worlds: Master Server Entry Point
    Initializes: Remotes, Services, Map Generation, Monetization, Creator Perks,
    Player Lifecycles, Gamepass Ownership Checks, and Network Routing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local CooldownService = require(script.Parent.Services.CooldownService)
local CombatService = require(script.Parent.Services.CombatService)
local RNGSystem = require(script.Parent.Services.RNGSystem)
local AdminService = require(script.Parent.Services.AdminService)
local MapService = require(script.Parent.Services.MapService)
local MonetizationService = require(script.Parent.Services.MonetizationService)
local CreatorPerksService = require(script.Parent.Services.CreatorPerksService)

-- 1. Ensure Remotes folder and all events exist
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local function GetOrCreateRemoteEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote :: RemoteEvent
end

local function GetOrCreateRemoteFunction(name: string): RemoteFunction
    local remote = remotesFolder:FindFirstChild(name) :: RemoteFunction?
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote :: RemoteFunction
end

-- Create all remote events
local castAbilityEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.CAST_ABILITY)
local abilityEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ABILITY_EVENT)
local updateStatsEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.UPDATE_STATS)
local rollElementEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ROLL_ELEMENT)
local globalAnnounceEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT)
local vfxTriggerEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.VFX_TRIGGER)
local soundTriggerEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.SOUND_TRIGGER)
local elementRolledEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ELEMENT_ROLLED)
local adminCommandEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ADMIN_COMMAND)
local openShopEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.OPEN_SHOP)
local fragmentCollectedEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.FRAGMENT_COLLECTED)
local mapTeleportEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.MAP_TELEPORT)

-- 2. Build World 1 Map
MapService.BuildWorld1()

-- 3. Remote Event Listeners

-- Combat abilities
castAbilityEvent.OnServerEvent:Connect(function(player: Player, slot: any, clientData: any)
    if type(slot) == "string" then
        CombatService.ProcessCast(player, slot, clientData)
    end
end)

-- Spin for element
rollElementEvent.OnServerEvent:Connect(function(player: Player)
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return end

    -- Deduct spin ticket
    if profile.SpinTickets <= 0 then
        return
    end
    profile.SpinTickets -= 1

    local rolled = RNGSystem.RollElement(player)
    elementRolledEvent:FireClient(player, rolled)
    PlayerDataService.SyncClient(player)
end)

-- Admin commands via remote (from admin panel)
adminCommandEvent.OnServerEvent:Connect(function(player: Player, cmd: any, arg1: any, arg2: any)
    if type(cmd) == "string" then
        -- Reconstruct command string for AdminService
        local fullCmd = cmd
        if arg1 then fullCmd = fullCmd .. " " .. tostring(arg1) end
        if arg2 then fullCmd = fullCmd .. " " .. tostring(arg2) end
        AdminService.ExecuteCommand(player, fullCmd)
    end
end)

-- Map teleport
mapTeleportEvent.OnServerEvent:Connect(function(player: Player, worldId: any)
    if type(worldId) ~= "string" then return end
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return end

    local hasWorld = profile.UnlockedWorlds[worldId]
    if not hasWorld then return end

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    -- Teleport to world spawn (MapService provides spawn positions)
    local spawnPos = MapService.GetWorldSpawn(worldId)
    root.CFrame = spawnPos
end)

-- 4. Player Lifecycle
local function OnPlayerAdded(player: Player)
    -- Load profile
    PlayerDataService.LoadProfile(player)

    -- Check gamepass ownership
    MonetizationService.CheckOwnershipOnJoin(player)

    -- Apply creator visuals if applicable
    CreatorPerksService.ApplyCreatorVisuals(player)

    -- Handle character spawns
    player.CharacterAdded:Connect(function(character)
        -- Wait for humanoid to exist
        local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
        if humanoid then
            -- Apply speed boost gamepass
            local profile = PlayerDataService.GetProfile(player)
            if profile and profile.GamePasses["SpeedBoost"] then
                humanoid.WalkSpeed = 19
                humanoid.JumpPower = 54
            end
        end

        PlayerDataService.ApplyLevelHealth(player)
        PlayerDataService.SyncClient(player)
        CreatorPerksService.ApplyCreatorVisuals(player)
    end)

    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local profile = PlayerDataService.GetProfile(player)
            if profile and profile.GamePasses["SpeedBoost"] then
                humanoid.WalkSpeed = 19
                humanoid.JumpPower = 54
            end
        end
        PlayerDataService.ApplyLevelHealth(player)
        PlayerDataService.SyncClient(player)
    end

    -- Legacy chat fallback for commands
    player.Chatted:Connect(function(msg)
        AdminService.ExecuteCommand(player, msg)
    end)
end

local function OnPlayerRemoving(player: Player)
    PlayerDataService.RemoveProfile(player)
    CooldownService.ClearPlayer(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Handle players already in server (Studio play test)
for _, player in Players:GetPlayers() do
    task.spawn(OnPlayerAdded, player)
end

-- Hook TextChatService for modern slash command handling
pcall(function()
    local tcs = game:GetService("TextChatService")
    tcs.MessageReceived:Connect(function(textChatMessage)
        local source = textChatMessage.TextSource
        if source then
            local sender = Players:GetPlayerByUserId(source.UserId)
            if sender then
                AdminService.ExecuteCommand(sender, textChatMessage.Text)
            end
        end
    end)
end)

print("[Elemental Worlds] Server initialized — Map, Monetization, Creator Perks, Saving, and Remotes ready.")
