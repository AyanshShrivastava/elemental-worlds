--!strict
--[[
    Elemental Worlds: Combat Helper Module
    Authoritative math for directional hit detection, aim verification, and damage scaling.
    MANDATORY REQUIREMENT: Targets behind or outside attack direction NEVER take damage.
]]

local GameConfig = require(script.Parent.Parent.Config.GameConfig)

local CombatHelper = {}

-- Checks if targetPosition is within maxAngleDegrees in front of attackerCFrame
function CombatHelper.IsInDirection(attackerCFrame: CFrame, targetPosition: Vector3, maxAngleDegrees: number): boolean
    if maxAngleDegrees >= 360 then
        return true -- Full 360 AoE attack (e.g., Domain/Spatial field)
    end

    local forwardVector = attackerCFrame.LookVector
    local toTarget = targetPosition - attackerCFrame.Position

    -- If target is directly on top of attacker, consider within direction
    if toTarget.Magnitude < 0.1 then
        return true
    end

    local directionToTarget = toTarget.Unit
    local dotProduct = forwardVector:Dot(directionToTarget)
    local angleDegrees = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))

    -- Half-angle check from center look vector
    local halfAngle = maxAngleDegrees / 2
    return angleDegrees <= halfAngle
end

-- Checks if target is within maximum distance
function CombatHelper.IsInDistance(origin: Vector3, targetPosition: Vector3, maxDistance: number): boolean
    local distance = (targetPosition - origin).Magnitude
    return distance <= maxDistance
end

-- Full directional and range validation for a target part
function CombatHelper.ValidateHit(attackerCFrame: CFrame, targetPart: BasePart, maxRange: number, maxAngleDegrees: number): boolean
    local targetPos = targetPart.Position
    local inDistance = CombatHelper.IsInDistance(attackerCFrame.Position, targetPos, maxRange)
    if not inDistance then
        return false
    end

    local inDirection = CombatHelper.IsInDirection(attackerCFrame, targetPos, maxAngleDegrees)
    return inDirection
end

-- Validates that target is alive and valid combatant (Player or NPC)
function CombatHelper.IsAlive(character: Model?): (boolean, Humanoid?)
    if not character or not character.Parent then
        return false, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, nil
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not rootPart:IsA("BasePart") then
        return false, nil
    end

    return true, humanoid
end

-- Scales damage based on character level: BaseDamage * (1 + 0.025 * (Level - 1))
function CombatHelper.CalculateDamage(baseDamage: number, level: number): number
    return GameConfig.CalculateDamage(baseDamage, level)
end

return table.freeze(CombatHelper)
