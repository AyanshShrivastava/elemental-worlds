--!strict
--[[
    Elemental Worlds: Master VFX Controller (Top-Tier Stylized Anime Combat)
    Orchestrates high-fidelity anime effects:
    - Anime Impact Frames (Negative Contrast / Monochrome Inversion flash)
    - Stylized Torus shockwaves & multi-tier ground craters
    - Dual-Core Energy Beams & Anime Crescent Slash Arcs
    - Converging energy charge wind-ups
    - 3D damage numbers, camera trauma shake, and spatial audio
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local SharedLoader = require(script.Parent.Parent.SharedLoader)
local GameConfig = SharedLoader.GameConfig
local VFXHelper = SharedLoader.VFXHelper

local UIController = require(script.Parent.UIController)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)
local DamageNumbersController = require(script.Parent.DamageNumbersController)

local VFXController = {}

-- Anime Impact Frame ColorCorrection in Lighting
local impactCorrection: ColorCorrectionEffect? = nil

local function EnsureImpactCorrection(): ColorCorrectionEffect
    if not impactCorrection or not impactCorrection.Parent then
        local existing = Lighting:FindFirstChild("AnimeImpactFrame") :: ColorCorrectionEffect?
        if existing then
            impactCorrection = existing
        else
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "AnimeImpactFrame"
            cc.Contrast = 0
            cc.Brightness = 0
            cc.Saturation = 0
            cc.Enabled = false
            cc.Parent = Lighting
            impactCorrection = cc
        end
    end
    return impactCorrection :: ColorCorrectionEffect
end

-- Triggers a stylized anime negative contrast impact flash
function VFXController.TriggerImpactFrame(duration: number?, intensity: number?)
    local cc = EnsureImpactCorrection()
    local d = duration or 0.06
    local int = intensity or 1.0

    cc.Contrast = 1.8 * int
    cc.Brightness = 0.3 * int
    cc.Saturation = -1.0 -- Stylized anime high-contrast monochrome flash
    cc.Enabled = true

    task.delay(d, function()
        if cc.Parent then
            cc.Enabled = false
            cc.Contrast = 0
            cc.Brightness = 0
            cc.Saturation = 0
        end
    end)
end

function VFXController.Init()
    EnsureImpactCorrection()

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    local vfxEvent = remotes:WaitForChild(GameConfig.REMOTES.VFX_TRIGGER, 5) :: RemoteEvent?
    if vfxEvent then
        vfxEvent.OnClientEvent:Connect(function(vfxType: string, data: any)
            if vfxType == "Blind" then
                local duration = (data and data.Duration) or 2.0
                UIController.TriggerBlind(duration)

            elseif vfxType == "ImpactFrame" then
                local d = (data and data.Duration) or 0.06
                local int = (data and data.Intensity) or 1.0
                VFXController.TriggerImpactFrame(d, int)

            elseif vfxType == "ImpactBurst" and data and data.Position then
                local element = data.Element or "Fire"
                VFXHelper.CreateImpactBurst(data.Position, element, data.Count or 32)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                else
                    SoundController.PlaySound3D("Punch", data.Position, 0.8)
                end

                if data.IsCrit then
                    VFXController.TriggerImpactFrame(0.06, 1.0)
                end
                CameraShakeController.Shake(data.Shake or 0.25)

            elseif vfxType == "Shockwave" and data and data.Position then
                local element = data.Element or "Fire"
                VFXHelper.CreateShockwave(data.Position, data.Radius or 22, data.Duration or 0.38, element)
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

            elseif vfxType == "CircularSlashWheel" and data and data.CFrame then
                local element = data.Element or "Fire"
                VFXHelper.CreateCircularSlashWheel(data.CFrame, element, data.Radius or 12, data.Count or 16, data.Duration or 0.35)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.CFrame.Position, 0.95)
                else
                    SoundController.PlaySound3D("SwordSlash", data.CFrame.Position, 0.85)
                end
                if data.Shake then
                    CameraShakeController.Shake(data.Shake)
                end
                VFXController.TriggerImpactFrame(0.06, 0.8)

            elseif vfxType == "LightExplosion" and data and data.Position then
                VFXHelper.CreateLightExplosion(data.Position, data.Radius or 22, data.Duration or 0.48)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 1.0)
                else
                    SoundController.PlaySound3D("Explosion", data.Position, 0.95)
                end
                if data.Shake then
                    CameraShakeController.Shake(data.Shake)
                end
                VFXController.TriggerImpactFrame(0.08, 1.1)

            elseif vfxType == "Fireball" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateFireball(data.StartPos, data.EndPos, data.Duration or 0.35)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.85)
                end
                if data.Shake then
                    CameraShakeController.Shake(data.Shake)
                end

            elseif vfxType == "WaterSpray" and data and data.CFrame then
                VFXHelper.CreateWaterSpray(data.CFrame, data.Range or 12)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.CFrame.Position, 0.75)
                end

            elseif vfxType == "WaterHand" and data and data.Position then
                VFXHelper.CreateWaterHand(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.9)
                end
                CameraShakeController.Shake(data.Shake or 0.45)

            elseif vfxType == "VortexSphere" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateVortexSphere(data.StartPos, data.EndPos, data.Duration or 0.4)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.85)
                end
                CameraShakeController.Shake(data.Shake or 0.5)

            elseif vfxType == "WaterDragon" and data and data.Character then
                VFXHelper.AttachWaterDragon(data.Character, data.Duration or 5.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.85)
                end

            elseif vfxType == "EarthPillars" and data and data.CFrame then
                VFXHelper.CreateEarthPillars(data.CFrame, data.Duration or 6.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.CFrame.Position, 0.85)
                end
                CameraShakeController.Shake(0.35)

            elseif vfxType == "Boulder" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateBoulder(data.StartPos, data.EndPos, data.Duration or 0.45)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.9)
                end
                CameraShakeController.Shake(data.Shake or 0.55)

            elseif vfxType == "StoneGauntlet" and data and data.Character then
                VFXHelper.CreateStoneGauntlet(data.Character, data.Duration or 0.4)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.8)
                end

            elseif vfxType == "TerraSequence" and data and data.Position then
                VFXHelper.CreateTerraSequence(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.95)
                end

            elseif vfxType == "MirrorsOfJudgement" and data and data.Position then
                VFXHelper.CreateMirrorsOfJudgement(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                end
                CameraShakeController.Shake(data.Shake or 0.5)

            elseif vfxType == "BlindingFlash" and data and data.Position then
                VFXHelper.CreateBlindingFlash(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                end

            elseif vfxType == "Tornado" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateTornado(data.StartPos, data.EndPos, data.Duration or 0.45)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.8)
                end
                CameraShakeController.Shake(data.Shake or 0.35)

            elseif vfxType == "Cyclone" and data and data.Position then
                VFXHelper.CreateCyclone(data.Position, data.Radius or 20, data.Duration or 4.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.9)
                end
                CameraShakeController.Shake(data.Shake or 0.5)

            elseif vfxType == "WindLightning" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateWindLightning(data.StartPos, data.EndPos)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.8)
                end

            elseif vfxType == "SpeedBoost" and data and data.Character then
                VFXHelper.AttachSpeedBoost(data.Character, data.Duration or 5.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.8)
                end

            elseif vfxType == "GlitchedTrail" and data and data.StartPos and data.EndPos then
                VFXHelper.CreateGlitchedTrail(data.StartPos, data.EndPos)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.8)
                end

            elseif vfxType == "GlitchWall" and data and data.Character then
                VFXHelper.CreateGlitchWall(data.Character, data.Duration or 0.6)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.85)
                end

            elseif vfxType == "404Ball" and data and data.StartPos and data.EndPos then
                VFXHelper.Create404Ball(data.StartPos, data.EndPos, data.Duration or 0.45)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.StartPos, 0.9)
                end
                CameraShakeController.Shake(data.Shake or 0.6)

            elseif vfxType == "GlitchInvis" and data and data.Character then
                VFXHelper.AttachGlitchInvis(data.Character, data.Duration or 5.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.8)
                end

            elseif vfxType == "GlitchInvisEnd" and data and data.Character then
                VFXHelper.EndGlitchInvis(data.Character)

            elseif vfxType == "SpatialDistortionDomain" and data and data.Position then
                VFXHelper.CreateSpatialDistortionDomain(data.Position, data.Radius or 35, data.Duration or 7.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.95)
                end
                CameraShakeController.Shake(data.Shake or 0.65)

            elseif vfxType == "GlitchCage" and data and data.Position then
                VFXHelper.CreateGlitchCage(data.Position, data.Duration or 5.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                end

            elseif vfxType == "ClockAura" and data and data.Character then
                VFXHelper.AttachClockDial(data.Character)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.8)
                end

            elseif vfxType == "TimeInjection" and data and data.Position then
                VFXHelper.CreateTimeInjection(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 0.85)
                end
                CameraShakeController.Shake(data.Shake or 0.45)

            elseif vfxType == "UntouchableBarrier" and data and data.Character then
                VFXHelper.AttachUntouchableBarrier(data.Character, data.Duration or 4.0)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Character:GetPivot().Position, 0.85)
                end

            elseif vfxType == "VirtualKill" and data and data.Position then
                VFXHelper.CreateVirtualKill(data.Position)
                if data.SFXId and data.SFXId ~= "" then
                    SoundController.PlayAudioId3D(data.SFXId, data.Position, 1.0)
                end

            elseif vfxType == "ConvergingCharge" and data and data.Position then
                local element = data.Element or "Fire"
                VFXHelper.CreateConvergingCharge(data.Position, element, data.Duration or 0.5)

            elseif vfxType == "DamageNumber" and data and data.Position and data.Damage then
                local element = data.Element or "Fire"
                DamageNumbersController.SpawnDamageNumber(data.Position, data.Damage, element, data.IsCrit or false)
                if data.IsCrit then
                    VFXController.TriggerImpactFrame(0.05, 0.85)
                end

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
        VFXHelper.CreateShockwave(pos, 22, 0.38, elem)
    elseif vfxType == "Crater" then
        VFXHelper.CreateCrater(pos, 14, elem)
    elseif vfxType == "ConvergingCharge" then
        VFXHelper.CreateConvergingCharge(pos, elem, 0.5)
    end
end

return table.freeze(VFXController)
