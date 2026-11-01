--!strict
--[[
    Elemental Worlds: Error Element Implementation (Secret)
    M1: Glitched Dash (Dash with glitch trail; builds Error Meter on hit)
    1: Chaotic Destruction (Glitched wall dash + crazy damage)
    2: 404 Not Found (Glitched ball AoE + heavy knockback)
    3: Got Glitched (5s Invisibility + invulnerability, usable while stunned)
    4: Spatial Distortion (Requires 50% Error Meter: 7s Glitched Domain realm)
    5: Unparalleled (Requires 100% Error Meter: 5s complete enemy movement freeze)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local PlayerDataService = require(script.Parent.Parent.Services.PlayerDataService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local ErrorElement = {}

-- M1: Glitched Dash (4-hit combo support)
function ErrorElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Error", "M1")
    if not ability then return end

    local step = comboStep or 1
    local isFinisher = (step == 4)
    local damage = if isFinisher then math.round(ability.BaseDamage * 1.6) else ability.BaseDamage
    local knockback = if isFinisher then (rootPart.CFrame.LookVector * 40 + Vector3.new(0, 15, 0)) else (rootPart.CFrame.LookVector * 15)

    local prevPos = rootPart.Position
    -- Dash forward
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -12)

    -- Visual chromatic aberration glitch trail
    VFXBroadcastService.Broadcast("GlitchedTrail", {
        StartPos = prevPos,
        EndPos = rootPart.Position,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, damage, knockback, step)
    end

    -- Build Error Meter (+10% on cast)
    PlayerDataService.AddErrorMeter(player, 10)
end

-- Move 1: Chaotic Destruction
function ErrorElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "1")
    if not ability then return end

    -- Visual holographic digital arm shield
    VFXBroadcastService.Broadcast("GlitchWall", {
        Character = character,
        Duration = 0.6,
        SFXId = ability.SFXId,
    })

    -- Dash forward with glitched wall impact
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -18)

    VFXBroadcastService.Broadcast("Crater", {
        Position = rootPart.Position,
        Element = "Error",
        Radius = 14,
        SFXId = ability.SFXId,
    })
    VFXBroadcastService.Broadcast("Shockwave", {
        Position = rootPart.Position,
        Element = "Error",
        Radius = 20,
        Duration = 0.4,
        Shake = 0.45,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        local knock = rootPart.CFrame.LookVector * 45 + Vector3.new(0, 15, 0)
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, knock)
    end

    -- Build Error Meter (+15%)
    PlayerDataService.AddErrorMeter(player, 15)
end

-- Move 2: 404 Not Found
function ErrorElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "2")
    if not ability then return end

    -- Build Error Meter (+20%)
    PlayerDataService.AddErrorMeter(player, 20)

    local dir = rootPart.CFrame.LookVector
    local spawnPos = rootPart.Position + (dir * 3)

    task.spawn(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { character }
        raycastParams.FilterType = RaycastParamsFilterType.Exclude

        local hitResult = Workspace:Raycast(spawnPos, dir * ability.Range, raycastParams)
        local impactPos = if hitResult then hitResult.Position else (spawnPos + dir * ability.Range)

        -- Visual pulsating chromatic aberration 404 ball
        VFXBroadcastService.Broadcast("404Ball", {
            StartPos = spawnPos,
            EndPos = impactPos,
            Duration = 0.45,
            SFXId = ability.SFXId,
            Shake = 0.6,
        })

        local targets = HitboxService.FindTargetsInCone(CFrame.new(impactPos), 20, 360, character)
        for _, target in targets do
            local blastKnock = (target.RootPart.Position - impactPos).Unit * 50 + Vector3.new(0, 20, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, blastKnock)
        end
    end)
end

-- Move 3: Got Glitched (5s Invisibility and Invulnerability)
function ErrorElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "3")
    if not ability then return end

    -- Build Error Meter (+25%)
    PlayerDataService.AddErrorMeter(player, 25)

    local duration = ability.Duration or 5.0
    StatusEffectService.ApplyEffect(character, "GotGlitched", duration, player)

    -- Visual scanline glitch dissolution and shimmer silhouette
    VFXBroadcastService.Broadcast("GlitchInvis", {
        Character = character,
        Duration = duration,
        SFXId = ability.SFXId,
    })
end

-- Move 4: Spatial Distortion (Requires 50% Error Meter)
function ErrorElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local profile = PlayerDataService.GetProfile(player)
    if not profile or profile.ErrorMeter < 50 then
        return -- Insufficient Error Meter!
    end

    local ability = AbilityConfig.GetAbility("Error", "4")
    if not ability then return end

    -- Deduct Error Meter
    PlayerDataService.AddErrorMeter(player, -50)

    -- Glitched realm activation VFX
    VFXBroadcastService.Broadcast("ImpactFrame", {
        Duration = 0.08,
        Intensity = 1.3,
    })
    VFXBroadcastService.Broadcast("ConvergingCharge", {
        Position = rootPart.Position,
        Element = "Error",
        Duration = 0.45,
    })
    VFXBroadcastService.Broadcast("Crater", {
        Position = rootPart.Position,
        Element = "Error",
        Radius = 20,
        SFXId = ability.SFXId,
    })
    VFXBroadcastService.Broadcast("Shockwave", {
        Position = rootPart.Position,
        Element = "Error",
        Radius = 30,
        Duration = 0.5,
        Shake = 0.65,
        SFXId = ability.SFXId,
    })

    local duration = ability.Duration or 7.0
    local domainRadius = 35
    local domainCenter = rootPart.Position

    -- Spawn Grounded Cyber Glitched Domain Arena (NO sky teleport, NO void plummet!)
    VFXBroadcastService.Broadcast("SpatialDistortionDomain", {
        Position = domainCenter,
        Radius = domainRadius,
        Duration = duration,
        SFXId = ability.SFXId,
        Shake = 0.7,
    })

    -- Trap and apply ticks to nearby targets inside the 35-stud arena
    task.spawn(function()
        local elapsed = 0
        while elapsed < duration and character.Parent do
            task.wait(1.0)
            elapsed += 1.0

            local targets = HitboxService.FindTargetsInCone(CFrame.new(domainCenter), domainRadius, 360, character)
            for _, target in targets do
                if target.Character.Parent and target.Humanoid.Health > 0 then
                    StatusEffectService.ApplyEffect(target.Character, "Stunned", 1.2, player)
                    local tickDamage = math.round(ability.BaseDamage / duration)
                    HitboxService.ApplyDamage(player, target, tickDamage, nil)
                end
            end

            -- Pulse a chromatic distortion shockwave every second
            VFXBroadcastService.Broadcast("Shockwave", {
                Position = domainCenter,
                Element = "Error",
                Radius = domainRadius * 0.8,
                Duration = 0.35,
                Shake = 0.3,
            })
        end

        -- Final inward collapse burst
        VFXBroadcastService.Broadcast("ImpactFrame", {
            Duration = 0.1,
            Intensity = 1.4,
        })
        VFXBroadcastService.Broadcast("Crater", {
            Position = domainCenter,
            Element = "Error",
            Radius = 24,
            SFXId = ability.SFXId,
        })
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = domainCenter,
            Element = "Error",
            Radius = domainRadius * 1.2,
            Duration = 0.5,
            Shake = 0.6,
            SFXId = ability.SFXId,
        })
        local finalTargets = HitboxService.FindTargetsInCone(CFrame.new(domainCenter), domainRadius, 360, character)
        for _, target in finalTargets do
            HitboxService.ApplyDamage(player, target, 25, Vector3.new(0, 20, 0))
        end
    end)
end

-- Move 5: Unparalleled (Requires 100% Error Meter)
function ErrorElement.CastMove5(player: Player, character: Model, rootPart: BasePart)
    local profile = PlayerDataService.GetProfile(player)
    if not profile or profile.ErrorMeter < 100 then
        return -- Insufficient Error Meter!
    end

    local ability = AbilityConfig.GetAbility("Error", "5")
    if not ability then return end

    -- Deduct full Error Meter
    PlayerDataService.AddErrorMeter(player, -100)

    VFXBroadcastService.Broadcast("ImpactFrame", {
        Duration = 0.1,
        Intensity = 1.4,
    })
    VFXBroadcastService.Broadcast("Shockwave", {
        Position = rootPart.Position,
        Element = "Error",
        Radius = 35,
        Duration = 0.6,
        Shake = 0.7,
        SFXId = ability.SFXId,
    })

    local duration = ability.Duration or 5.0
    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, 360, character)
    if #targets > 0 then
        for _, target in targets do
            StatusEffectService.ApplyEffect(target.Character, "UnparalleledStun", duration, player)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, nil)
            VFXBroadcastService.Broadcast("GlitchCage", {
                Position = target.RootPart.Position,
                Duration = duration,
                SFXId = ability.SFXId,
            })
        end
    else
        -- Whiff visual feedback: spawn cyber glitch cage in front of caster
        VFXBroadcastService.Broadcast("GlitchCage", {
            Position = rootPart.Position + rootPart.CFrame.LookVector * 12,
            Duration = duration,
            SFXId = ability.SFXId,
        })
    end
end

return table.freeze(ErrorElement)
