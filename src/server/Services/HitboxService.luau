--!strict
--[[
    Elemental Worlds: Hitbox & Target Resolution Service
    Authoritative spatial queries supporting Players and NPCs in nested folders.
    MANDATORY: Directional verification via CombatHelper guarantees no damage to targets behind or outside cone.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatHelper = require(ReplicatedStorage.Shared.Modules.CombatHelper)
local StatusEffectService = require(script.Parent.StatusEffectService)
local PlayerDataService = require(script.Parent.PlayerDataService)

export type ValidTarget = {
    Character: Model,
    Humanoid: Humanoid,
    RootPart: BasePart,
}

local HitboxService = {}

-- Collect all potential combat characters in workspace (Players and nested NPCs)
local function GetAllCombatants(ignoreCharacter: Model?): { Model }
    local combatants: { Model } = {}

    -- 1. Check all connected players
    for _, player in Players:GetPlayers() do
        local char = player.Character
        if char and char ~= ignoreCharacter then
            table.insert(combatants, char)
        end
    end

    -- 2. Check NPCs folder (including any nested subfolders)
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, desc in npcsFolder:GetDescendants() do
            if desc:IsA("Model") and desc ~= ignoreCharacter and desc:FindFirstChildOfClass("Humanoid") then
                table.insert(combatants, desc)
            end
        end
    end

    -- 3. Check Workspace direct children for generic enemy models
    for _, child in Workspace:GetChildren() do
        if child:IsA("Model") and child ~= ignoreCharacter and not Players:GetPlayerFromCharacter(child) then
            if child:FindFirstChildOfClass("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
                table.insert(combatants, child)
            end
        end
    end

    return combatants
end

-- Finds all valid targets within a directional cone and range
function HitboxService.FindTargetsInCone(
    attackerCFrame: CFrame,
    maxRange: number,
    maxConeAngle: number,
    attackerCharacter: Model?
): { ValidTarget }
    local targets: { ValidTarget } = {}
    local combatants = GetAllCombatants(attackerCharacter)

    for _, candidate in combatants do
        local isAlive, humanoid = CombatHelper.IsAlive(candidate)
        if isAlive and humanoid then
            local rootPart = candidate:FindFirstChild("HumanoidRootPart") :: BasePart?
            if rootPart then
                -- CRITICAL: Validates both distance and look-direction cone
                local isValid = CombatHelper.ValidateHit(attackerCFrame, rootPart, maxRange, maxConeAngle)
                if isValid then
                    table.insert(targets, {
                        Character = candidate,
                        Humanoid = humanoid,
                        RootPart = rootPart,
                    })
                end
            end
        end
    end

    return targets
end

-- Finds a single closest target in cone (useful for targeted moves like Flames of Fury, Terra Finisher, Got Throwed)
function HitboxService.FindClosestTargetInCone(
    attackerCFrame: CFrame,
    maxRange: number,
    maxConeAngle: number,
    attackerCharacter: Model?
): ValidTarget?
    local targets = HitboxService.FindTargetsInCone(attackerCFrame, maxRange, maxConeAngle, attackerCharacter)
    local closest: ValidTarget? = nil
    local minDistance = math.huge

    for _, target in targets do
        local dist = (target.RootPart.Position - attackerCFrame.Position).Magnitude
        if dist < minDistance then
            minDistance = dist
            closest = target
        end
    end

    return closest
end

-- Authoritatively deals damage and applies on-hit effects
function HitboxService.ApplyDamage(
    attackerPlayer: Player?,
    target: ValidTarget,
    baseDamage: number,
    knockbackVector: Vector3?
): boolean
    local targetChar = target.Character
    local humanoid = target.Humanoid

    -- 1. Check if target can take damage (checks Untouchable & GotGlitched)
    if not StatusEffectService.CanTakeDamage(targetChar) then
        return false -- Immune!
    end

    -- 2. Check if Water Dragon transformation is active on target (ends on hit + burst)
    if StatusEffectService.HasEffect(targetChar, "WaterDragon") then
        StatusEffectService.RemoveEffect(targetChar, "WaterDragon")
        -- Trigger droplet burst damage around target
        local burstTargets = HitboxService.FindTargetsInCone(target.RootPart.CFrame, 15, 360, targetChar)
        for _, bTarget in burstTargets do
            bTarget.Humanoid:TakeDamage(15)
        end
    end

    -- 3. Calculate scaled damage based on attacker's level
    local attackerLevel = 1
    if attackerPlayer then
        local profile = PlayerDataService.GetProfile(attackerPlayer)
        if profile then
            attackerLevel = profile.Level

            -- If using Error element M1, add +5% to Error Meter on valid hit!
            if profile.Element == "Error" then
                PlayerDataService.AddErrorMeter(attackerPlayer, 5)
            end
        end
    end

    local finalDamage = CombatHelper.CalculateDamage(baseDamage, attackerLevel)
    humanoid:TakeDamage(finalDamage)

    -- 4. Apply knockback impulse if specified
    if knockbackVector and target.RootPart and not target.RootPart.Anchored then
        target.RootPart:ApplyImpulse(knockbackVector * target.RootPart.AssemblyMass)
    end

    return true
end

return table.freeze(HitboxService)
