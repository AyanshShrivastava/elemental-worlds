--!strict
--[[
    Elemental Worlds: Status Effect Service
    Server-authoritative status effect management, invulnerability checks, and cleanup.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local StatusTypes = require(ReplicatedStorage.Shared.Modules.StatusEffectTypes)
local VFXBroadcastService = require(script.Parent.VFXBroadcastService)

export type ActiveEffect = StatusTypes.ActiveEffect
export type StatusEffectName = StatusTypes.StatusEffectName

local StatusEffectService = {}

-- character instance -> effectName -> ActiveEffect
local characterEffects: { [Model]: { [StatusEffectName]: ActiveEffect } } = {}

-- Applies a status effect with a specific duration
function StatusEffectService.ApplyEffect(
    character: Model,
    effectName: StatusEffectName,
    duration: number,
    sourcePlayer: Player?,
    data: { [string]: any }?
)
    if not characterEffects[character] then
        characterEffects[character] = {}

        -- Bind cleanup on death or removing
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Once(function()
                StatusEffectService.ClearAllEffects(character)
            end)
        end
        character.Destroying:Once(function()
            StatusEffectService.ClearAllEffects(character)
        end)
    end

    local now = os.clock()
    local effect: ActiveEffect = {
        Name = effectName,
        StartTime = now,
        Duration = duration,
        EndTime = now + duration,
        SourcePlayer = sourcePlayer,
        Data = data,
    }

    characterEffects[character][effectName] = effect

    -- Apply immediate mechanics
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

    if effectName == "Stunned" or effectName == "TimeStopped" or effectName == "UnparalleledStun" then
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        if rootPart and (effectName == "TimeStopped" or effectName == "UnparalleledStun") then
            rootPart.Anchored = true
        end
    elseif effectName == "SpeedBoost" then
        if humanoid then
            humanoid.WalkSpeed = 32 -- Doubled standard walkspeed
        end
    elseif effectName == "GotGlitched" then
        -- Set character invisible on server (never touch HumanoidRootPart)
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if part:GetAttribute("OrigTrans") == nil then
                    part:SetAttribute("OrigTrans", part.Transparency)
                end
                part.Transparency = 1
            elseif part:IsA("Decal") then
                if part:GetAttribute("OrigTrans") == nil then
                    part:SetAttribute("OrigTrans", part.Transparency)
                end
                part.Transparency = 1
            end
        end
    elseif effectName == "Blinded" then
        -- Notify client to show blind overlay
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local vfxEvent = remotes:FindFirstChild(GameConfig.REMOTES.VFX_TRIGGER) :: RemoteEvent?
                if vfxEvent then
                    vfxEvent:FireClient(player, "Blind", { Duration = duration })
                end
            end
        end
    end

    -- Schedule removal
    task.delay(duration, function()
        -- Verify effect wasn't replaced by a newer one
        local current = characterEffects[character] and characterEffects[character][effectName]
        if current and current.StartTime == now then
            StatusEffectService.RemoveEffect(character, effectName)
        end
    end)
end

function StatusEffectService.HasEffect(character: Model, effectName: StatusEffectName): boolean
    local effects = characterEffects[character]
    if not effects then return false end
    local effect = effects[effectName]
    if not effect then return false end

    if os.clock() >= effect.EndTime then
        StatusEffectService.RemoveEffect(character, effectName)
        return false
    end

    return true
end

-- Checks if character can currently take damage (checks Untouchable & GotGlitched)
function StatusEffectService.CanTakeDamage(character: Model): boolean
    if StatusEffectService.HasEffect(character, "Untouchable") then
        return false -- Time: Untouchable stops all incoming attacks
    end
    if StatusEffectService.HasEffect(character, "GotGlitched") then
        return false -- Error: Got Glitched is immune to all damage
    end
    return true
end

-- Checks if character can cast normal abilities
function StatusEffectService.CanCastAbilities(character: Model): boolean
    if StatusEffectService.HasEffect(character, "Stunned") then
        return false
    end
    if StatusEffectService.HasEffect(character, "TimeStopped") then
        return false
    end
    if StatusEffectService.HasEffect(character, "UnparalleledStun") then
        return false
    end
    return true
end

-- Removes a specific status effect
function StatusEffectService.RemoveEffect(character: Model, effectName: StatusEffectName)
    local effects = characterEffects[character]
    if not effects or not effects[effectName] then return end

    effects[effectName] = nil

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

    if effectName == "Stunned" or effectName == "TimeStopped" or effectName == "UnparalleledStun" or effectName == "SpeedBoost" then
        if humanoid then
            humanoid.WalkSpeed = 16 -- Standard walkspeed
            humanoid.JumpPower = 50
        end
        if rootPart and (effectName == "TimeStopped" or effectName == "UnparalleledStun") then
            rootPart.Anchored = false
        end
    elseif effectName == "GotGlitched" then
        -- Restore visibility on server using saved original transparencies
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local orig = part:GetAttribute("OrigTrans")
                part.Transparency = if typeof(orig) == "number" then orig else 0
                part:SetAttribute("OrigTrans", nil)
            elseif part:IsA("Decal") then
                local orig = part:GetAttribute("OrigTrans")
                part.Transparency = if typeof(orig) == "number" then orig else 0
                part:SetAttribute("OrigTrans", nil)
            end
        end
        -- Enforce client visibility restoration
        VFXBroadcastService.Broadcast("GlitchInvisEnd", { Character = character })
    end
end

-- Clear all effects on death / destroy
function StatusEffectService.ClearAllEffects(character: Model)
    local effects = characterEffects[character]
    if not effects then return end

    for effectName in effects do
        StatusEffectService.RemoveEffect(character, effectName)
    end
    characterEffects[character] = nil
    VFXBroadcastService.Broadcast("GlitchInvisEnd", { Character = character })
end

return table.freeze(StatusEffectService)
