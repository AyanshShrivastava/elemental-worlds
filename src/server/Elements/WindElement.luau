--!strict
--[[
    Elemental Worlds: Wind Element Implementation
    M1: Compressed Wind (Lightning-bolt shaped wind projectile)
    1: Airy Vortex (Small tornado)
    2: The Cyclone of Fury (Pulls targets into vortex + high damage)
    3: Maximum Speed (5-second speed boost for escape/repositioning)
    4: Wind: Death Speed (Cinematic dive, rock ride, and lightning wind dash)
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local WindElement = {}

-- M1: Compressed Wind (4-hit combo support)
function WindElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Wind", "M1")
    if not ability then return end

    local step = comboStep or 1
    local isFinisher = (step == 4)
    local damage = if isFinisher then math.round(ability.BaseDamage * 1.6) else ability.BaseDamage
    local knockback = if isFinisher then (rootPart.CFrame.LookVector * 40 + Vector3.new(0, 15, 0)) else (rootPart.CFrame.LookVector * 15)

    -- Visual wind lightning projectile
    local m1End = rootPart.Position + (rootPart.CFrame.LookVector * ability.Range)
    VFXBroadcastService.Broadcast("WindLightning", {
        StartPos = rootPart.Position + Vector3.new(0, 1.2, 0),
        EndPos = m1End,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, damage, knockback, step)
    end
end

-- Move 1: Airy Vortex
function WindElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Wind", "1")
    if not ability then return end

    local spawnPos = rootPart.Position + (rootPart.CFrame.LookVector * 2)
    local endPos = rootPart.Position + (rootPart.CFrame.LookVector * ability.Range)

    -- Visual mini tornado traveling forward
    VFXBroadcastService.Broadcast("Tornado", {
        StartPos = spawnPos,
        EndPos = endPos,
        Duration = 0.45,
        SFXId = ability.SFXId,
        Shake = 0.35,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        local push = rootPart.CFrame.LookVector * 30 + Vector3.new(0, 10, 0)
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, push)
    end
end

-- Move 2: The Cyclone of Fury
function WindElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Wind", "2")
    if not ability then return end

    local cycloneCenter = rootPart.Position + (rootPart.CFrame.LookVector * 10)
    local duration = ability.Duration or 4.0

    -- Visual massive swirling cyclone with suction particles
    VFXBroadcastService.Broadcast("Cyclone", {
        Position = cycloneCenter,
        Radius = ability.Range,
        Duration = duration,
        SFXId = ability.SFXId,
        Shake = 0.5,
    })

    local elapsed = 0
    task.spawn(function()
        while elapsed < duration and character.Parent do
            task.wait(0.5)
            elapsed += 0.5

            local targets = HitboxService.FindTargetsInCone(CFrame.new(cycloneCenter), ability.Range, 360, character)
            for _, target in targets do
                -- Pull toward cyclone center
                local toCenter = (cycloneCenter - target.RootPart.Position).Unit * 20
                target.RootPart:ApplyImpulse(toCenter * target.RootPart.AssemblyMass)
                HitboxService.ApplyDamage(player, target, math.round(ability.BaseDamage / (duration * 2)), nil)
            end
        end
    end)
end

-- Move 3: Maximum Speed (5s Speed Boost)
function WindElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Wind", "3")
    if not ability then return end

    local duration = ability.Duration or 5.0
    StatusEffectService.ApplyEffect(character, "SpeedBoost", duration, player)

    -- Visual sonic wind trails and foot ring emitters
    VFXBroadcastService.Broadcast("SpeedBoost", {
        Character = character,
        Duration = duration,
        SFXId = ability.SFXId,
    })
end

-- Move 4: Wind: Death Speed (Cinematic Sequence)
function WindElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Wind", "4")
    if not ability then return end

    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    if not target or not target.Character.Parent then return end

    local tRoot = target.RootPart
    local tHum = target.Humanoid

    -- Sequence Step 1: Lift target and caster into the air
    StatusEffectService.ApplyEffect(target.Character, "Stunned", 3.0, player)
    tRoot.CFrame = tRoot.CFrame * CFrame.new(0, 25, 0)
    rootPart.CFrame = tRoot.CFrame * CFrame.new(0, 5, 5)

    -- Sequence Step 2: Dive down quickly
    task.delay(0.5, function()
        if not target.Character.Parent or tHum.Health <= 0 then return end
        tRoot.CFrame = tRoot.CFrame * CFrame.new(0, -23, 0)
        rootPart.CFrame = tRoot.CFrame * CFrame.new(0, 2, -10)

        -- Sequence Step 3: Wind lightning bolt dash finisher
        task.delay(0.4, function()
            if target.Character.Parent and tHum.Health > 0 then
                local finalDashKnock = rootPart.CFrame.LookVector * 50 + Vector3.new(0, 15, 0)
                HitboxService.ApplyDamage(player, target, ability.BaseDamage, finalDashKnock)

                VFXBroadcastService.Broadcast("ImpactFrame", {
                    Duration = 0.08,
                    Intensity = 1.3,
                })
                VFXBroadcastService.Broadcast("Crater", {
                    Position = tRoot.Position,
                    Element = "Wind",
                    Radius = 16,
                    SFXId = ability.SFXId,
                })
                VFXBroadcastService.Broadcast("Shockwave", {
                    Position = tRoot.Position,
                    Element = "Wind",
                    Radius = 24,
                    Duration = 0.45,
                    Shake = 0.6,
                    SFXId = ability.SFXId,
                })
            end
        end)
    end)
end

return table.freeze(WindElement)
