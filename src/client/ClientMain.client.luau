--!strict
--[[
    Elemental Worlds: Master Client Entry Point
    Coordinates all client subsystems: Anime HUD, Camera Shake, 3D Damage Numbers,
    Tactile Audio, Procedural Limb Lerping, and Network Event Listeners.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local UIController = require(script.Parent.Controllers.UIController)
local CombatController = require(script.Parent.Controllers.CombatController)
local CameraShakeController = require(script.Parent.Controllers.CameraShakeController)
local MobileController = require(script.Parent.Controllers.MobileController)
local VFXController = require(script.Parent.Controllers.VFXController)

local localPlayer = Players.LocalPlayer

-- 1. Initialize Camera Shake
CameraShakeController.Init()

-- 2. Initialize Anime HUD
UIController.CreateHUD()

-- 3. Link Cooldown callback from CombatController to UI
CombatController.SetCooldownCallback(function(slot, duration)
    UIController.StartCooldown(slot, duration)
end)

-- 4. Initialize Controllers
CombatController.Init()
MobileController.Init()
VFXController.Init()

-- 5. Track character health changes for dual-layer health bar
local function OnCharacterAdded(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    if humanoid then
        humanoid.HealthChanged:Connect(function(health)
            UIController.SetHealth(health, humanoid.MaxHealth)
        end)
        UIController.SetHealth(humanoid.Health, humanoid.MaxHealth)
    end
end

if localPlayer.Character then
    OnCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- 6. Listen for Stats updates from server
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

print("[Elemental Worlds] Client initialized with full anime VFX, audio & camera systems.")
