--!strict
-- Aqua.luau — Top-Tier Aqua Element VFX
-- High-pressure hydrodynamic streams, 3D sculpted vortices,
-- negative divergent shock rings, 130-stud leviathan water dragon, and fluid anime water physics.

local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local BLUE = Color3.fromRGB(0, 120, 255)
local CYAN = Color3.fromRGB(0, 240, 255)
local TURQUOISE = Color3.fromRGB(60, 230, 210)
local DEEP_OCEAN = Color3.fromRGB(5, 45, 140)
local WHITE = Color3.fromRGB(240, 255, 255)
local WATER = Core.seq({ CYAN, TURQUOISE, BLUE, DEEP_OCEAN })
local WATER_FOAM = Core.seq({ WHITE, CYAN, BLUE })

local Aqua = {}

-- M1: Colossal Hydro Blade Slash (28-stud wide anime water cut, sweeps 42 studs forward, NO air cracks)
function Aqua.M1(ctx)
	local dir = ctx.direction
	local hands = {
		Core.getPart(ctx.character, { "RightHand", "Right Arm" }),
		Core.getPart(ctx.character, { "LeftHand", "Left Arm" }),
	}
	local hand = hands[1] or hands[2]
	if not hand then return end

	local origin = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(origin, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-25, 25)))

	-- Colossal 28-stud wide anime water blade sweeping forward 42 studs
	Core.colossalSlash(cleaveCF, 42, WATER, {
		width = 28,
		height = 4.5,
		duration = 0.42,
		meshColor = CYAN,
		soundId = Core.Sounds.WaterImpact,
	})

	-- Negative Divergent Ring at origin (LightEmission = -20)
	local ringAnchor = Core.anchor(origin)
	local ring = Core.emitter(Core.attach(ringAnchor), {
		texture = Core.PinnacleTextures.DivergentRing,
		color = WATER,
		light = -20,
		rate = 0,
		lifetime = NumberRange.new(0.2, 0.32),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(3, 10),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 10,
	})
	ring:Emit(2)

	-- Water Droplet Splash
	Core.burst(origin, 22, {
		texture = Core.Textures.WaterDroplet,
		color = WATER_FOAM,
		speed = 25,
		life = 0.45,
		light = 0.9,
	})
	Core.cleanupLater({ ringAnchor }, 0.6)
end

-- Move1: Water Hand / Tidal Wave Surge (Colossal 130-Stud Wave Palm Rush)
function Aqua.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local dir = ctx.direction.Unit
	local range = 130
	local target = ctx.target or (origin + dir * range)
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 65, 0.4)

	-- 3D Sculpted Wave Mesh (`rbxassetid://2689837482`) scaled to colossal 14x10x18 studs
	local wavePart, waveMesh = Core.meshPart(Core.Meshes.WaveMesh, Vector3.new(14, 10, 18), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.1,
	})

	-- Animated Water Stream Beams (`rbxassetid://10820007429`)
	local att0 = Core.attach(wavePart, Vector3.new(0, 0, 6))
	local att1 = Core.attach(wavePart, Vector3.new(0, 0, -6))
	local waterBeam = Core.beam(att0, att1, {
		texture = Core.PinnacleTextures.WaterBeam15,
		color = WATER,
		width0 = 10,
		width1 = 6,
		light = 0.95,
		textureSpeed = 5,
	})

	-- Water droplet wake
	local droplets = Core.emitter(att1, {
		texture = Core.Textures.WaterDroplet,
		color = WATER_FOAM,
		rate = 90,
		lifetime = NumberRange.new(0.4, 0.8),
		speed = NumberRange.new(8, 22),
		spread = Vector2.new(25, 25),
		size = NumberSequence.new(1.2, 0.1),
		light = 0.9,
	})

	Core.sound(origin, Core.Sounds.WaterImpact, 0.85, 0.9)

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local currentPos = origin:Lerp(target, Core.smooth(k))
		wavePart.CFrame = Core.lookCF(currentPos, dir)
	end, function()
		droplets.Enabled = false
		waterBeam:Destroy()
		wavePart:Destroy()

		-- Impact: Tidal Geyser & Shockwave (Zero cracks in air!)
		Core.impactExplosion(target, WATER, 22, {
			duration = 2.0,
			rockCount = 20,
			shakeDur = 0.35,
			shakeIntens = 2.4,
			meshColor = CYAN,
		})
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 3,
			to = 32,
			duration = 0.6,
		})
	end)
end

-- Move2: Vortex of Destruction (Colossal 120-Stud Hydro Vortex Cyclone)
function Aqua.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local dir = ctx.direction.Unit
	local range = 120
	local target = ctx.target or (origin + dir * range)
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 55, 0.45)

	-- 3D Sculpted SpinnyThings Mesh (`rbxassetid://6133078795`) spinning rapidly
	local vortexPart, vortexMesh = Core.meshPart(Core.Meshes.SpinnyThings, Vector3.new(15, 4, 15), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.12,
		spin = Vector3.new(0, 0, -22),
	})

	-- Secondary Core Orb (`FancySphere`)
	local corePart, cMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 6, Core.lookCF(origin, dir), {
		color = BLUE,
		material = Enum.Material.Neon,
		transparency = 0.15,
		spin = Vector3.new(8, 15, 8),
	})

	-- Helical water bands wrapping around vortex
	local att0 = Core.attach(vortexPart, Vector3.new(-3, 0, 3))
	local att1 = Core.attach(vortexPart, Vector3.new(3, 0, -3))
	local beam = Core.beam(att0, att1, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = WATER,
		width0 = 4.5,
		width1 = 4.5,
		curve0 = 6,
		curve1 = 6,
		textureSpeed = 7,
		light = 1,
	})

	Core.sound(origin, Core.Sounds.WaterImpact, 0.8, 1.05)

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local currentPos = origin:Lerp(target, Core.smooth(k))
		vortexPart.CFrame = Core.lookCF(currentPos, dir)
		corePart.CFrame = CFrame.new(currentPos)
	end, function()
		beam:Destroy()
		vortexPart:Destroy()
		corePart:Destroy()

		-- Implosion & Colossal Shockwave
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 3,
			to = 36,
			duration = 0.7,
			meshId = Core.Meshes.ShockwaveColossal,
		})
		Core.burst(target, 45, {
			texture = Core.Textures.WaterDroplet,
			color = WATER_FOAM,
			speed = 35,
			life = 0.65,
			light = 1,
		})
		Core.impactExplosion(target, WATER, 24, {
			duration = 2.0,
			rockCount = 22,
			shakeDur = 0.42,
			shakeIntens = 2.7,
		})
	end)
end

-- Move3: Water Dragon (130-Stud Undulating Leviathan Dragon)
function Aqua.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local origin = r and (r.Position + r.CFrame.LookVector * 4) or ctx.origin
	local dir = ctx.direction.Unit
	local range = 130
	local targetPos = ctx.target or (origin + dir * range)
	local duration = ctx.duration or 5

	local dragonModel = Instance.new("Model")
	dragonModel.Name = "WaterDragonVFX"
	dragonModel.Parent = Core.Folder

	-- 3D Sculpted Dragon Head (`FancySphereLight` + `SlashEffect` jaw)
	local head, hMesh = Core.meshPart(Core.Meshes.FancySphereLight, Vector3.new(7, 7, 9), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.08,
		parent = dragonModel,
	})

	local jaw, jMesh = Core.meshPart(Core.Meshes.SlashEffect, Vector3.new(10, 0.8, 5.5), Core.lookCF(origin, dir) * CFrame.Angles(0, math.rad(90), 0), {
		color = BLUE,
		material = Enum.Material.Neon,
		transparency = 0.15,
		parent = dragonModel,
	})

	-- Body Ribbon Trail
	local att0 = Core.attach(head, Vector3.new(0, 2.5, 0))
	local att1 = Core.attach(head, Vector3.new(0, -2.5, 0))
	local trail = Core.trail(head, att0, att1, {
		color = WATER,
		lifetime = 1.0,
		light = 0.95,
	})

	-- Dragon spray emitters
	local spray = Core.emitter(att0, {
		texture = Core.Textures.WaterDroplet,
		color = WATER_FOAM,
		rate = 70,
		speed = NumberRange.new(10, 24),
		spread = Vector2.new(20, 20),
		size = NumberSequence.new(1.6, 0.1),
		light = 0.95,
	})

	local isAlive = true
	local currentPos = origin

	-- Undulation flight towards target
	local startClock = os.clock()
	local flightConn
	flightConn = RunService.Heartbeat:Connect(function()
		if not isAlive then
			flightConn:Disconnect()
			return
		end
		local dt = os.clock() - startClock
		local waveY = math.sin(dt * 8) * 2.0
		local waveX = math.cos(dt * 6) * 1.6
		local stepDir = (targetPos - currentPos)
		if stepDir.Magnitude > 3 then
			currentPos = currentPos + stepDir.Unit * 1.8 + Vector3.new(waveX * 0.15, waveY * 0.15, 0)
			head.CFrame = Core.lookCF(currentPos, stepDir.Unit)
			jaw.CFrame = head.CFrame * CFrame.Angles(0, math.rad(90), 0)
		end
	end)

	local handle = {}

	function handle:End(hitPos: Vector3?)
		if not isAlive then return end
		isAlive = false
		local p = hitPos or currentPos
		spray.Enabled = false

		-- Detonation: Massive 38-stud shockwave disc + tidal eruption + camera shake
		Core.shockwave(Core.groundCF(p + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 4,
			to = 38,
			duration = 0.85,
			meshId = Core.Meshes.ShockwaveColossal,
		})
		Core.burst(p, 55, {
			texture = Core.Textures.WaterDroplet,
			color = WATER_FOAM,
			speed = 40,
			life = 0.75,
			light = 1,
		})
		Core.impactExplosion(p, WATER, 26, {
			duration = 2.2,
			rockCount = 26,
			shakeDur = 0.55,
			shakeIntens = 3.2,
		})
		Core.sound(p, Core.Sounds.WaterImpact, 1.0, 0.85)

		task.delay(0.5, function()
			dragonModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isAlive then handle:End() end
	end)

	return handle
end

-- Move4: Limitless Punches (Anime Hydro Barrage + Divergent Rings + Colossal Tidal Finisher)
function Aqua.Move4(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target or (r.Position + ctx.direction * 30)
	local count = 12
	local dir = (target - r.Position).Unit

	for i = 1, count do
		task.delay((i - 1) * 0.07, function()
			local offset = Vector3.new(
				Random.new():NextNumber(-3.5, 3.5),
				Random.new():NextNumber(-2.0, 3.5),
				Random.new():NextNumber(-2, 2)
			)
			local strikePos = target + offset
			local cleaveCF = Core.lookCF(strikePos, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-45, 45)))

			-- 14-stud anime hydro cut (air burst glint, NO cracks in air!)
			Core.dismantleCleave(cleaveCF, WATER, 12)

			-- Negative Divergent Ring
			local ringAnchor = Core.anchor(strikePos)
			local ring = Core.emitter(Core.attach(ringAnchor), {
				texture = Core.PinnacleTextures.DivergentRing,
				color = WATER,
				light = -20,
				rate = 0,
				lifetime = NumberRange.new(0.2, 0.3),
				speed = NumberRange.new(0.1, 0.5),
				size = NumberSequence.new(2, 8),
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			})
			ring:Emit(1)
			Core.cleanupLater({ ringAnchor }, 0.5)

			-- Water burst droplets
			Core.burst(strikePos, 14, {
				texture = Core.Textures.WaterDroplet,
				color = WATER_FOAM,
				speed = 22,
				life = 0.35,
			})
		end)
	end

	-- Final finisher punch: Colossal Tidal Blast
	task.delay(count * 0.07 + 0.1, function()
		Core.impactExplosion(target, WATER, 28, {
			duration = 2.5,
			rockCount = 30,
			shakeDur = 0.65,
			shakeIntens = 3.6,
			meshColor = CYAN,
		})
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 3,
			to = 38,
			duration = 0.7,
			meshId = Core.Meshes.ShockwaveColossal,
		})
		Core.sound(target, Core.Sounds.WaterImpact, 1.0, 0.8)
	end)
end

return Aqua
