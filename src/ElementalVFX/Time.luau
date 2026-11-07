--!strict
-- Time.luau — Top-Tier Time Element VFX (Secret Element)
-- 3D sculpted FancySphere Chronos Shield, celestial clock runes,
-- glass fracture time shatter, colossal 28-stud chrono slashes, and chronological reverse physics.

local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local DEEP_CHRONO = Color3.fromRGB(20, 50, 180)
local CYAN = Color3.fromRGB(0, 240, 255)
local GOLD_TIME = Color3.fromRGB(255, 215, 110)
local BRIGHT = Color3.fromRGB(225, 245, 255)
local WHITE = Color3.fromRGB(255, 255, 255)
local TIME = Core.seq({ WHITE, BRIGHT, CYAN, DEEP_CHRONO })
local CHRONO = Core.seq({ GOLD_TIME, CYAN, BRIGHT })

local Time = {}

-- M1: Colossal Chromatic Temporal Slash (28-stud time cut, sweeps 42 studs, NO air cracks)
function Time.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.0
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-25, 25)))

	-- Colossal 28-stud Chrono Slash sweeping forward 42 studs
	Core.colossalSlash(cleaveCF, 42, TIME, {
		width = 28,
		height = 4.2,
		duration = 0.4,
		meshColor = CYAN,
		soundId = Core.Sounds.LaserBeam,
	})

	-- Time-Ghost Afterimage of the striking hand
	Core.ghost(cleaveCF, Vector3.new(1.0, 1.0, 4.0), CYAN, 0.35)

	-- Concentric Temporal Ripple Disc (VelocityPerpendicular)
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local ripple = Core.emitter(att, {
		texture = Core.PinnacleTextures.CelestialRing,
		color = CHRONO,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(3, 10),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 12,
	})
	ripple:Emit(1)

	Core.burst(start, 14, {
		texture = Core.PinnacleTextures.PopStar,
		color = CHRONO,
		speed = 16,
		life = 0.45,
		light = 1,
	})
	Core.cleanupLater({ anchor }, 0.5)
end

-- Move1: Got Throwed (Celestial Ring Freeze + Teleport + Colossal Cleave)
function Time.Move1(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local target = ctx.target or (ctx.origin + ctx.direction * 35)
	if not r then return end

	-- 1. Celestial Temporal Ring locking the target
	local targetAnchor = Core.anchor(target + Vector3.new(0, 2, 0))
	local ring = Core.emitter(Core.attach(targetAnchor), {
		texture = Core.PinnacleTextures.CelestialRing,
		color = TIME,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.6, 0.8),
		size = NumberSequence.new(9),
		orientation = Enum.ParticleOrientation.FacingCamera,
		rotSpeed = NumberRange.new(45, 45),
		zOffset = 14,
	})
	ring:Emit(1)

	-- 2. Teleport Streak with Afterimages
	Core.afterimage(char, { color = CYAN, life = 0.4 })
	local teleportBeam = Core.tempBeam(r.Position, target - ctx.direction * 4, 0.25, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = TIME,
		width0 = 4,
		width1 = 0.8,
		light = 1,
	})

	task.delay(0.22, function()
		-- 3. Devastating 28-stud Cleave Strike at Target
		local cleaveCF = Core.lookCF(target, ctx.direction)
		Core.colossalSlash(cleaveCF, 35, TIME, {
			width = 28,
			height = 4.0,
			duration = 0.35,
			meshColor = GOLD_TIME,
		})
		Core.impactExplosion(target, TIME, 20, {
			duration = 1.8,
			rockCount = 20,
			shakeDur = 0.35,
			shakeIntens = 2.4,
		})
		Core.cleanupLater({ targetAnchor }, 0.8)
	end)
end

-- Move2: Time Injection (Clock Ring Freeze + Inward Reverse Speedlines + Impact)
function Time.Move2(ctx)
	local target = ctx.target or (ctx.origin + ctx.direction * 30)

	-- 1. 3D InwardShockwave Mesh (`rbxassetid://6220387416`) pulling spacetime inward
	local inwardPart, mesh = Core.meshPart(Core.Meshes.InwardShockwave, Vector3.one * 18, CFrame.new(target), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(0, -12, 0),
	})
	Core.runFor(0.5, function(_, t)
		local scale = 1.0 - (t / 0.5) * 0.85
		inwardPart.Size = Vector3.one * (18 * scale)
	end, function()
		inwardPart:Destroy()

		-- 2. Impact Shatter: Glass Fracture + 3D RoughShockwave Mesh
		local shockPart, sMesh = Core.meshPart(Core.Meshes.RoughShockwave, Vector3.new(22, 5, 22), Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = GOLD_TIME,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		Core.runFor(0.4, function(_, t)
			shockPart.Transparency = 0.1 + 0.9 * (t / 0.4)
		end, function()
			shockPart:Destroy()
		end)

		Core.burst(target, 35, {
			texture = Core.PinnacleTextures.GlassShatter,
			color = TIME,
			speed = 26,
			life = 0.65,
			light = 1,
		})
		Core.impactExplosion(target, TIME, 24, {
			duration = 2.0,
			rockCount = 24,
			shakeDur = 0.45,
			shakeIntens = 2.8,
		})
	end)
end

-- Move3: Untouchable / Chronos Shield (3D FancySphereLight Barrier + Handle)
function Time.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local duration = ctx.duration or 4
	if not r then return { Hit = function() end, End = function() end } end

	local shieldModel = Instance.new("Model")
	shieldModel.Name = "ChronosShieldVFX"
	shieldModel.Parent = Core.Folder

	-- 3D Sculpted FancySphereLight Barrier (`rbxassetid://5703288879`)
	local shieldPart, sMesh = Core.meshPart(Core.Meshes.FancySphereLight, Vector3.one * 10, r.CFrame, {
		color = CYAN,
		material = Enum.Material.ForceField,
		transparency = 0.3,
		parent = shieldModel,
	})

	-- Orbiting Celestial Clock Ring
	local ringAnchor = Core.anchor(r.Position)
	ringAnchor.Parent = shieldModel
	local att = Core.attach(ringAnchor)
	local clockRing = Core.emitter(att, {
		texture = Core.PinnacleTextures.CelestialRing,
		color = CHRONO,
		light = 1,
		rate = 8,
		lifetime = NumberRange.new(0.5, 0.8),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(12),
		rotSpeed = NumberRange.new(60, 60),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
	})

	local isAlive = true
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not isAlive or not r.Parent then
			conn:Disconnect()
			return
		end
		shieldPart.CFrame = r.CFrame
		ringAnchor.CFrame = r.CFrame * CFrame.new(0, -1, 0)
	end)

	local handle = {}

	function handle:Hit()
		if not isAlive then return end
		shieldPart.Color = Color3.fromRGB(255, 255, 255)
		shieldPart.Transparency = 0.1
		task.delay(0.1, function()
			if isAlive and shieldPart.Parent then
				shieldPart.Color = CYAN
				shieldPart.Transparency = 0.3
			end
		end)
		Core.shockwave(shieldPart.CFrame, {
			color = GOLD_TIME,
			from = 8,
			to = 20,
			duration = 0.3,
		})
	end

	function handle:End()
		if not isAlive then return end
		isAlive = false
		conn:Disconnect()
		Core.burst(shieldPart.Position, 30, {
			texture = Core.PinnacleTextures.GlassShatter,
			color = TIME,
			speed = 22,
			life = 0.5,
		})
		shieldModel:Destroy()
	end

	task.delay(duration, function()
		if isAlive then handle:End() end
	end)

	return handle
end

-- Move4: Virtual Kill / Temporal Rupture (Timeline Fracture + Colossal Supernova Release)
function Time.Move4(ctx)
	local target = ctx.target or ctx.origin

	-- 1. Glass Fracture Sound & Strobe at Target
	Core.burst(target, 50, {
		texture = Core.PinnacleTextures.GlassShatter,
		color = TIME,
		speed = 32,
		life = 0.75,
		light = 1,
	})

	-- 2. 3D RoughShockwave Electricity Mesh (`rbxassetid://903888897`)
	local roughPart, rMesh = Core.meshPart(Core.Meshes.RoughShockwave, Vector3.new(30, 7, 30), Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
		color = GOLD_TIME,
		material = Enum.Material.Neon,
		transparency = 0.1,
	})
	Core.runFor(0.5, function(_, t)
		roughPart.Transparency = 0.1 + 0.9 * (t / 0.5)
	end, function()
		roughPart:Destroy()
	end)

	-- 3. Supernova Timeline Realignment Release (55 studs)
	Core.supernovaSphere(target, TIME, 55, {
		duration = 1.6,
		coreColor = WHITE,
	})
	Core.impactExplosion(target, TIME, 30, {
		duration = 2.8,
		rockCount = 36,
		shakeDur = 0.75,
		shakeIntens = 4.0,
	})
	Core.sound(target, Core.Sounds.Explosion, 1.0, 0.85)
end

return Time
