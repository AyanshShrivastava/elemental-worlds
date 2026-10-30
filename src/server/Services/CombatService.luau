--!strict
--[[
    Elemental Worlds: Combat Service
    Server-authoritative router for player ability casts.
    Performs validation (Cooldowns, Stuns, Elements, Error Meter) before executing abilities.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local CooldownService = require(script.Parent.CooldownService)
local StatusEffectService = require(script.Parent.StatusEffectService)
local PlayerDataService = require(script.Parent.PlayerDataService)

-- Element handlers
local FireElement = require(script.Parent.Parent.Elements.FireElement)
local AquaElement = require(script.Parent.Parent.Elements.AquaElement)
local EarthElement = require(script.Parent.Parent.Elements.EarthElement)
local LightElement = require(script.Parent.Parent.Elements.LightElement)
local WindElement = require(script.Parent.Parent.Elements.WindElement)
local ErrorElement = require(script.Parent.Parent.Elements.ErrorElement)
local TimeElement = require(script.Parent.Parent.Elements.TimeElement)

local CombatService = {}

local elementHandlers: { [string]: any } = {
    Fire = FireElement,
    Aqua = AquaElement,
    Earth = EarthElement,
    Light = LightElement,
    Wind = WindElement,
    Error = ErrorElement,
    Time = TimeElement,
}

function CombatService.ProcessCast(player: Player, slot: string)
    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        return
    end

    local profile = PlayerDataService.GetProfile(player)
    if not profile then return end

    local element = profile.Element
    local ability = AbilityConfig.GetAbility(element, slot)
    if not ability then
        return -- Invalid slot for this element
    end

    -- 1. Cooldown Check
    local isOnCooldown, remainingTime = CooldownService.IsOnCooldown(player, slot)
    if isOnCooldown then
        return
    end

    -- 2. Stun Check (Allow if move has CanCastWhileStunned set to true)
    if not ability.CanCastWhileStunned and not StatusEffectService.CanCastAbilities(char) then
        return
    end

    -- 3. Error Meter Check
    if ability.ErrorMeterCost and ability.ErrorMeterCost > 0 then
        if profile.ErrorMeter < ability.ErrorMeterCost then
            return -- Insufficient Error Meter
        end
    end

    -- Server-Authoritative: Start Cooldown
    CooldownService.StartCooldown(player, slot, ability.Cooldown)

    -- Notify client to trigger local animation and start visual cooldown timer
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local abilityRemote = remotes:FindFirstChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?
        if abilityRemote then
            abilityRemote:FireClient(player, slot, ability.Cooldown, ability.AnimationId, ability.AnimationMarker)
        end
    end

    -- Route to Element Handler
    local handler = elementHandlers[element]
    if handler then
        local methodName = if slot == "M1" then "CastM1" else ("CastMove" .. slot)
        if handler[methodName] then
            handler[methodName](player, char, rootPart)
        end
    end
end

return table.freeze(CombatService)
