--!strict
--[[
    Elemental Worlds: Master Client Entry Point
    Initializes UI, Combat input bindings, Mobile touch controls, and network listeners.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local UIController = require(script.Parent.Controllers.UIController)
local CombatController = require(script.Parent.Controllers.CombatController)
local MobileController = require(script.Parent.Controllers.MobileController)
local VFXController = require(script.Parent.Controllers.VFXController)

-- 1. Initialize UI HUD
UIController.CreateHUD()

-- 2. Link Cooldown callback from CombatController to UI
CombatController.SetCooldownCallback(function(slot, duration)
    UIController.StartCooldown(slot, duration)
end)

-- 3. Initialize Controllers
CombatController.Init()
MobileController.Init()
VFXController.Init()

-- 4. Listen for Stats updates from server
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if remotes then
    local updateStatsEvent = remotes:WaitForChild(GameConfig.REMOTES.UPDATE_STATS, 5) :: RemoteEvent?
    if updateStatsEvent then
        updateStatsEvent.OnClientEvent:Connect(function(data)
            UIController.UpdateStats(data)
        end)
    end

    local globalAnnounceEvent = remotes:WaitForChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT, 5) :: RemoteEvent?
    if globalAnnounceEvent then
        globalAnnounceEvent.OnClientEvent:Connect(function(message)
            UIController.ShowAnnouncement(message)
        end)
    end
end

print("[Elemental Worlds] Client initialized successfully.")
