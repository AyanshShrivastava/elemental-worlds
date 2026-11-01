--!strict
--[[
    Elemental Worlds: Aqua Element Implementation
    M1: Water
    1: Water Hand (Mid damage strike)
    2: Vortex of Destruction (High damage spinning sphere)
    3: Water Dragon (Transformation with on-hit burst cancellation)
    4: Aqua: Limitless Punches (Crazy damage rapid strikes)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local AquaElement = {}

-- M1: Water (4-hit combo support)
function AquaElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Aqua", "M1")
    if not ability then return end

    local step = comboStep or 1
    local isFinisher = (step == 4)
    local damage = if isFinisher then math.round(ability.BaseDamage * 1.6) else ability.BaseDamage
    local knockback = if isFinisher then (rootPart.CFrame.LookVector * 35 + Vector3.new(0, 12, 0)) else (rootPart.CFrame.LookVector * 10)

    -- Visual dual water spray from hands
    VFXBroadcastService.Broadcast("WaterSpray", {
        CFrame = rootPart.CFrame,
        Range = ability.Range,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, damage, knockback, step)
    end
end

-- Move 1: Water Hand
function AquaElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Aqua", "1")
    if not ability then return end

    local strikeCFrame = rootPart.CFrame * CFrame.new(0, 0, -8)
    VFXBroadcastService.Broadcast("WaterHand", {
        Position = strikeCFrame.Position,
        SFXId = ability.SFXId,
        Shake = 0.45,
    })

    local targets = HitboxService.FindTargetsInCone(strikeCFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        local knockback = Vector3.new(0, -20, 0) -- Slam downward
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, knockback)
    end
end

-- Move 2: Vortex of Destruction
function AquaElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Aqua", "2")
    if not ability then return end

    local dir = rootPart.CFrame.LookVector
    local spawnPos = rootPart.Position + (dir * 3)

    task.spawn(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { character }
        raycastParams.FilterType = RaycastParamsFilterType.Exclude

        local hitResult = Workspace:Raycast(spawnPos, dir * ability.Range, raycastParams)
        local impactPos = if hitResult then hitResult.Position else (spawnPos + dir * ability.Range)

        VFXBroadcastService.Broadcast("VortexSphere", {
            StartPos = spawnPos,
            EndPos = impactPos,
            Duration = 0.4,
            SFXId = ability.SFXId,
            Shake = 0.5,
        })

        local targets = HitboxService.FindTargetsInCone(CFrame.new(impactPos), 18, 360, character)
        for _, target in targets do
            local pushVector = (target.RootPart.Position - impactPos).Unit * 35 + Vector3.new(0, 10, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, pushVector)
        end
    end)
end

-- Move 3: Water Dragon (Transformation)
function AquaElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Aqua", "3")
    if not ability then return end

    local duration = ability.Duration or 5.0
    StatusEffectService.ApplyEffect(character, "WaterDragon", duration, player)

    VFXBroadcastService.Broadcast("WaterDragon", {
        Character = character,
        Duration = duration,
        SFXId = ability.SFXId,
    })
end

-- Move 4: Aqua: Limitless Punches
function AquaElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Aqua", "4")
    if not ability then return end

    -- Rapid strikes: 8 hits over 1.5 seconds totaling crazy damage
    local totalHits = 8
    local perHitDamage = math.round(ability.BaseDamage / totalHits)

    task.spawn(function()
        for i = 1, totalHits do
            if not character.Parent then break end

            local punchOffset = CFrame.new(math.random(-2, 2) * 0.8, math.random(-1, 2) * 0.5, -3.5)
            VFXBroadcastService.Broadcast("SlashArc", {
                CFrame = rootPart.CFrame * punchOffset,
                Element = "Aqua",
                Scale = 0.85,
                SFXId = "rbxassetid://3041191430",
            })

            local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
            for _, target in targets do
                local knock = if i == totalHits then (rootPart.CFrame.LookVector * 40 + Vector3.new(0, 15, 0)) else nil
                HitboxService.ApplyDamage(player, target, perHitDamage, knock)
            end

            if i == totalHits then
                VFXBroadcastService.Broadcast("ImpactFrame", {
                    Duration = 0.08,
                    Intensity = 1.25,
                })
                VFXBroadcastService.Broadcast("Crater", {
                    Position = rootPart.Position + (rootPart.CFrame.LookVector * 6),
                    Element = "Aqua",
                    Radius = 16,
                    SFXId = ability.SFXId,
                })
                VFXBroadcastService.Broadcast("Shockwave", {
                    Position = rootPart.Position + (rootPart.CFrame.LookVector * 6),
                    Element = "Aqua",
                    Radius = 20,
                    Duration = 0.4,
                    Shake = 0.6,
                    SFXId = ability.SFXId,
                })
            end

            task.wait(1.5 / totalHits)
        end
    end)
end

return table.freeze(AquaElement)
