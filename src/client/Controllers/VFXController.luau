--!strict
--[[
    Elemental Worlds: Client Master VFX Controller (Blox Fruits Anime Combat)
    Orchestrates high-fidelity particle bursts, dynamic craters, energy beams, 3D damage numbers,
    spatial audio, and camera shakes with zero replication stutter.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local VFXHelper = require(ReplicatedStorage.Shared.Modules.VFXHelper)

local UIController = require(script.Parent.UIController)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)
local DamageNumbersController = require(script.Parent.DamageNumbersController)

local VFXController = {}

function VFXController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    local vfxEvent = remotes:WaitForChild(GameConfig.REMOTES.VFX_TRIGGER, 5) :: RemoteEvent?
    if vfxEvent then
        vfxEvent.OnClientEvent:Connect(function(vfxType: string, data: any)
            if vfxType == "Blind" then
                local duration = (data and data.Duration) or 2.0
                UIController.TriggerBlind(duration)

            elseif vfxType == "ImpactBurst" and data and data.Position then
                local element = data.Element or "Fire"
                VFXHelper.CreateImpactBurst(data.Position, element, data.Count or 32)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                else
                    SoundController.PlaySound3D("Punch", data.Position, 0.8)
                end
                CameraShakeController.Shake(data.Shake or 0.25)

            elseif vfxType == "Shockwave" and data and data.Position then
                local element = data.Element or "Fire"
                VFXHelper.CreateShockwave(data.Position, data.Radius or 22, data.Duration or 0.4, element)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.95)
                else
                    SoundController.PlaySound3D("Explosion", data.Position, 0.9)
                end
                CameraShakeController.Shake(data.Shake or 0.45)

            elseif vfxType == "Crater" and data and data.Position then
                local element = data.Element or "Earth"
                VFXHelper.CreateCrater(data.Position, data.Radius or 14, element)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 1.0)
                else
                    SoundController.PlaySound3D("Explosion", data.Position, 1.0)
                end
                CameraShakeController.Shake(data.Shake or 0.55)

            elseif vfxType == "Beam" and data and data.StartPos and data.EndPos then
                local element = data.Element or "Light"
                VFXHelper.CreateBeam(data.StartPos, data.EndPos, element, data.Thickness or 1.5)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.9)
                else
                    SoundController.PlaySound3D("MagicCast", data.StartPos, 0.85)
                end
                CameraShakeController.Shake(data.Shake or 0.3)

            elseif vfxType == "SlashArc" and data and data.CFrame then
                local element = data.Element or "Fire"
                VFXHelper.CreateSlashArc(data.CFrame, element, data.Scale or 1.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.CFrame.Position, 0.8)
                else
                    SoundController.PlaySound3D("SwordSlash", data.CFrame.Position, 0.7)
                end

            elseif vfxType == "DamageNumber" and data and data.Position and data.Damage then
                local element = data.Element or "Fire"
                DamageNumbersController.SpawnDamageNumber(data.Position, data.Damage, element, data.IsCrit or false)

            elseif vfxType == "ComboHit" and data and data.Count then
                UIController.RegisterComboHit(data.Count)
            end
        end)
    end
end

function VFXController.PlayVFX(vfxType: string, position: Vector3?, element: string?)
    local elem = element or "Fire"
    local pos = position or Vector3.new(0, 0, 0)
    if vfxType == "ImpactBurst" then
        VFXHelper.CreateImpactBurst(pos, elem, 32)
    elseif vfxType == "Shockwave" then
        VFXHelper.CreateShockwave(pos, 22, 0.4, elem)
    elseif vfxType == "Crater" then
        VFXHelper.CreateCrater(pos, 14, elem)
    end
end

return table.freeze(VFXController)
