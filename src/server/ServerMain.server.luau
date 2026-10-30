--!strict
--[[
    Elemental Worlds: Master Server Entry Point
    Initializes Remotes, Services, Map Generation, Monetization, Creator Perks,
    Player Lifecycles, and Network Routing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
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

-- 1. Ensure Remotes folder and events exist
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
    return remote
end

local castAbilityEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.CAST_ABILITY)
local abilityEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ABILITY_EVENT)
local updateStatsEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.UPDATE_STATS)
local rollElementEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ROLL_ELEMENT)
local globalAnnounceEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT)
local vfxTriggerEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.VFX_TRIGGER)
local elementRolledEvent = GetOrCreateRemoteEvent(GameConfig.REMOTES.ELEMENT_ROLLED)

-- 2. Build World 1 Map and Regions
MapService.BuildWorld1()

-- 3. Remote Event Listeners
castAbilityEvent.OnServerEvent:Connect(function(player: Player, slot: any, clientData: any)
    if type(slot) == "string" then
        CombatService.ProcessCast(player, slot, clientData)
    end
end)

rollElementEvent.OnServerEvent:Connect(function(player: Player)
    local rolled = RNGSystem.RollElement(player)
    elementRolledEvent:FireClient(player, rolled)
end)

-- 4. Player Lifecycle
local function OnPlayerAdded(player: Player)
    -- Load profile
    local profile = PlayerDataService.LoadProfile(player)

    -- Apply creator crown & title if coolzgamer9
    CreatorPerksService.ApplyCreatorVisuals(player)

    -- Handle character spawns
    player.CharacterAdded:Connect(function(character)
        PlayerDataService.ApplyLevelHealth(player)
        PlayerDataService.SyncClient(player)
        CreatorPerksService.ApplyCreatorVisuals(player)
    end)

    if player.Character then
        PlayerDataService.ApplyLevelHealth(player)
        PlayerDataService.SyncClient(player)
    end

    -- Hook legacy chatted for commands as fallback
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
for _, player in Players:GetPlayers() do
    OnPlayerAdded(player)
end

-- Hook TextChatService for modern chat command handling
pcall(function()
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local source = textChatMessage.TextSource
        if source then
            local sender = Players:GetPlayerByUserId(source.UserId)
            if sender then
                AdminService.ExecuteCommand(sender, textChatMessage.Text)
            end
        end
    end)
end)

print("[Elemental Worlds] Master Server with Map, Monetization, Creator Perks, and Saving initialized.")
