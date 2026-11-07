--!strict
-- Wind.luau — Top-Tier Wind Element VFX
-- 3D sculpted Tornado and SpinnyThings vortices, -2000 deg/s TornadoSlash,
-- VelocityPerpendicular wind rings, and aerodynamic supersonic trails.

local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local WHITE = Color3.fromRGB(255, 255, 255)
local TEAL = Color3.fromRGB(150, 245, 230)
local EMERALD = Color3.fromRGB(60, 225, 160)
local MINT = Color3.fromRGB(180, 255, 220)
local DUST = Color3.fromRGB(210, 220, 215)
local WIND = Core.seq({ WHITE, MINT, TEAL, EMERALD })
local AERO = Core.seq({ WHITE, TEAL })

local Wind = {}

-- M1: Gale Cut (0.05s cleave + -2000 deg/s TornadoSlash in VelocityPerpendicular)
function Wind.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-30, 30)))

	-- 1. Micro-Cleave Instant Slash
	Core.dismantleCleave(cleaveCF, WIND, 8)

	-- 2. TornadoSlash (-2000 deg/s, VelocityPerpendicular)
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local slash = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		light = 0.8,
		rate = 0,
		lifetime = NumberRange.new(0.12, 0.22),
		speed = NumberRange.new(0.1, 0.5),
		rotSpeed = NumberRange.new(-2000, -2000),
		size = NumberSequence.new(3, 7),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 14,
	})

	-- Aerodynamic wind ring
	local ring = Core.emitter(att, {
		texture = Core.PinnacleTextures.WindRingPerp,
		color = AERO,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.15, 0.25),
		speed = NumberRange.new(0.1, 0.5),
		rotSpeed = NumberRange.new(-50, 50),
		size = NumberSequence.new(2, 8),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 8,
	})

	slash:Emit(1)
	ring:Emit(1)
	Core.cleanupLater({ anchor }, 0.5)
end

-- Move1: Airy Vortex (Triple 3D Curved Slash Meshes + Trailing Wind Rings)
function Wind.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dir = (target - origin).Unit
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 65, 0.25)

	-- Spawn 3 Curved 3D SlashEffect Meshes (`rbxassetid://4572036304`)
	local slashes = {}
	for i = 1, 3 do
		local a = (i - 1) * (math.pi * 2 / 3)
		local offset = Vector3.new(math.cos(a) * 1.5, math.sin(a) * 1.5, 0)
		local slashPart, m = Core.meshPart(Core.Meshes.SlashEffect, Vector3.new(12, 0.6, 5), Core.lookCF(origin + offset, dir) * CFrame.Angles(0, math.rad(90), a), {
			color = TEAL,
			material = Enum.Material.Neon,
			transparency = 0.15,
		})
		table.insert(slashes, slashPart)
	end

	-- Trailing -1000 deg/s wind vortex
	local anchor = Core.anchor(origin)
	local att = Core.attach(anchor)
	local vortexEmitter = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		rate = 40,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(2, 6),
		rotSpeed = NumberRange.new(-1000, -1000),
		size = NumberSequence.new(3, 7),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
	})

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local curPos = origin:Lerp(target, k)
		anchor.Position = curPos
		for i, s in ipairs(slashes) do
			local a = (i - 1) * (math.pi * 2 / 3) + t * 12
			local offset = Vector3.new(math.cos(a) * 2.2, math.sin(a) * 2.2, 0)
			s.CFrame = Core.lookCF(curPos + offset, dir) * CFrame.Angles(0, math.rad(90), a)
		end
	end, function()
		vortexEmitter.Enabled = false
		Core.destroyAll(slashes)
		anchor:Destroy()

		-- Impact: Aerodynamic Shockwave + Ground Dust
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = TEAL,
			from = 2,
			to = 26,
			duration = 0.5,
		})
		Core.burst(target, 25, {
			texture = Core.Textures.AnimeSmoke,
			color = ColorSequence.new(DUST),
			speed = 20,
			life = 0.6,
		})
	end)
end

-- Move2: The Cyclone of Fury (3D Sculpted Tornado Mesh + SpinnyThings Vortex)
function Wind.Move2(ctx)
	local target = ctx.target
	local radius = ctx.radius or 14
	local duration = ctx.duration or 5

	local cycloneModel = Instance.new("Model")
	cycloneModel.Name = "CycloneOfFuryVFX"
	cycloneModel.Parent = Core.Folder

	-- 1. 3D Sculpted Tornado Mesh (`rbxassetid://5705014362`)
	local tornadoPart, tMesh = Core.meshPart(Core.Meshes.Tornado, Vector3.new(radius * 1.5, 32, radius * 1.5), CFrame.new(target + Vector3.new(0, 16, 0)), {
		color = TEAL,
		material = Enum.Material.Neon,
		transparency = 0.35,
		spin = Vector3.new(0, -12, 0),
		parent = cycloneModel,
	})

	-- 2. 3D Sculpted SpinnyThings Mesh (`rbxassetid://6133078795`) at base
	local baseVortex, bMesh = Core.meshPart(Core.Meshes.SpinnyThings, Vector3.new(radius * 1.8, 2, radius * 1.8), Core.groundCF(target + Vector3.new(0, 0.5, 0)), {
		color = MINT,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(0, 0, -20),
		parent = cycloneModel,
	})

	-- 3. Thick Dust Column (AnimeSmoke Grid8x8)
	local att = Core.attach(baseVortex)
	local dustColumn = Core.emitter(att, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST),
		rate = 35,
		lifetime = NumberRange.new(1.0, 1.8),
		speed = NumberRange.new(20, 35),
		spread = Vector2.new(15, 15),
		direction = Enum.NormalId.Top,
		size = NumberSequence.new(radius * 0.4, radius * 1.5),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.Loop,
		flipbookFramerate = NumberRange.new(24, 24),
		zOffset = 6,
	})

	-- 4. Rotating Debris Rings in VelocityPerpendicular
	local ringEmitter = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		rate = 25,
		lifetime = NumberRange.new(0.3, 0.5),
		speed = NumberRange.new(1, 4),
		rotSpeed = NumberRange.new(-1200, -1200),
		size = NumberSequence.new(radius * 0.8, radius * 1.6),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 10,
	})

	Core.runFor(duration, function(_, t)
		if t >= duration - 1.0 then
			local k = (t - (duration - 1.0)) / 1.0
			tornadoPart.Transparency = 0.35 + 0.65 * k
			baseVortex.Transparency = 0.2 + 0.8 * k
			dustColumn.Enabled = false
			ringEmitter.Enabled = false
		end
	end, function()
		cycloneModel:Destroy()
	end)
end

-- Move3: Maximum Speed / Typhoon Rush (3D Vento2 Body Drill + Sonic Boom Rings)
function Wind.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local duration = ctx.duration or 5

	-- 3D Sculpted Vento2 Mesh (`rbxassetid://6063631009`) enveloping player
	local drillPart, mesh = Core.meshPart(Core.Meshes.Vento2, Vector3.new(6, 6, 8), r.CFrame, {
		color = TEAL,
		material = Enum.Material.Neon,
		transparency = 0.4,
		spin = Vector3.new(0, 0, -24),
	})

	local att = Core.attach(drillPart)
	local speedRing = Core.emitter(att, {
		texture = Core.PinnacleTextures.WindRingPerp,
		color = AERO,
		rate = 25,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(2, 6),
		rotSpeed = NumberRange.new(-60, 60),
		size = NumberSequence.new(3, 7),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 5,
	})

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not drillPart.Parent or not r.Parent then
			conn:Disconnect()
			return
		end
		drillPart.CFrame = r.CFrame
	end)

	Core.runFor(duration, function(_, t)
		if t >= duration - 0.8 then
			local k = (t - (duration - 0.8)) / 0.8
			drillPart.Transparency = 0.4 + 0.6 * k
			speedRing.Enabled = false
		end
	end, function()
		conn:Disconnect()
		drillPart:Destroy()
	end)
end

-- Move4: Wind: Death Speed (Supersonic Lightning Dash + Shockwave release)
function Wind.Move4(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target
	local origin = r.Position

	-- 1. Pre-dash suction vortex
	Core.converge(origin, 10, 25, 0.4, TEAL)
	Core.shockwave(Core.groundCF(origin + Vector3.new(0, 0.2, 0)), {
		color = TEAL,
		from = 1,
		to = 16,
		duration = 0.4,
	})

	task.delay(0.35, function()
		-- 2. Supersonic Teleport Streak
		Core.afterimage(char, { color = TEAL, life = 0.4 })
		Core.tempBeam(origin, target, 0.25, {
			texture = Core.PinnacleTextures.HelicalBeam,
			color = WIND,
			width0 = 4,
			width1 = 1,
			light = 1,
		})

		-- 3. Arrival: 3D LightWind Mesh Impact (`rbxassetid://4681227436`)
		local windPart, m = Core.meshPart(Core.Meshes.LightWind, Vector3.one * 12, Core.lookCF(target, ctx.direction), {
			color = MINT,
			material = Enum.Material.Neon,
			transparency = 0.15,
		})
		Core.runFor(0.4, function(_, t)
			windPart.Transparency = 0.15 + 0.85 * (t / 0.4)
		end, function()
			windPart:Destroy()
		end)

		-- 4. Micro-Cleaves & Sonic Blast
		Core.dismantleCleave(Core.lookCF(target, ctx.direction), WIND, 14)
		Core.groundSlamCrater(target, WIND, 18, { duration = 2.0, rockCount = 22 })
	end)
end

return Wind
