--!strict
--[[
    Elemental Worlds: Light Element Implementation
    M1: Dim Light Ray
    1: Amplified Light (Piercing beam)
    2: Mirrors of Judgement (Mirror bounce slam)
    3: Blinding Attack (2-second blind effect + low damage)
    4: Divine Light Amplification (Massive amplified charge blast)
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local LightElement = {}

-- M1: Dim Light Ray (4-hit combo support)
function LightElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Light", "M1")
    if not ability then return end

    local step = comboStep or 1
    local isFinisher = (step == 4)
    local damage = if isFinisher then math.round(ability.BaseDamage * 1.6) else ability.BaseDamage
    local knockback = if isFinisher then (rootPart.CFrame.LookVector * 35 + Vector3.new(0, 12, 0)) else (rootPart.CFrame.LookVector * 10)

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, damage, knockback, step)
    end
end

-- Move 1: Amplified Light
function LightElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Light", "1")
    if not ability then return end

    local beamEnd = rootPart.Position + (rootPart.CFrame.LookVector * ability.Range)
    VFXBroadcastService.Broadcast("Beam", {
        StartPos = rootPart.Position + Vector3.new(0, 1.5, 0),
        EndPos = beamEnd,
        Element = "Light",
        Thickness = 1.4,
        Shake = 0.25,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, rootPart.CFrame.LookVector * 20)
    end
end

-- Move 2: Mirrors of Judgement
function LightElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Light", "2")
    if not ability then return end

    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    if not target then return end

    -- Ray bounces between mirrors and slams target
    task.delay(0.3, function()
        if target.Character.Parent and target.Humanoid.Health > 0 then
            local slamVector = Vector3.new(0, -25, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, slamVector)

            VFXBroadcastService.Broadcast("Crater", {
                Position = target.RootPart.Position,
                Element = "Light",
                Radius = 12,
                SFXId = ability.SFXId,
            })
            VFXBroadcastService.Broadcast("Shockwave", {
                Position = target.RootPart.Position,
                Element = "Light",
                Radius = 16,
                Duration = 0.35,
                Shake = 0.45,
                SFXId = ability.SFXId,
            })
        end
    end)
end

-- Move 3: Blinding Attack (2s Blind Effect)
function LightElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Light", "3")
    if not ability then return end

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, nil)
        -- Apply fair 2-second blindness status effect
        StatusEffectService.ApplyEffect(target.Character, "Blinded", ability.Duration or 2.0, player)
    end
end

-- Move 4: Divine Light Amplification
function LightElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Light", "4")
    if not ability then return end

    -- Brief charge delay before releasing massive beam
    task.delay(0.4, function()
        if not character.Parent then return end

        local beamEnd = rootPart.Position + (rootPart.CFrame.LookVector * ability.Range)
        VFXBroadcastService.Broadcast("Beam", {
            StartPos = rootPart.Position + Vector3.new(0, 1.5, 0),
            EndPos = beamEnd,
            Element = "Light",
            Thickness = 3.6,
            Shake = 0.65,
            SFXId = ability.SFXId,
        })
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = rootPart.Position,
            Element = "Light",
            Radius = 22,
            Duration = 0.45,
            Shake = 0.5,
            SFXId = ability.SFXId,
        })

        local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
        for _, target in targets do
            local blastKnock = rootPart.CFrame.LookVector * 50 + Vector3.new(0, 20, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, blastKnock)
        end
    end)
end

return table.freeze(LightElement)
