--!strict
--[[
    Elemental Worlds: Fire Element Implementation
    M1: Flame Dagger
    1: Scorching Fireball (Projectile with impact/miss burst)
    2: Infernal Beast (Summons fire minion with 25% max HP)
    3: Flames of Fury (Teleports behind target + Goldi beam & lines)
    4: Infernal Judgement (10s Fire Domain barrier with boundary lock)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local FireElement = {}

-- M1: Flame Dagger (4-hit combo support)
function FireElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Fire", "M1")
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

-- Move 1: Scorching Fireball
function FireElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Fire", "1")
    if not ability then return end

    local spawnPos = rootPart.Position + (rootPart.CFrame.LookVector * 3)
    local dir = rootPart.CFrame.LookVector

    -- Simulate projectile raycast forward
    task.spawn(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = { character }
        raycastParams.FilterType = RaycastParamsFilterType.Exclude

        local hitResult = Workspace:Raycast(spawnPos, dir * ability.Range, raycastParams)
        local impactPos = if hitResult then hitResult.Position else (spawnPos + dir * ability.Range)

        -- Burst AoE at impact/miss position
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = impactPos,
            Element = "Fire",
            Radius = 16,
            Duration = 0.35,
            Shake = 0.35,
            SFXId = ability.SFXId,
        })

        local burstCFrame = CFrame.new(impactPos)
        local blastRadius = 15
        local targets = HitboxService.FindTargetsInCone(burstCFrame, blastRadius, 360, character)
        for _, target in targets do
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, (target.RootPart.Position - impactPos).Unit * 25)
        end
    end)
end

-- Move 2: Infernal Beast
function FireElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Fire", "2")
    if not ability then return end

    local summonerHum = character:FindFirstChildOfClass("Humanoid")
    local maxHealth = if summonerHum then summonerHum.MaxHealth else 100
    local beastHealth = maxHealth * 0.25

    -- Create summon NPC model
    local beast = Instance.new("Model")
    beast.Name = player.Name .. "_InfernalBeast"

    local bRoot = Instance.new("Part")
    bRoot.Name = "HumanoidRootPart"
    bRoot.Size = Vector3.new(2, 2, 2)
    bRoot.Color = Color3.fromRGB(255, 69, 0)
    bRoot.Material = Enum.Material.Neon
    bRoot.CFrame = rootPart.CFrame * CFrame.new(3, 0, -3)
    bRoot.CanCollide = false
    bRoot.Parent = beast

    local bHum = Instance.new("Humanoid")
    bHum.MaxHealth = beastHealth
    bHum.Health = beastHealth
    bHum.WalkSpeed = 18
    bHum.Parent = beast

    beast.PrimaryPart = bRoot
    beast.Parent = Workspace:FindFirstChild("NPCs") or Workspace

    -- Beast auto-targeting loop
    local duration = ability.Duration or 15
    local alive = true

    task.spawn(function()
        local elapsed = 0
        while alive and elapsed < duration do
            task.wait(1.5)
            elapsed += 1.5
            if not beast.Parent or bHum.Health <= 0 then break end

            local target = HitboxService.FindClosestTargetInCone(bRoot.CFrame, 25, 360, beast)
            if target and target.Character ~= character then
                bHum:MoveTo(target.RootPart.Position)
                local dist = (target.RootPart.Position - bRoot.Position).Magnitude
                if dist <= 6 then
                    HitboxService.ApplyDamage(player, target, ability.BaseDamage, nil)
                end
            end
        end

        alive = false
        if beast.Parent then
            beast:Destroy()
        end
    end)

    Debris:AddItem(beast, duration + 1)
end

-- Move 3: Flames of Fury
function FireElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Fire", "3")
    if not ability then return end

    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    if not target then return end

    -- Chat line logic: check if fury is 100% or below
    local chatLine = "Goldi..."
    -- Teleport behind target
    rootPart.CFrame = target.RootPart.CFrame * CFrame.new(0, 0, 4)

    -- Fire beam at target
    VFXBroadcastService.Broadcast("Beam", {
        StartPos = rootPart.Position + Vector3.new(0, 1.5, 0),
        EndPos = target.RootPart.Position,
        Element = "Fire",
        Thickness = 1.8,
        Shake = 0.4,
        SFXId = ability.SFXId,
    })

    task.delay(0.2, function()
        if target.Character.Parent and target.Humanoid.Health > 0 then
            local knockback = rootPart.CFrame.LookVector * 45 + Vector3.new(0, 15, 0)
            HitboxService.ApplyDamage(player, target, ability.BaseDamage, knockback)
        end
    end)
end

-- Move 4: Infernal Judgement (10s Domain)
function FireElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Fire", "4")
    if not ability then return end

    local domainCenter = rootPart.Position
    local domainRadius = 30
    local duration = ability.Duration or 10

    -- Rise above ground
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 8, 0)
    rootPart.Anchored = true

    -- VFX: Converging charge wind-up, impact frame, massive eruption crater and shockwave
    VFXBroadcastService.Broadcast("ImpactFrame", {
        Duration = 0.08,
        Intensity = 1.2,
    })
    VFXBroadcastService.Broadcast("ConvergingCharge", {
        Position = domainCenter,
        Element = "Fire",
        Duration = 0.45,
    })
    VFXBroadcastService.Broadcast("Crater", {
        Position = domainCenter,
        Radius = 18,
        Element = "Fire",
        SFXId = ability.SFXId,
    })
    VFXBroadcastService.Broadcast("Shockwave", {
        Position = domainCenter,
        Element = "Fire",
        Radius = domainRadius,
        Duration = 0.5,
        Shake = 0.55,
        SFXId = ability.SFXId,
    })

    -- Visual Domain Boundary Part
    local domainPart = Instance.new("Part")
    domainPart.Name = "FireDomain_Boundary"
    domainPart.Shape = Enum.PartType.Cylinder
    domainPart.Size = Vector3.new(25, domainRadius * 2, domainRadius * 2)
    domainPart.CFrame = CFrame.new(domainCenter) * CFrame.Angles(0, 0, math.rad(90))
    domainPart.Transparency = 0.7
    domainPart.Color = Color3.fromRGB(255, 80, 0)
    domainPart.Material = Enum.Material.ForceField
    domainPart.Anchored = true
    domainPart.CanCollide = false
    domainPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    -- Tick damage and boundary containment loop
    local elapsed = 0
    task.spawn(function()
        while elapsed < duration and character.Parent do
            task.wait(1.0)
            elapsed += 1.0

            local targets = HitboxService.FindTargetsInCone(CFrame.new(domainCenter), domainRadius, 360, character)
            for _, t in targets do
                HitboxService.ApplyDamage(player, t, math.round(ability.BaseDamage / duration), nil)
                -- Clamp to boundary
                local offset = t.RootPart.Position - domainCenter
                if offset.Magnitude > domainRadius - 2 then
                    t.RootPart.Position = domainCenter + (offset.Unit * (domainRadius - 3))
                end
            end
        end

        -- Safe Cleanup
        if rootPart and rootPart.Parent then
            rootPart.Anchored = false
        end
        if domainPart.Parent then
            domainPart:Destroy()
        end
    end)
end

return table.freeze(FireElement)
