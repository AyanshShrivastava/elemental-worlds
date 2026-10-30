--!strict
--[[
    Elemental Worlds: Client Combat Controller
    Captures user input (Keyboard, Mouse, Touch) and invokes server ability remotes.
    Plays local animation with marker fallback.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AnimationMarkerUtil = require(ReplicatedStorage.Shared.Modules.AnimationMarkerUtil)

local localPlayer = Players.LocalPlayer

local CombatController = {}

local castAbilityEvent: RemoteEvent? = nil
local abilityEvent: RemoteEvent? = nil

-- Registered UI callback for cooldown timer display
local onCooldownStartedCallback: ((slot: string, duration: number) -> ())? = nil

function CombatController.SetCooldownCallback(callback: (slot: string, duration: number) -> ())
    onCooldownStartedCallback = callback
end

function CombatController.Cast(slot: string)
    if not castAbilityEvent then
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY, 5) :: RemoteEvent?
        end
    end

    if castAbilityEvent then
        castAbilityEvent:FireServer(slot)
    end
end

function CombatController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY) :: RemoteEvent?
    abilityEvent = remotes:WaitForChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?

    -- Listen for server ability execution confirmation
    if abilityEvent then
        abilityEvent.OnClientEvent:Connect(function(slot: string, cooldown: number, animId: string?, marker: string?)
            -- Notify UI for cooldown countdown
            if onCooldownStartedCallback then
                onCooldownStartedCallback(slot, cooldown)
            end

            -- Play local animation if available
            local character = localPlayer.Character
            if character and animId and animId ~= "" and animId ~= "rbxassetid://0" then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    AnimationMarkerUtil.PlayWithMarker(humanoid, animId, marker or "Hit", 0.3, function()
                        -- Marker fired
                    end)
                end
            end
        end)
    end

    -- PC Keyboard & Mouse Inputs
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            CombatController.Cast("M1")
        elseif input.KeyCode == Enum.KeyCode.One then
            CombatController.Cast("1")
        elseif input.KeyCode == Enum.KeyCode.Two then
            CombatController.Cast("2")
        elseif input.KeyCode == Enum.KeyCode.Three then
            CombatController.Cast("3")
        elseif input.KeyCode == Enum.KeyCode.Four then
            CombatController.Cast("4")
        elseif input.KeyCode == Enum.KeyCode.Five then
            CombatController.Cast("5")
        end
    end)
end

return table.freeze(CombatController)
