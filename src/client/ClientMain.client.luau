--!strict
--[[
    Elemental Worlds: Master Client Entry Point
    Initializes: Anime HUD, Creator Dashboard, Spin Gacha UI, Monetization Shop,
    World Map Panel, Camera Shake, 3D Damage Numbers, Tactile Audio, and Network Event Listeners.
    
    Load order:
    1. Core systems (CameraShake, Sound)
    2. HUD (UIController)
    3. Combat & Mobile input
    4. Specialized UIs (Admin, Spin, Shop, Map)
    5. Network listener hooks
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SharedLoader = require(script.Parent.SharedLoader)
local GameConfig = SharedLoader.GameConfig
local UIController = require(script.Parent.Controllers.UIController)
local CombatController = require(script.Parent.Controllers.CombatController)
local CameraShakeController = require(script.Parent.Controllers.CameraShakeController)
local MobileController = require(script.Parent.Controllers.MobileController)
local VFXController = require(script.Parent.Controllers.VFXController)
local AdminPanelController = require(script.Parent.Controllers.AdminPanelController)
local SpinUIController = require(script.Parent.Controllers.SpinUIController)
local ShopUIController = require(script.Parent.Controllers.ShopUIController)

local localPlayer = Players.LocalPlayer

-- 1. Core Systems
CameraShakeController.Init()
UIController.CreateHUD()

-- 2. Link Combat cooldown callback to HUD
CombatController.SetCooldownCallback(function(slot, duration)
    UIController.StartCooldown(slot, duration)
end)

-- 3. Initialize all subsystems
CombatController.Init()
MobileController.Init()
VFXController.Init()
AdminPanelController.Init()
SpinUIController.Init()
ShopUIController.Init()

-- 4. Character health tracking
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

-- 5. Network listeners
local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if remotes then
    -- Stats sync
    local updateStatsEvent = remotes:WaitForChild(GameConfig.REMOTES.UPDATE_STATS, 10) :: RemoteEvent?
    if updateStatsEvent then
        updateStatsEvent.OnClientEvent:Connect(function(data)
            UIController.UpdateStats(data)
            if data and data.Element then
                CombatController.SetCurrentElement(data.Element)
            end
        end)
    end

    -- Global announcements
    local globalAnnounceEvent = remotes:WaitForChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT, 10) :: RemoteEvent?
    if globalAnnounceEvent then
        globalAnnounceEvent.OnClientEvent:Connect(function(message)
            UIController.ShowAnnouncement(message)
        end)
    end

    -- Fragment collection notification
    local fragmentEvent = remotes:WaitForChild(GameConfig.REMOTES.FRAGMENT_COLLECTED, 10) :: RemoteEvent?
    if fragmentEvent then
        fragmentEvent.OnClientEvent:Connect(function(fragmentName)
            UIController.ShowFragmentCollected(fragmentName)
            UIController.ShowAnnouncement("World Fragment Discovered: " .. tostring(fragmentName))
        end)
    end

    -- Element rolled result (handled by SpinUIController)
    local elementRolledEvent = remotes:WaitForChild(GameConfig.REMOTES.ELEMENT_ROLLED, 10) :: RemoteEvent?
    if elementRolledEvent then
        elementRolledEvent.OnClientEvent:Connect(function(element)
            SpinUIController.ShowRollResult(element)
            CombatController.SetCurrentElement(element)
        end)
    end

    -- VFXController.Init() already subscribes to VFX_TRIGGER with full payload decoding
end

print("[Elemental Worlds] Client initialized — HUD, Admin Suite, Spin Gacha, Shop, Map, VFX, and all listeners ready.")
