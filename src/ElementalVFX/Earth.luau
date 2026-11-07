--!strict
-- Earth.luau — Top-Tier Earth Element VFX
-- Multi-pass layering with custom 3D sculpted GroundSpikes,
-- realistic 700 deg/s tumbling shrapnel physics, and negative depth craters.

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
	cols = 4,
	rows = 3,
	blockW = 3,
	blockH = 3,
	blockD = 1.5,
}

-- M1: Seismic Stone Cleave (Sculpted Ground Spike cut + tumbling shrapnel)
function Earth.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-30, 30)))

	-- 1. Micro-Cleave Instant Slash
	Core.dismantleCleave(cleaveCF, EARTH, 9)

	-- 2. Tumbling Physics Rocks
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local rocks = Core.emitter(att, {
		texture = Core.PinnacleTextures.TumblingRock,
		color = ColorSequence.new(STONE),
		light = 0,
		rate = 0,
		lifetime = NumberRange.new(0.4, 0.7),
		speed = NumberRange.new(12, 24),
		spread = Vector2.new(45, 45),
		direction = Enum.NormalId.Front,
		acceleration = Vector3.new(0, -171.5, 0),
		drag = 2.5,
		rotSpeed = NumberRange.new(-700, 700),
		size = NumberSequence.new(0.9, 0.2),
	})
	rocks:Emit(8)

	-- Dust puff
	Core.burst(start, 10, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST_C),
		speed = 10,
		life = 0.5,
	})
	Core.cleanupLater({ anchor }, 0.8)
end

-- Move1: Earthy Wall (Sculpted 3D GroundSpikes Eruption + Handle)
function Earth.Move1(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local center = r and (r.Position + r.CFrame.LookVector * 7) or (ctx.origin + ctx.direction * 7)
	local wallDir = r and r.CFrame.RightVector or Vector3.new(1, 0, 0)
	local duration = Earth.WALL.duration

	local wallModel = Instance.new("Model")
	wallModel.Name = "EarthWallVFX"
	wallModel.Parent = Core.Folder

	local spikes = {}
	local numPillars = 5
	local pillarWidth = 3.6
	local pillarHeight = 11

	-- Ground Flash and Dust Column along the wall line
	Core.groundSlamCrater(center, EARTH, 12, { duration = 1.5, rockCount = 14, useMesh = false })

	-- Erupt sculpted 3D GroundSpikes (`rbxassetid://967645205`)
	for i = 1, numPillars do
		local offset = wallDir * ((i - (numPillars + 1) * 0.5) * pillarWidth)
		local p = center + offset
		local cf = Core.lookCF(p, r and r.CFrame.LookVector or ctx.direction) * CFrame.Angles(math.rad(Random.new():NextNumber(-6, 6)), 0, 0)

		local spike, mesh = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(pillarWidth, pillarHeight, 3.2), cf, {
			color = STONE,
			material = Enum.Material.Rock,
			transparency = 0,
			parent = wallModel,
		})
		table.insert(spikes, spike)
	end

	-- Rise smoothly from ground
	local targetCenter = center
	local undergroundCenter = center - Vector3.new(0, pillarHeight, 0)
	Core.runFor(0.25, function(_, t)
		local k = Core.smooth(t / 0.25)
		for i, spike in ipairs(spikes) do
			local offset = wallDir * ((i - (numPillars + 1) * 0.5) * pillarWidth)
			local curP = undergroundCenter:Lerp(targetCenter, k) + offset
			spike.CFrame = CFrame.new(curP) * spike.CFrame.Rotation
		end
	end)

	local isAlive = true
	local handle = {}

	function handle:SetHealth(pct: number)
		if not isAlive then return end
		if pct <= 0 then
			handle:Shatter()
		else
			-- Shudder and spawn fracture chips
			for _, spike in ipairs(spikes) do
				local shake = Vector3.new(Random.new():NextNumber(-0.3, 0.3), 0, Random.new():NextNumber(-0.3, 0.3))
				spike.Position = spike.Position + shake
			end
			Core.burst(center, 12, {
				texture = Core.PinnacleTextures.TumblingRock,
				color = ColorSequence.new(STONE),
				speed = 15,
				life = 0.5,
			})
		end
	end

	function handle:Shatter()
		if not isAlive then return end
		isAlive = false
		Core.groundSlamCrater(center, EARTH, 16, { duration = 2.0, rockCount = 28 })
		Core.burst(center, 30, {
			texture = Core.Textures.AnimeSmoke,
			color = ColorSequence.new(DUST_C),
			speed = 25,
			life = 0.8,
		})
		wallModel:Destroy()
	end

	function handle:End()
		if not isAlive then return end
		isAlive = false
		-- Sink smoothly into ground
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

-- Move2: Boulder of Destruction (3D Sculpted Crystalline Boulder + Impact Shatter)
function Earth.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dir = (target - origin).Unit
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 50, 0.3)

	-- 3D Sculpted Boulder Mesh (`rbxassetid://4933939180`)
	local boulder, bMesh = Core.meshPart(Core.Meshes.ExplosionCube, Vector3.one * 5.5, Core.lookCF(origin, dir), {
		color = BROWN,
		material = Enum.Material.Rock,
		transparency = 0,
		spin = Vector3.new(5, 7, 3),
	})

	-- Trailing dust flakes
	local att = Core.attach(boulder)
	local dustTrail = Core.emitter(att, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(DUST_C),
		rate = 45,
		lifetime = NumberRange.new(0.4, 0.8),
		speed = NumberRange.new(2, 6),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(1.8, 3.5),
	})

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local curPos = origin:Lerp(target, k)
		boulder.Position = curPos
	end, function()
		dustTrail.Enabled = false
		boulder:Destroy()

		-- Impact: Seismic Crater with 3D Smash Mesh + Tumbling Shrapnel
		Core.groundSlamCrater(target, EARTH, 16, { duration = 2.5, rockCount = 26 })
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = STONE,
			from = 2,
			to = 28,
			duration = 0.6,
		})
	end)
end

-- Move3: Accelerated Earth Punch (3D Bonk Mesh Impact + Seismic Ground Slam)
function Earth.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target
	local dir = (target - r.Position).Unit

	-- Dash streak to target
	Core.afterimage(char, { color = STONE, life = 0.35 })
	Core.tempBeam(r.Position, target, 0.25, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = EARTH,
		width0 = 3,
		width1 = 1,
	})

	task.delay(0.18, function()
		-- 3D Sculpted Bonk Impact Mesh (`rbxassetid://4316118084`)
		local bonkPart, mesh = Core.meshPart(Core.Meshes.Bonk, Vector3.one * 7, Core.lookCF(target, dir), {
			color = STONE,
			material = Enum.Material.Rock,
			transparency = 0.1,
		})
		Core.runFor(0.35, function(_, t)
			bonkPart.Transparency = 0.1 + 0.9 * (t / 0.35)
		end, function()
			bonkPart:Destroy()
		end)

		-- Complete Ground Slam Crater
		Core.groundSlamCrater(target, EARTH, 18, {
			duration = 2.5,
			rockCount = 28,
		})
	end)
end

-- Move4: The Master of Terra (Domain-Scale Terraform: 8 Colossal Spikes + Seismic Shockwave)
function Earth.Move4(ctx)
	local center = ctx.target or ctx.origin
	local R = 32
	local duration = 6.0

	-- Central Seismic Shockwave (`GravityShockwave` mesh)
	local gravPart, gMesh = Core.meshPart(Core.Meshes.GravityShockwave, Vector3.new(R * 1.8, 1, R * 1.8), Core.groundCF(center + Vector3.new(0, 0.2, 0)), {
		color = STONE,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(0, 4, 0),
	})

	-- 8 Colossal Spikes encircling the target (`rbxassetid://967645205`)
	local pts = Core.circle(center, R, 8, 0)
	local spikes = {}
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, center - pt) * CFrame.Angles(0, math.rad(180), math.rad(18))
		local spike, m = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(6, 36, 6), cf, {
			color = BROWN,
			material = Enum.Material.Rock,
			transparency = 0,
		})
		table.insert(spikes, spike)
	end

	-- Massive Crater & Tumbling Boulders
	Core.groundSlamCrater(center, EARTH, 28, { duration = 3.5, rockCount = 45 })

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
