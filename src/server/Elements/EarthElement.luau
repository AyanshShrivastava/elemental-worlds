--!strict
--[[
    Elemental Worlds: Earth Element Implementation
    M1: Earth Sword
    1: Earthy Wall (Collidable obstacle blocking attacks)
    2: Boulder of Destruction (Giant rolling projectile)
    3: Accelerated Earth Punch (Infused punch on impact)
    4: The Master of Terra (Cinematic two-character sequence with target reservation)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local EarthElement = {}

-- M1: Earth Sword (4-hit combo support)
function EarthElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Earth", "M1")
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

-- Move 1: Earthy Wall
function EarthElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Earth", "1")
    if not ability then return end

    local wallDuration = ability.Duration or 6.0
    local wallPart = Instance.new("Part")
    wallPart.Name = "EarthyWall"
    wallPart.Size = Vector3.new(16, 9, 3)
    wallPart.CFrame = rootPart.CFrame * CFrame.new(0, 3, -6)
    wallPart.Material = Enum.Material.Slate
    wallPart.Color = Color3.fromRGB(120, 85, 55)
    wallPart.Anchored = true
    wallPart.CanCollide = true
    wallPart.Parent = Workspace:FindFirstChild("Map") or Workspace

    -- Visual eruption effects
    VFXBroadcastService.Broadcast("Crater", {
        Position = wallPart.Position,
        Element = "Earth",
        Radius = 10,
    })
    VFXBroadcastService.Broadcast("Shockwave", {
        Position = wallPart.Position,
        Element = "Earth",
        Radius = 14,
        Duration = 0.35,
        Shake = 0.3,
    })

    Debris:AddItem(wallPart, wallDuration)
end

-- Move 2: Boulder of Destruction
function EarthElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Earth", "2")
    if not ability then return end

    local dir = rootPart.CFrame.LookVector
    local spawnPos = rootPart.Position + (dir * 4)

    task.spawn(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { character }
        raycastParams.FilterType = RaycastParamsFilterType.Exclude

        local hitResult = Workspace:Raycast(spawnPos, dir * ability.Range, raycastParams)
        local impactPos = if hitResult then hitResult.Position else (spawnPos + dir * ability.Range)

        -- Visual boulder shatter impact
        VFXBroadcastService.Broadcast("Crater", {
            Position = impactPos,
            Element = "Earth",
            Radius = 14,
        })
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = impactPos,
            Element = "Earth",
            Radius = 20,
            Duration = 0.45,
            Shake = 0.5,
        })

        local targets = HitboxService.FindTargetsInCone(CFrame.new(impactPos), 15, 360, character)
        for _, target in targets do
            local knock = (target.RootPart.Position - impactPos).Unit * 40 + Vector3.new(0, 15, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, knock)
        end
    end)
end

-- Move 3: Accelerated Earth Punch
function EarthElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Earth", "3")
    if not ability then return end

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, ability.BaseDamage, rootPart.CFrame.LookVector * 25)
    end
end

-- Move 4: The Master of Terra (Cinematic 2-character sequence)
function EarthElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Earth", "4")
    if not ability then return end

    -- 1. Validate and reserve target
    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    if not target or not target.Character.Parent then
        return -- No valid target in direction
    end

    local tRoot = target.RootPart
    local tHum = target.Humanoid

    -- Stun target for sequence
    StatusEffectService.ApplyEffect(target.Character, "Stunned", 3.0, player)

    -- Phase 1: Launch target upward
    tRoot.CFrame = tRoot.CFrame * CFrame.new(0, 20, 0)
    rootPart.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4) -- Teleport behind target in air

    -- Phase 2: Descend together
    task.delay(0.6, function()
        if not target.Character.Parent or tHum.Health <= 0 then return end
        tRoot.CFrame = tRoot.CFrame * CFrame.new(0, -18, 0)
        rootPart.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)

        -- Phase 3: Earth dagger finishing strike
        task.delay(0.4, function()
            if target.Character.Parent and tHum.Health > 0 then
                local slamKnock = Vector3.new(0, -30, 0)
                HitboxService.ApplyDamage(player, target, ability.BaseDamage, slamKnock)

                VFXBroadcastService.Broadcast("Crater", {
                    Position = tRoot.Position,
                    Element = "Earth",
                    Radius = 18,
                })
                VFXBroadcastService.Broadcast("Shockwave", {
                    Position = tRoot.Position,
                    Element = "Earth",
                    Radius = 26,
                    Duration = 0.5,
                    Shake = 0.65,
                })
            end
        end)
    end)
end

return table.freeze(EarthElement)
