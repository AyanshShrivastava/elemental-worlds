--!strict
--[[
    Elemental Worlds: Combat Service
    Server-authoritative router for player ability casts.
    Validates cooldowns, stuns, elements, error meters, and combo steps.
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

function CombatService.ProcessCast(player: Player, slot: string, clientData: any?)
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
        return
    end

    -- 1. Cooldown Check
    local isOnCooldown, remainingTime = CooldownService.IsOnCooldown(player, slot)
    if isOnCooldown then
        return
    end

    -- 2. Stun Check
    if not ability.CanCastWhileStunned and not StatusEffectService.CanCastAbilities(char) then
        return
    end

    -- 3. Error Meter Check
    if ability.ErrorMeterCost and ability.ErrorMeterCost > 0 then
        if profile.ErrorMeter < ability.ErrorMeterCost then
            return
        end
    end

    -- Extract optional combo step for M1 (1, 2, 3, 4)
    local comboStep = 1
    if clientData and type(clientData) == "table" and type(clientData.ComboStep) == "number" then
        comboStep = math.clamp(math.floor(clientData.ComboStep), 1, 4)
    end

    -- M1 has a shorter internal cooldown (0.28s) to allow fluid combo chaining, while move 4 finisher adds slightly more
    local cooldown = if slot == "M1" then (if comboStep == 4 then 0.75 else 0.28) else ability.Cooldown
    CooldownService.StartCooldown(player, slot, cooldown)

    -- Notify client to trigger local animation and start visual cooldown timer
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local abilityRemote = remotes:FindFirstChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?
        if abilityRemote then
            abilityRemote:FireClient(player, slot, cooldown, ability.AnimationId, ability.AnimationMarker)
        end
    end

    -- Route to Element Handler
    local handler = elementHandlers[element]
    if handler then
        if slot == "M1" and handler.CastM1 then
            handler.CastM1(player, char, rootPart, comboStep)
        else
            local methodName = "CastMove" .. slot
            if handler[methodName] then
                handler[methodName](player, char, rootPart)
            end
        end
    end
end

return table.freeze(CombatService)
