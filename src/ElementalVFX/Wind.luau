--!strict
-- Wind.luau — Top-Tier Wind Element VFX
-- 3D sculpted Tornado and SpinnyThings vortices, -2000 deg/s TornadoSlash,
-- colossal 28-stud vacuum slashes, VelocityPerpendicular wind rings, and aerodynamic supersonic trails.

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

-- M1: Colossal Gale Blade Slash (28-stud wide vacuum cut, sweeps 45 studs forward, NO air cracks)
function Wind.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-25, 25)))

	-- Colossal 28-stud wide anime vacuum blade sweeping forward 45 studs
	Core.colossalSlash(cleaveCF, 45, WIND, {
		width = 28,
		height = 4.0,
		duration = 0.4,
		meshColor = TEAL,
		soundId = Core.Sounds.SwordSlash,
	})

	-- TornadoSlash (-2000 deg/s, VelocityPerpendicular)
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local slash = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		light = 0.85,
		rate = 0,
		lifetime = NumberRange.new(0.12, 0.22),
		speed = NumberRange.new(0.1, 0.5),
		rotSpeed = NumberRange.new(-2000, -2000),
		size = NumberSequence.new(3, 8),
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
		size = NumberSequence.new(2, 9),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 8,
	})

	slash:Emit(1)
	ring:Emit(1)
	Core.cleanupLater({ anchor }, 0.5)
end

-- Move1: Airy Vortex (Triple 3D Curved Slash Meshes traveling 120 studs forward)
function Wind.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local dir = ctx.direction.Unit
	local range = 120
	local target = ctx.target or (origin + dir * range)
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 65, 0.4)

	-- Spawn 3 Curved 3D SlashEffect Meshes (`rbxassetid://4572036304`)
	local slashes = {}
	for i = 1, 3 do
		local a = (i - 1) * (math.pi * 2 / 3)
		local offset = Vector3.new(math.cos(a) * 2.0, math.sin(a) * 2.0, 0)
		local slashPart, m = Core.meshPart(Core.Meshes.SlashEffect, Vector3.new(14, 0.8, 6), Core.lookCF(origin + offset, dir) * CFrame.Angles(0, math.rad(90), a), {
			color = TEAL,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		table.insert(slashes, slashPart)
	end

	-- Trailing -1200 deg/s wind vortex
	local anchor = Core.anchor(origin)
	local att = Core.attach(anchor)
	local vortexEmitter = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		rate = 45,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(2, 6),
		rotSpeed = NumberRange.new(-1200, -1200),
		size = NumberSequence.new(4, 9),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
	})

	Core.sound(origin, Core.Sounds.SwordSlash, 0.8, 1.2)

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local curPos = origin:Lerp(target, Core.smooth(k))
		anchor.Position = curPos
		for i, s in ipairs(slashes) do
			local a = (i - 1) * (math.pi * 2 / 3) + t * 14
			local offset = Vector3.new(math.cos(a) * 2.8, math.sin(a) * 2.8, 0)
			s.CFrame = Core.lookCF(curPos + offset, dir) * CFrame.Angles(0, math.rad(90), a)
		end
	end, function()
		vortexEmitter.Enabled = false
		Core.destroyAll(slashes)
		anchor:Destroy()

		-- Impact: Aerodynamic Shockwave + Impact Burst (Zero cracks in air!)
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = TEAL,
			from = 3,
			to = 32,
			duration = 0.55,
			meshId = Core.Meshes.ShockwaveColossal,
		})
		Core.impactExplosion(target, WIND, 20, {
			duration = 1.8,
			rockCount = 18,
			shakeDur = 0.35,
			shakeIntens = 2.2,
		})
	end)
end

-- Move2: The Cyclone of Fury (Towering 50-Stud Atmospheric Cyclone)
function Wind.Move2(ctx)
	local target = ctx.target or ctx.origin
	local radius = ctx.radius or 18
	local duration = ctx.duration or 5

	local cycloneModel = Instance.new("Model")
	cycloneModel.Name = "CycloneOfFuryVFX"
	cycloneModel.Parent = Core.Folder

	-- 1. 3D Sculpted Tornado Mesh (`rbxassetid://5705014362` or `rbxassetid://5732025462`)
	local tornadoMeshId = Core.Meshes.TornadoMesh or Core.Meshes.Tornado
	local tornadoPart, tMesh = Core.meshPart(tornadoMeshId, Vector3.new(radius * 1.8, 45, radius * 1.8), CFrame.new(target + Vector3.new(0, 22, 0)), {
		color = TEAL,
		material = Enum.Material.Neon,
		transparency = 0.25,
		spin = Vector3.new(0, -16, 0),
		parent = cycloneModel,
	})

	-- 2. 3D Sculpted SpinnyThings Mesh (`rbxassetid://6133078795`) at base
	local baseVortex, bMesh = Core.meshPart(Core.Meshes.SpinnyThings, Vector3.new(radius * 2.2, 2.5, radius * 2.2), Core.groundCF(target + Vector3.new(0, 0.5, 0)), {
		color = MINT,
		material = Enum.Material.Neon,
		transparency = 0.15,
		spin = Vector3.new(0, 0, -25),
		parent = cycloneModel,
	})

	-- 3. Thick Dust Column (AnimeSmoke Grid8x8)
	local att = Core.attach(baseVortex)
	local dustColumn = Core.emitter(att, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST),
		rate = 45,
		lifetime = NumberRange.new(1.0, 1.8),
		speed = NumberRange.new(25, 42),
		spread = Vector2.new(18, 18),
		direction = Enum.NormalId.Top,
		size = NumberSequence.new(radius * 0.5, radius * 1.8),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.Loop,
		flipbookFramerate = NumberRange.new(24, 24),
		zOffset = 6,
	})

	-- 4. Rotating Debris Rings in VelocityPerpendicular
	local ringEmitter = Core.emitter(att, {
		texture = Core.PinnacleTextures.TornadoSlash,
		color = WIND,
		rate = 35,
		lifetime = NumberRange.new(0.3, 0.5),
		speed = NumberRange.new(1, 4),
		rotSpeed = NumberRange.new(-1400, -1400),
		size = NumberSequence.new(radius * 0.9, radius * 1.8),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 10,
	})

	Core.cameraShake(0.5, 2.6)

	Core.runFor(duration, function(_, t)
		if t >= duration - 1.0 then
			local k = (t - (duration - 1.0)) / 1.0
			tornadoPart.Transparency = 0.25 + 0.75 * k
			baseVortex.Transparency = 0.15 + 0.85 * k
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
	local drillPart, mesh = Core.meshPart(Core.Meshes.Vento2, Vector3.new(7, 7, 10), r.CFrame, {
		color = TEAL,
		material = Enum.Material.Neon,
		transparency = 0.35,
		spin = Vector3.new(0, 0, -28),
	})

	local att = Core.attach(drillPart)
	local speedRing = Core.emitter(att, {
		texture = Core.PinnacleTextures.WindRingPerp,
		color = AERO,
		rate = 30,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(2, 6),
		rotSpeed = NumberRange.new(-60, 60),
		size = NumberSequence.new(4, 9),
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
			drillPart.Transparency = 0.35 + 0.65 * k
			speedRing.Enabled = false
		end
	end, function()
		conn:Disconnect()
		drillPart:Destroy()
	end)
end

-- Move4: Wind: Death Speed (Supersonic Slaughter Combo + 10 Colossal Crescent Slashes)
function Wind.Move4(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target or (r.Position + ctx.direction * 35)
	local origin = r.Position

	-- 1. Pre-dash suction vortex
	Core.converge(origin, 12, 30, 0.35, TEAL)
	Core.shockwave(Core.groundCF(origin + Vector3.new(0, 0.2, 0)), {
		color = TEAL,
		from = 2,
		to = 20,
		duration = 0.4,
	})

	task.delay(0.3, function()
		-- 2. Supersonic Teleport Streak
		Core.afterimage(char, { color = TEAL, life = 0.4 })
		Core.tempBeam(origin, target, 0.25, {
			texture = Core.PinnacleTextures.HelicalBeam,
			color = WIND,
			width0 = 5,
			width1 = 1,
			light = 1,
		})

		-- 3. Criss-crossing 28-stud crescent vacuum slashes across the target area
		for i = 1, 8 do
			task.delay((i - 1) * 0.06, function()
				local angle = (i * 45) + Random.new():NextNumber(-15, 15)
				local offset = Vector3.new(math.cos(math.rad(angle)) * 6, Random.new():NextNumber(-2, 4), math.sin(math.rad(angle)) * 6)
				local slashCF = Core.lookCF(target + offset, (target - (target + offset)).Unit) * CFrame.Angles(0, 0, math.rad(angle))
				Core.colossalSlash(slashCF, 35, WIND, {
					width = 24,
					height = 3.5,
					duration = 0.3,
					meshColor = TEAL,
				})
			end)
		end

		-- 4. Final Sonic Shockwave Blast & Impact (Zero air cracks!)
		task.delay(8 * 0.06 + 0.1, function()
			Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
				color = TEAL,
				from = 4,
				to = 38,
				duration = 0.7,
				meshId = Core.Meshes.ShockwaveColossal,
			})
			Core.impactExplosion(target, WIND, 26, {
				duration = 2.2,
				rockCount = 26,
				shakeDur = 0.65,
				shakeIntens = 3.6,
			})
			Core.sound(target, Core.Sounds.Explosion, 1.0, 0.9)
		end)
	end)
end

return Wind
