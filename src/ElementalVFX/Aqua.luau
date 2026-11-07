--!strict
-- Aqua.luau — Top-Tier Aqua Element VFX
-- High-pressure hydrodynamic streams, 3D sculpted vortices,
-- negative divergent shock rings, and fluid anime water physics.

local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local BLUE = Color3.fromRGB(0, 120, 255)
local CYAN = Color3.fromRGB(0, 240, 255)
local TURQUOISE = Color3.fromRGB(60, 230, 210)
local DEEP_OCEAN = Color3.fromRGB(5, 45, 140)
local WATER = Core.seq({ CYAN, TURQUOISE, BLUE, DEEP_OCEAN })
local WATER_FOAM = Core.seq({ Color3.fromRGB(240, 255, 255), CYAN, BLUE })

local Aqua = {}

-- M1: Rapid Hydro Cleave (0.05s anime cut + negative divergent ring)
function Aqua.M1(ctx)
	local dir = ctx.direction
	local hands = {
		Core.getPart(ctx.character, { "LeftHand", "Left Arm" }),
		Core.getPart(ctx.character, { "RightHand", "Right Arm" }),
	}
	for i, hand in ipairs(hands) do
		if hand then
			task.delay((i - 1) * 0.08, function()
				local origin = hand.Position + dir * 2.0
				local cleaveCF = Core.lookCF(origin, dir) * CFrame.Angles(0, 0, math.rad((i == 1 and -30 or 30)))

				-- Instant Cleave with Water ColorSequence
				Core.dismantleCleave(cleaveCF, WATER, 8)

				-- Negative Divergent Ring (LightEmission = -20)
				local ringAnchor = Core.anchor(origin)
				local ring = Core.emitter(Core.attach(ringAnchor), {
					texture = Core.PinnacleTextures.DivergentRing,
					color = WATER,
					light = -20,
					rate = 0,
					lifetime = NumberRange.new(0.2, 0.3),
					speed = NumberRange.new(0.1, 0.5),
					size = NumberSequence.new(2, 7),
					orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					zOffset = 10,
				})
				ring:Emit(1)

				-- Water Droplet Splash
				Core.burst(origin, 18, {
					texture = Core.Textures.WaterDroplet,
					color = WATER_FOAM,
					speed = 22,
					life = 0.4,
					light = 0.8,
				})
				Core.cleanupLater({ ringAnchor }, 0.6)
			end)
		end
	end
end

-- Move1: Water Hand (Sculpted Hydro Blade / Hand + Animated Water Beams + Tidal Geyser)
function Aqua.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dir = (target - origin).Unit
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 55, 0.25)

	-- 3D Sculpted Wave Mesh (`rbxassetid://2689837482`)
	local wavePart, waveMesh = Core.meshPart(Core.Meshes.WaveMesh, Vector3.new(8, 6, 12), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.15,
	})

	-- Animated Water Stream Beams (`rbxassetid://10820007429`)
	local att0 = Core.attach(wavePart, Vector3.new(0, 0, 4))
	local att1 = Core.attach(wavePart, Vector3.new(0, 0, -4))
	local waterBeam = Core.beam(att0, att1, {
		texture = Core.PinnacleTextures.WaterBeam15,
		color = WATER,
		width0 = 6,
		width1 = 4,
		light = 0.9,
		textureSpeed = 4,
	})

	-- Water droplet wake
	local droplets = Core.emitter(att1, {
		texture = Core.Textures.WaterDroplet,
		color = WATER_FOAM,
		rate = 60,
		lifetime = NumberRange.new(0.3, 0.6),
		speed = NumberRange.new(6, 16),
		spread = Vector2.new(15, 15),
		size = NumberSequence.new(0.7, 0.1),
		light = 0.85,
	})

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local currentPos = origin:Lerp(target, k)
		wavePart.CFrame = Core.lookCF(currentPos, dir)
	end, function()
		droplets.Enabled = false
		waterBeam:Destroy()
		wavePart:Destroy()

		-- Impact: Tidal Geyser with 3D Bonk Mesh & Negative Water Rings
		Core.groundSlamCrater(target, WATER, 14, { duration = 2.0, rockCount = 18 })
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 2,
			to = 26,
			duration = 0.6,
		})
	end)
end

-- Move2: Vortex of Destruction (3D Sculpted Spinning Vortex Mesh + Concentric Hydro Discs)
function Aqua.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dir = (target - origin).Unit
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 45, 0.35)

	-- 3D Sculpted SpinnyThings Mesh (`rbxassetid://6133078795`) spinning at -1000 deg/s
	local vortexPart, vortexMesh = Core.meshPart(Core.Meshes.SpinnyThings, Vector3.new(10, 3, 10), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.15,
		spin = Vector3.new(0, 0, -18),
	})

	-- Secondary Core Orb (`FancySphere`)
	local corePart, cMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 4.5, Core.lookCF(origin, dir), {
		color = BLUE,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(6, 12, 6),
	})

	-- Helical water bands wrapping around vortex
	local att0 = Core.attach(vortexPart, Vector3.new(-2, 0, 2))
	local att1 = Core.attach(vortexPart, Vector3.new(2, 0, -2))
	local beam = Core.beam(att0, att1, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = WATER,
		width0 = 3,
		width1 = 3,
		curve0 = 4,
		curve1 = 4,
		textureSpeed = 6,
		light = 1,
	})

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local currentPos = origin:Lerp(target, k)
		vortexPart.CFrame = Core.lookCF(currentPos, dir)
		corePart.CFrame = CFrame.new(currentPos)
	end, function()
		beam:Destroy()
		vortexPart:Destroy()
		corePart:Destroy()

		-- Implosion & Shockwave
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 3,
			to = 32,
			duration = 0.7,
		})
		Core.burst(target, 35, {
			texture = Core.Textures.WaterDroplet,
			color = WATER_FOAM,
			speed = 30,
			life = 0.6,
			light = 1,
		})
		Core.groundSlamCrater(target, WATER, 12, { duration = 1.5, rockCount = 16 })
	end)
end

-- Move3: Water Dragon (Sculpted Spiral Dragon with Hydro Ribbons + Handle)
function Aqua.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local origin = r and (r.Position + r.CFrame.LookVector * 4) or ctx.origin
	local dir = ctx.direction
	local duration = ctx.duration or 5

	local dragonModel = Instance.new("Model")
	dragonModel.Name = "WaterDragonVFX"
	dragonModel.Parent = Core.Folder

	-- 3D Sculpted Dragon Head (`FancySphereLight` + `SlashEffect` jaw)
	local head, hMesh = Core.meshPart(Core.Meshes.FancySphereLight, Vector3.new(5, 5, 7), Core.lookCF(origin, dir), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.1,
		parent = dragonModel,
	})

	local jaw, jMesh = Core.meshPart(Core.Meshes.SlashEffect, Vector3.new(8, 0.6, 4), Core.lookCF(origin, dir) * CFrame.Angles(0, math.rad(90), 0), {
		color = BLUE,
		material = Enum.Material.Neon,
		transparency = 0.2,
		parent = dragonModel,
	})

	-- Body Ribbon Trail
	local att0 = Core.attach(head, Vector3.new(0, 1.8, 0))
	local att1 = Core.attach(head, Vector3.new(0, -1.8, 0))
	local trail = Core.trail(head, att0, att1, {
		color = WATER,
		lifetime = 0.8,
		light = 0.9,
	})

	-- Dragon spray emitters
	local spray = Core.emitter(att0, {
		texture = Core.Textures.WaterDroplet,
		color = WATER_FOAM,
		rate = 50,
		speed = NumberRange.new(8, 20),
		spread = Vector2.new(15, 15),
		size = NumberSequence.new(1.2, 0.1),
		light = 0.9,
	})

	local isAlive = true
	local targetPos = ctx.target
	local currentPos = origin

	-- Undulation flight
	local startClock = os.clock()
	local flightConn
	flightConn = RunService.Heartbeat:Connect(function()
		if not isAlive then
			flightConn:Disconnect()
			return
		end
		local dt = os.clock() - startClock
		local waveY = math.sin(dt * 8) * 1.5
		local waveX = math.cos(dt * 6) * 1.2
		local stepDir = (targetPos - currentPos)
		if stepDir.Magnitude > 2 then
			currentPos = currentPos + stepDir.Unit * 1.4 + Vector3.new(waveX * 0.1, waveY * 0.1, 0)
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

		-- Detonation: Massive 160-stud shockwave disc + tidal eruption
		Core.shockwave(Core.groundCF(p + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 3,
			to = 35,
			duration = 0.8,
		})
		Core.burst(p, 45, {
			texture = Core.Textures.WaterDroplet,
			color = WATER_FOAM,
			speed = 35,
			life = 0.7,
			light = 1,
		})
		Core.groundSlamCrater(p, WATER, 16, { duration = 2.0, rockCount = 20 })

		task.delay(0.5, function()
			dragonModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isAlive then handle:End() end
	end)

	return handle
end

-- Move4: Limitless Punches (Anime Barrage + Divergent Rings + Water Claws)
function Aqua.Move4(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target
	local count = 9
	local dir = (target - r.Position).Unit

	for i = 1, count do
		task.delay((i - 1) * 0.08, function()
			local offset = Vector3.new(
				Random.new():NextNumber(-2.5, 2.5),
				Random.new():NextNumber(-1.5, 2.5),
				Random.new():NextNumber(-1, 1)
			)
			local strikePos = target + offset
			local cleaveCF = Core.lookCF(strikePos, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-45, 45)))

			-- Micro-cleave cut
			Core.dismantleCleave(cleaveCF, WATER, 8)

			-- Negative Divergent Ring
			local ringAnchor = Core.anchor(strikePos)
			local ring = Core.emitter(Core.attach(ringAnchor), {
				texture = Core.PinnacleTextures.DivergentRing,
				color = WATER,
				light = -20,
				rate = 0,
				lifetime = NumberRange.new(0.2, 0.28),
				speed = NumberRange.new(0.1, 0.5),
				size = NumberSequence.new(1.5, 6),
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			})
			ring:Emit(1)
			Core.cleanupLater({ ringAnchor }, 0.5)

			-- Water burst droplets
			Core.burst(strikePos, 10, {
				texture = Core.Textures.WaterDroplet,
				color = WATER_FOAM,
				speed = 18,
				life = 0.35,
			})
		end)
	end

	-- Final finisher punch
	task.delay(count * 0.08 + 0.1, function()
		Core.groundSlamCrater(target, WATER, 18, { duration = 2.0, rockCount = 24 })
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = CYAN,
			from = 2,
			to = 30,
			duration = 0.6,
		})
	end)
end

return Aqua
