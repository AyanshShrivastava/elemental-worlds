-- Dispatcher.lua
-- The one module you call from a LocalScript:
--
--   local VFX = require(ReplicatedStorage.ElementalVFX.Dispatcher)
--   VFX.Play("Fire", "Move1", { character = char, target = hitPosition })
--
-- Element names: "Aqua", "Fire", "Earth", "Light", "Wind", "Error", "Time"
-- Move names:    "M1", "Move1", "Move2", "Move3", "Move4", "Move5" (Error only)
--
-- Moves that keep something alive (Fire Move2, Aqua Move3, Earth Move1,
-- Error Move3/Move4, Time Move3) return a handle from Play. See each module's header.

local Core = require(script.Parent.Core)

local Dispatcher = {}

Dispatcher.Elements = {
	Aqua = require(script.Parent.Aqua),
	Fire = require(script.Parent.Fire),
	Earth = require(script.Parent.Earth),
	Light = require(script.Parent.Light),
	Wind = require(script.Parent.Wind),
	Error = require(script.Parent.Error),
	Time = require(script.Parent.Time),
}

function Dispatcher.Play(element, move, ctx)
	local mod = Dispatcher.Elements[element]
	if not mod then
		warn("[ElementalVFX] Unknown element: " .. tostring(element))
		return nil
	end
	local fn = mod[move]
	if not fn then
		warn("[ElementalVFX] " .. tostring(element) .. " has no move " .. tostring(move))
		return nil
	end
	return fn(Core.context(ctx or {}))
end

return Dispatcher
