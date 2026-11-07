--!strict
-- Earth.luau — Top-Tier Earth Element VFX
-- Multi-pass layering with custom 3D sculpted GroundSpikes,
-- 130-stud crystalline boulder launch, 700 deg/s tumbling shrapnel physics, and strict ground-only craters.

local Core = require(script.Parent.Core)

local STONE = Color3.fromRGB(150, 145, 140)
local BROWN = Color3.fromRGB(120, 85, 55)
local DUST_C = Color3.fromRGB(195, 185, 165)
local DARK_CRATER = Color3.fromRGB(45, 35, 28)
local EARTH = Core.seq({ STONE, BROWN, DUST_C })
local MAGMA_GLOW = Color3.fromRGB(255, 120, 30)

local Earth = {}

Earth.WALL = {
	duration = 8,
	collidable = true,
	sinkTime = 0.6,
	cols = 5,
	pillarW = 3.8,
	pillarH = 13,
}

-- M1: Seismic Stone Cleave (24-stud stone blade cut, tumbling shrapnel, NO cracks in air!)
function Earth.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-25, 25)))

	-- 24-stud stone blade slash sweeping 35 studs forward
	Core.colossalSlash(cleaveCF, 35, EARTH, {
		width = 24,
		height = 4.5,
		duration = 0.38,
		meshColor = STONE,
		soundId = Core.Sounds.EarthImpact,
	})

	-- Tumbling Physics Rocks (particles, not decal cracks)
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local rocks = Core.emitter(att, {
		texture = Core.PinnacleTextures.TumblingRock,
		color = ColorSequence.new(STONE),
		light = 0,
		rate = 0,
		lifetime = NumberRange.new(0.4, 0.7),
		speed = NumberRange.new(14, 26),
		spread = Vector2.new(45, 45),
		direction = Enum.NormalId.Front,
		acceleration = Vector3.new(0, -171.5, 0),
		drag = 2.5,
		rotSpeed = NumberRange.new(-700, 700),
		size = NumberSequence.new(1.0, 0.2),
	})
	rocks:Emit(10)

	-- Dust puff
	Core.burst(start, 12, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST_C),
		speed = 12,
		life = 0.5,
	})
	Core.cleanupLater({ anchor }, 0.8)
end

-- Move1: Earthy Wall (Sculpted 3D GroundSpikes Eruption on Verified Ground)
function Earth.Move1(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local center = r and (r.Position + r.CFrame.LookVector * 8) or (ctx.origin + ctx.direction * 8)
	local wallDir = r and r.CFrame.RightVector or Vector3.new(1, 0, 0)
	local duration = Earth.WALL.duration

	-- Raycast down to verify ground surface
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { Core.Folder }
	local rayResult = workspace:Raycast(center + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), rayParams)
	local groundY = rayResult and rayResult.Position.Y or (center.Y - 2.5)
	local baseCenter = Vector3.new(center.X, groundY, center.Z)

	local wallModel = Instance.new("Model")
	wallModel.Name = "EarthWallVFX"
	wallModel.Parent = Core.Folder

	local spikes = {}
	local numPillars = Earth.WALL.cols
	local pillarWidth = Earth.WALL.pillarW
	local pillarHeight = Earth.WALL.pillarH

	-- Ground Crater and Dust along the wall line (Strictly on ground)
	Core.groundCrater(baseCenter, EARTH, 14, { duration = 1.8, rockCount = 18, useMesh = false })

	-- Erupt sculpted 3D GroundSpikes (`rbxassetid://967645205`)
	for i = 1, numPillars do
		local offset = wallDir * ((i - (numPillars + 1) * 0.5) * pillarWidth)
		local p = baseCenter + offset
		local cf = Core.lookCF(p, r and r.CFrame.LookVector or ctx.direction) * CFrame.Angles(math.rad(Random.new():NextNumber(-6, 6)), 0, 0)

		local spike, mesh = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(pillarWidth, pillarHeight, 3.5), cf, {
			color = STONE,
			material = Enum.Material.Rock,
			transparency = 0,
			parent = wallModel,
		})
		table.insert(spikes, spike)
	end

	-- Rise smoothly from ground
	local targetCenter = baseCenter + Vector3.new(0, pillarHeight * 0.5, 0)
	local undergroundCenter = baseCenter - Vector3.new(0, pillarHeight * 0.5, 0)
	Core.runFor(0.25, function(_, t)
		local k = Core.smooth(t / 0.25)
		for i, spike in ipairs(spikes) do
			local offset = wallDir * ((i - (numPillars + 1) * 0.5) * pillarWidth)
			local curP = undergroundCenter:Lerp(targetCenter, k) + offset
			spike.CFrame = CFrame.new(curP) * spike.CFrame.Rotation
		end
	end)

	Core.sound(baseCenter, Core.Sounds.EarthImpact, 0.85, 0.95)
	Core.cameraShake(0.25, 1.8)

	local isAlive = true
	local handle = {}

	function handle:SetHealth(pct: number)
		if not isAlive then return end
		if pct <= 0 then
			handle:Shatter()
		else
			for _, spike in ipairs(spikes) do
				local shake = Vector3.new(Random.new():NextNumber(-0.3, 0.3), 0, Random.new():NextNumber(-0.3, 0.3))
				spike.Position = spike.Position + shake
			end
			Core.burst(baseCenter, 14, {
				texture = Core.PinnacleTextures.TumblingRock,
				color = ColorSequence.new(STONE),
				speed = 16,
				life = 0.5,
			})
		end
	end

	function handle:Shatter()
		if not isAlive then return end
		isAlive = false
		Core.impactExplosion(baseCenter, EARTH, 18, { duration = 2.0, rockCount = 28 })
		Core.burst(baseCenter, 35, {
			texture = Core.Textures.AnimeSmoke,
			color = ColorSequence.new(DUST_C),
			speed = 28,
			life = 0.8,
		})
		wallModel:Destroy()
	end

	function handle:End()
		if not isAlive then return end
		isAlive = false
		Core.runFor(Earth.WALL.sinkTime, function(_, t)
			local k = Core.smooth(t / Earth.WALL.sinkTime)
			for i, spike in ipairs(spikes) do
				local offset = wallDir * ((i - (numPillars + 1) * 0.5) * pillarWidth)
				local curP = targetCenter:Lerp(undergroundCenter, k) + offset
				spike.CFrame = CFrame.new(curP) * spike.CFrame.Rotation
			end
		end, function()
			wallModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isAlive then handle:End() end
	end)

	return handle
end

-- Move2: Boulder of Destruction (Colossal 130-Stud Crystalline Boulder Launch)
function Earth.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local dir = ctx.direction.Unit
	local range = 130
	local target = ctx.target or (origin + dir * range)
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 55, 0.45)

	-- 3D Sculpted Boulder Mesh (`rbxassetid://4933939180`) scaled to colossal 8 studs
	local boulder, bMesh = Core.meshPart(Core.Meshes.ExplosionCube, Vector3.one * 8.0, Core.lookCF(origin, dir), {
		color = BROWN,
		material = Enum.Material.Rock,
		transparency = 0,
		spin = Vector3.new(6, 9, 4),
	})

	-- Trailing dust flakes & tumbling rocks
	local att = Core.attach(boulder)
	local dustTrail = Core.emitter(att, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST_C),
		rate = 60,
		lifetime = NumberRange.new(0.4, 0.8),
		speed = NumberRange.new(3, 8),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(2.5, 5.0),
	})
	local rockTrail = Core.emitter(att, {
		texture = Core.PinnacleTextures.TumblingRock,
		color = ColorSequence.new(STONE),
		rate = 25,
		lifetime = NumberRange.new(0.3, 0.6),
		speed = NumberRange.new(5, 12),
		spread = Vector2.new(45, 45),
		rotSpeed = NumberRange.new(-500, 500),
		size = NumberSequence.new(0.8, 0.2),
	})

	Core.sound(origin, Core.Sounds.EarthImpact, 0.85, 1.0)

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local curPos = origin:Lerp(target, Core.smooth(k))
		boulder.Position = curPos
	end, function()
		dustTrail.Enabled = false
		rockTrail.Enabled = false
		boulder:Destroy()

		-- Impact: Seismic Crater with 3D Smash Mesh + Tumbling Shrapnel
		Core.impactExplosion(target, EARTH, 26, {
			duration = 2.5,
			rockCount = 32,
			shakeDur = 0.5,
			shakeIntens = 3.2,
		})
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = STONE,
			from = 3,
			to = 34,
			duration = 0.65,
			meshId = Core.Meshes.ShockwaveColossal,
		})
	end)
end

-- Move3: Accelerated Earth Punch (3D Bonk Impact + Seismic Shock Cone)
function Earth.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target or (r.Position + ctx.direction * 30)
	local dir = (target - r.Position).Unit

	-- Dash streak to target
	Core.afterimage(char, { color = STONE, life = 0.35 })
	Core.tempBeam(r.Position, target, 0.22, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = EARTH,
		width0 = 4,
		width1 = 1,
	})

	task.delay(0.18, function()
		-- 3D Sculpted Bonk Impact Mesh (`rbxassetid://4316118084`)
		local bonkPart, mesh = Core.meshPart(Core.Meshes.Bonk, Vector3.one * 9, Core.lookCF(target, dir), {
			color = STONE,
			material = Enum.Material.Rock,
			transparency = 0.1,
		})
		Core.runFor(0.35, function(_, t)
			bonkPart.Transparency = 0.1 + 0.9 * (t / 0.35)
		end, function()
			bonkPart:Destroy()
		end)

		-- Seismic Impact Explosion (Never cracks in mid-air!)
		Core.impactExplosion(target, EARTH, 22, {
			duration = 2.2,
			rockCount = 26,
			shakeDur = 0.38,
			shakeIntens = 2.5,
		})
	end)
end

-- Move4: The Master of Terra (Domain-Scale Terraform: 12 Colossal Spikes + Seismic Ring)
function Earth.Move4(ctx)
	local center = ctx.target or ctx.origin
	local R = 36
	local duration = 6.0

	-- Central Seismic Shockwave (`GravityShockwave` mesh)
	local gravPart, gMesh = Core.meshPart(Core.Meshes.GravityShockwave, Vector3.new(R * 2.0, 1.2, R * 2.0), Core.groundCF(center + Vector3.new(0, 0.2, 0)), {
		color = STONE,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(0, 5, 0),
	})

	-- 12 Colossal Spikes encircling the target (`rbxassetid://967645205`)
	local pts = Core.circle(center, R, 12, 0)
	local spikes = {}
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, center - pt) * CFrame.Angles(0, math.rad(180), math.rad(18))
		local spike, m = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(7, 42, 7), cf, {
			color = BROWN,
			material = Enum.Material.Rock,
			transparency = 0,
		})
		table.insert(spikes, spike)
	end

	-- Massive Crater & Tumbling Boulders (Verified ground check)
	Core.impactExplosion(center, EARTH, 36, {
		duration = 3.5,
		rockCount = 48,
		shakeDur = 0.8,
		shakeIntens = 4.0,
	})
	Core.sound(center, Core.Sounds.EarthImpact, 1.0, 0.8)

	Core.runFor(duration, function(_, t)
		if t >= duration - 1.2 then
			local k = (t - (duration - 1.2)) / 1.2
			gravPart.Transparency = 0.2 + 0.8 * k
			for _, s in ipairs(spikes) do
				s.Transparency = k
			end
		end
	end, function()
		gravPart:Destroy()
		Core.destroyAll(spikes)
	end)
end

return Earth
