--!strict
--[[
    Elemental Worlds: Client Combat Controller
    Features a 4-hit M1 combo system, procedural attack motions, sound triggers, and camera shake.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AnimationMarkerUtil = require(ReplicatedStorage.Shared.Modules.AnimationMarkerUtil)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)
local ProceduralAnimController = require(script.Parent.ProceduralAnimController)

local localPlayer = Players.LocalPlayer

local CombatController = {}

local castAbilityEvent: RemoteEvent? = nil
local abilityEvent: RemoteEvent? = nil

-- Combo State
local comboStep = 1
local lastM1Time = 0.0
local COMBO_RESET_DELAY = 1.3 -- Reset combo if idle for 1.3 seconds

local onCooldownStartedCallback: ((slot: string, duration: number) -> ())? = nil

function CombatController.SetCooldownCallback(callback: (slot: string, duration: number) -> ())
    onCooldownStartedCallback = callback
end

-- Cast ability with slot and optional metadata
function CombatController.Cast(slot: string)
    if not castAbilityEvent then
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY, 5) :: RemoteEvent?
        end
    end

    if not castAbilityEvent then return end

    if slot == "M1" then
        local now = os.clock()
        if now - lastM1Time > COMBO_RESET_DELAY then
            comboStep = 1
        end
        lastM1Time = now

        -- Procedural punch animation & sound
        ProceduralAnimController.PlayProceduralPunch(comboStep)
        SoundController.PlaySound2D("Punch", 0.6)

        -- Slight screen shake on finisher (combo step 4)
        if comboStep == 4 then
            CameraShakeController.Shake(0.35)
        end

        castAbilityEvent:FireServer(slot, { ComboStep = comboStep })

        -- Advance combo step (1 -> 2 -> 3 -> 4 -> 1)
        comboStep = (comboStep % 4) + 1
    else
        -- Heavy cast motion
        ProceduralAnimController.PlayCastRecoil()
        SoundController.PlaySound2D("MagicCast", 0.7)
        CameraShakeController.Shake(0.2)
        castAbilityEvent:FireServer(slot, {})
    end
end

function CombatController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY) :: RemoteEvent?
    abilityEvent = remotes:WaitForChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?

    -- Server ability execution listener
    if abilityEvent then
        abilityEvent.OnClientEvent:Connect(function(slot: string, cooldown: number, animId: string?, marker: string?)
            if onCooldownStartedCallback then
                onCooldownStartedCallback(slot, cooldown)
            end

            local character = localPlayer.Character
            if character and animId and animId ~= "" and animId ~= "rbxassetid://0" then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    AnimationMarkerUtil.PlayWithMarker(humanoid, animId, marker or "Hit", 0.3, function()
                        -- Marker reached
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
