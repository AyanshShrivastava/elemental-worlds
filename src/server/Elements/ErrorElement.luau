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

local ErrorElement = {}

-- M1: Glitched Dash (Dashes forward and damages targets in path; builds Error Meter)
function ErrorElement.CastM1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "M1")
    if not ability then return end

    -- Dash forward
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -12)

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, rootPart.CFrame.LookVector * 15)
    end
end

-- Move 1: Chaotic Destruction
function ErrorElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "1")
    if not ability then return end

    -- Dash forward with glitched wall impact
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -18)

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        local knock = rootPart.CFrame.LookVector * 45 + Vector3.new(0, 15, 0)
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, knock)
    end
end

-- Move 2: 404 Not Found
function ErrorElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Error", "2")
    if not ability then return end

    local dir = rootPart.CFrame.LookVector
    local spawnPos = rootPart.Position + (dir * 3)

    task.spawn(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { character }
        raycastParams.FilterType = RaycastParamsFilterType.Exclude

        local hitResult = Workspace:Raycast(spawnPos, dir * ability.Range, raycastParams)
        local impactPos = if hitResult then hitResult.Position else (spawnPos + dir * ability.Range)

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

    local duration = ability.Duration or 5.0
    StatusEffectService.ApplyEffect(character, "GotGlitched", duration, player)
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

    local duration = ability.Duration or 7.0
    local originCFrame = rootPart.CFrame
    -- Separate glitched realm coordinate high above map
    local realmPosition = Vector3.new(0, 5000, 0)

    -- Collect nearby targets
    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, 360, character)

    -- Transport caster and targets to isolated realm
    rootPart.CFrame = CFrame.new(realmPosition)
    local targetOriginalCFrames: { [BasePart]: CFrame } = {}

    for _, target in targets do
        targetOriginalCFrames[target.RootPart] = target.RootPart.CFrame
        target.RootPart.CFrame = CFrame.new(realmPosition + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
        StatusEffectService.ApplyEffect(target.Character, "Stunned", duration, player)
    end

    -- Tick damage while inside
    local elapsed = 0
    task.spawn(function()
        while elapsed < duration and character.Parent do
            task.wait(1.0)
            elapsed += 1.0
            for _, target in targets do
                if target.Character.Parent and target.Humanoid.Health > 0 then
                    HitboxService.ApplyDamage(player, target, math.round(ability.BaseDamage / duration), nil)
                end
            end
        end

        -- Safe Return: Guaranteed teleport back to original positions
        if rootPart.Parent then
            rootPart.CFrame = originCFrame
        end
        for root, originalCF in targetOriginalCFrames do
            if root and root.Parent then
                root.CFrame = originalCF
            end
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

    local duration = ability.Duration or 5.0
    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, 360, character)
    for _, target in targets do
        StatusEffectService.ApplyEffect(target.Character, "UnparalleledStun", duration, player)
    end
end

return table.freeze(ErrorElement)
