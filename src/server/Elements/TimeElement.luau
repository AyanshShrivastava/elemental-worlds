--!strict
--[[
    Elemental Worlds: Time Element Implementation (Secret)
    M1: Time Punch (Blue aura high damage punch)
    1: Got Throwed (0.5s target freeze, teleport behind, heavy punch)
    2: Time Injection (Abstract time freeze & information overload)
    3: Untouchable (Invulnerability shield against incoming hits, usable while stunned)
    4: Virtual Kill (Ultimate instant KO finisher with 150s cooldown)
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local HitboxService = require(script.Parent.Parent.Services.HitboxService)
local StatusEffectService = require(script.Parent.Parent.Services.StatusEffectService)
local VFXBroadcastService = require(script.Parent.Parent.Services.VFXBroadcastService)

local TimeElement = {}

-- M1: Time Punch (4-hit combo support)
function TimeElement.CastM1(player: Player, character: Model, rootPart: BasePart, comboStep: number?)
    local ability = AbilityConfig.GetAbility("Time", "M1")
    if not ability then return end

    local step = comboStep or 1
    local isFinisher = (step == 4)
    local damage = if isFinisher then math.round(ability.BaseDamage * 1.6) else ability.BaseDamage
    local knockback = if isFinisher then (rootPart.CFrame.LookVector * 40 + Vector3.new(0, 15, 0)) else (rootPart.CFrame.LookVector * 15)

    -- Broadcast to ElementalVFX Dispatcher
    VFXBroadcastService.Broadcast("ElementalMove", {
        Element = "Time",
        Move = "M1",
        Character = character,
        Target = rootPart.Position + rootPart.CFrame.LookVector * 12,
        Direction = rootPart.CFrame.LookVector,
    })

    -- Visual glowing clock dial aura on striking fist
    VFXBroadcastService.Broadcast("ClockAura", {
        Character = character,
        SFXId = ability.SFXId,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        HitboxService.ApplyDamage(player, target, damage, knockback, step)
    end
end

-- Move 1: Got Throwed
function TimeElement.CastMove1(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Time", "1")
    if not ability then return end

    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    VFXBroadcastService.Broadcast("ElementalMove", {
        Element = "Time",
        Move = "Move1",
        Character = character,
        Target = if target and target.RootPart then target.RootPart.Position else (rootPart.Position + rootPart.CFrame.LookVector * 18),
        Direction = rootPart.CFrame.LookVector,
    })
    if target and target.Character.Parent then
        local tRoot = target.RootPart
        local tHum = target.Humanoid

        -- Freeze target for 0.5 seconds
        StatusEffectService.ApplyEffect(target.Character, "TimeStopped", 0.5, player)

        -- Teleport behind target
        rootPart.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)

        -- Land hard punch when freeze ends
        task.delay(0.5, function()
            if target.Character.Parent and tHum.Health > 0 then
                local punchKnock = rootPart.CFrame.LookVector * 40 + Vector3.new(0, 10, 0)
                HitboxService.ApplyDamage(player, target, ability.BaseDamage, punchKnock)

                VFXBroadcastService.Broadcast("Shockwave", {
                    Position = tRoot.Position,
                    Element = "Time",
                    Radius = 16,
                    Duration = 0.35,
                    Shake = 0.4,
                    SFXId = ability.SFXId,
                })
            end
        end)
    else
        -- Whiff action: Chronological high-speed dash forward with time rift shockwave
        rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -18)
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = rootPart.Position,
            Element = "Time",
            Radius = 14,
            Duration = 0.3,
            Shake = 0.35,
            SFXId = ability.SFXId,
        })
    end
end

-- Move 2: Time Injection (Abstract 2 years in 0.2s effect)
function TimeElement.CastMove2(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Time", "2")
    if not ability then return end

    local castPos = rootPart.Position + (rootPart.CFrame.LookVector * 12)
    VFXBroadcastService.Broadcast("ElementalMove", {
        Element = "Time",
        Move = "Move2",
        Character = character,
        Target = castPos,
        Direction = rootPart.CFrame.LookVector,
    })

    -- Visual abstract timeline streams & spinning clock rings
    VFXBroadcastService.Broadcast("TimeInjection", {
        Position = castPos,
        SFXId = ability.SFXId,
        Shake = 0.45,
    })

    local targets = HitboxService.FindTargetsInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    for _, target in targets do
        -- Brief time stop effect
        StatusEffectService.ApplyEffect(target.Character, "TimeStopped", 0.8, player)
        task.delay(0.2, function()
            if target.Character.Parent and target.Humanoid.Health > 0 then
                HitboxService.ApplyDamage(player, target, ability.BaseDamage, nil)
            end
        end)
    end
end

-- Move 3: Untouchable (Incoming attack invulnerability)
function TimeElement.CastMove3(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Time", "3")
    if not ability then return end

    local duration = ability.Duration or 4.0
    -- Applies Untouchable status: StatusEffectService.CanTakeDamage returns false!
    StatusEffectService.ApplyEffect(character, "Untouchable", duration, player)

    VFXBroadcastService.Broadcast("ElementalMove", {
        Element = "Time",
        Move = "Move3",
        Character = character,
        Duration = duration,
    })

    -- Visual revolving chronological forcefield with ethereal clock gears
    VFXBroadcastService.Broadcast("UntouchableBarrier", {
        Character = character,
        Duration = duration,
        SFXId = ability.SFXId,
    })
end

-- Move 4: Virtual Kill (Ultimate instant KO with 150s cooldown)
function TimeElement.CastMove4(player: Player, character: Model, rootPart: BasePart)
    local ability = AbilityConfig.GetAbility("Time", "4")
    if not ability then return end

    local target = HitboxService.FindClosestTargetInCone(rootPart.CFrame, ability.Range, ability.ConeAngle, character)
    local strikePos = if target and target.Character.Parent then target.RootPart.Position else (rootPart.Position + rootPart.CFrame.LookVector * 15)

    VFXBroadcastService.Broadcast("ElementalMove", {
        Element = "Time",
        Move = "Move4",
        Character = character,
        Target = strikePos,
        Direction = rootPart.CFrame.LookVector,
    })

    VFXBroadcastService.Broadcast("ConvergingCharge", {
        Position = rootPart.Position,
        Element = "Time",
        Duration = 0.4,
    })

    if target and target.Character.Parent then
        -- Time freeze during execution
        StatusEffectService.ApplyEffect(target.Character, "TimeStopped", 1.0, player)
    end

    task.delay(0.4, function()
        if not character.Parent then return end

        local strikePos = if target and target.Character.Parent then target.RootPart.Position else (rootPart.Position + rootPart.CFrame.LookVector * 15)

        VFXBroadcastService.Broadcast("ImpactFrame", {
            Duration = 0.1,
            Intensity = 1.5,
        })
        -- Visual colossal floor clock dial, vertical chronological beam and burst
        VFXBroadcastService.Broadcast("VirtualKill", {
            Position = strikePos,
            SFXId = ability.SFXId,
        })
        VFXBroadcastService.Broadcast("Shockwave", {
            Position = strikePos,
            Element = "Time",
            Radius = 75,
            Duration = 0.5,
            Shake = 0.7,
            SFXId = ability.SFXId,
        })

        if target and target.Character.Parent and target.Humanoid.Health > 0 then
            -- Instant KO under balance rules (deals max health as true damage)
            local killDamage = target.Humanoid.MaxHealth + 1000
            HitboxService.ApplyDamage(player, target, killDamage, rootPart.CFrame.LookVector * 50)
        end
    end)
end

return table.freeze(TimeElement)
