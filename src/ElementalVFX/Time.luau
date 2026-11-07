--!strict
-- Time.luau — Top-Tier Time Element VFX (Secret Element)
-- 3D sculpted FancySphere Chronos Shield, celestial clock runes,
-- glass fracture time shatter, and chronological reverse physics.

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

-- M1: Chromatic Temporal Strike (Time ghost afterimage + ripple cut)
function Time.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.0
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-30, 30)))

	-- 1. Micro-Cleave Instant Slash
	Core.dismantleCleave(cleaveCF, TIME, 8)

	-- 2. Time-Ghost Afterimage of the striking hand
	Core.ghost(cleaveCF, Vector3.new(0.8, 0.8, 3.2), CYAN, 0.35)

	-- 3. Concentric Temporal Ripple Disc (VelocityPerpendicular)
	local anchor = Core.anchor(start)
	local att = Core.attach(anchor)
	local ripple = Core.emitter(att, {
		texture = Core.PinnacleTextures.CelestialRing,
		color = CHRONO,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.2, 0.35),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(2, 8),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		zOffset = 12,
	})
	ripple:Emit(1)

	Core.burst(start, 12, {
		texture = Core.PinnacleTextures.CelestialRing,
		color = CHRONO,
		speed = 14,
		life = 0.45,
		light = 1,
	})
	Core.cleanupLater({ anchor }, 0.5)
end

-- Move1: Got Throwed (Celestial Ring Freeze + Teleport + Heavy Cleave)
function Time.Move1(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local target = ctx.target
	if not r then return end

	-- 1. Celestial Temporal Ring locking the target
	local targetAnchor = Core.anchor(target + Vector3.new(0, 2, 0))
	local ring = Core.emitter(Core.attach(targetAnchor), {
		texture = Core.PinnacleTextures.CelestialRing,
		color = TIME,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.6, 0.8),
		size = NumberSequence.new(7),
		orientation = Enum.ParticleOrientation.FacingCamera,
		rotSpeed = NumberRange.new(45, 45),
		zOffset = 14,
	})
	ring:Emit(1)

	-- 2. Teleport Streak with Afterimages
	Core.afterimage(char, { color = CYAN, life = 0.4 })
	local teleportBeam = Core.tempBeam(r.Position, target - ctx.direction * 3, 0.25, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = TIME,
		width0 = 3,
		width1 = 0.5,
		light = 1,
	})

	task.delay(0.22, function()
		-- 3. Devastating Instant Cleave Strike at Target
		Core.dismantleCleave(Core.lookCF(target, ctx.direction), TIME, 12)
		Core.groundSlamCrater(target, TIME, 14, { duration = 1.8, rockCount = 18 })
		Core.cleanupLater({ targetAnchor }, 0.8)
	end)
end

-- Move2: Time Injection (Clock Ring Freeze + Inward Reverse Speedlines + Impact)
function Time.Move2(ctx)
	local target = ctx.target
	local origin = ctx.origin

	-- 1. 3D InwardShockwave Mesh (`rbxassetid://6220387416`) pulling spacetime inward
	local inwardPart, mesh = Core.meshPart(Core.Meshes.InwardShockwave, Vector3.one * 14, CFrame.new(target), {
		color = CYAN,
		material = Enum.Material.Neon,
		transparency = 0.25,
		spin = Vector3.new(0, -10, 0),
	})
	Core.runFor(0.5, function(_, t)
		local scale = 1.0 - (t / 0.5) * 0.8
		inwardPart.Size = Vector3.one * (14 * scale)
	end, function()
		inwardPart:Destroy()

		-- 2. Impact Shatter: Glass Fracture + 3D RoughShockwave Mesh
		local shockPart, sMesh = Core.meshPart(Core.Meshes.RoughShockwave, Vector3.new(16, 4, 16), Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = GOLD_TIME,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		Core.runFor(0.4, function(_, t)
			shockPart.Transparency = 0.1 + 0.9 * (t / 0.4)
		end, function()
			shockPart:Destroy()
		end)

		Core.burst(target, 25, {
			texture = Core.PinnacleTextures.GlassShatter,
			color = TIME,
			speed = 22,
			life = 0.6,
			light = 1,
		})
		Core.groundSlamCrater(target, TIME, 16, { duration = 2.0, rockCount = 20 })
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
	local shieldPart, sMesh = Core.meshPart(Core.Meshes.FancySphereLight, Vector3.one * 8.5, r.CFrame, {
		color = CYAN,
		material = Enum.Material.ForceField,
		transparency = 0.35,
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
		rate = 6,
		lifetime = NumberRange.new(0.5, 0.8),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(10),
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
		-- Flash and ripple upon block
		shieldPart.Color = Color3.fromRGB(255, 255, 255)
		shieldPart.Transparency = 0.1
		task.delay(0.1, function()
			if isAlive and shieldPart.Parent then
				shieldPart.Color = CYAN
				shieldPart.Transparency = 0.35
			end
		end)
		Core.shockwave(shieldPart.CFrame, {
			color = GOLD_TIME,
			from = 8,
			to = 16,
			duration = 0.3,
		})
	end

	function handle:End()
		if not isAlive then return end
		isAlive = false
		conn:Disconnect()
		Core.burst(shieldPart.Position, 25, {
			texture = Core.PinnacleTextures.GlassShatter,
			color = TIME,
			speed = 18,
			life = 0.45,
		})
		shieldModel:Destroy()
	end

	task.delay(duration, function()
		if isAlive then handle:End() end
	end)

	return handle
end

-- Move4: Virtual Kill / Temporal Rupture (Timeline Fracture + Supernova Release)
function Time.Move4(ctx)
	local target = ctx.target or ctx.origin

	-- 1. Glass Fracture Sound & Strobe at Target
	Core.burst(target, 40, {
		texture = Core.PinnacleTextures.GlassShatter,
		color = TIME,
		speed = 28,
		life = 0.7,
		light = 1,
	})

	-- 2. 3D RoughShockwave Electricity Mesh (`rbxassetid://903888897`)
	local roughPart, rMesh = Core.meshPart(Core.Meshes.RoughShockwave, Vector3.new(24, 6, 24), Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
		color = GOLD_TIME,
		material = Enum.Material.Neon,
		transparency = 0.1,
	})
	Core.runFor(0.5, function(_, t)
		roughPart.Transparency = 0.1 + 0.9 * (t / 0.5)
	end, function()
		roughPart:Destroy()
	end)

	-- 3. Supernova Timeline Realignment Release
	Core.supernovaSphere(target, TIME, 45, {
		duration = 1.4,
		coreColor = WHITE,
	})
	Core.groundSlamCrater(target, TIME, 22, { duration = 2.5, rockCount = 30 })
end

return Time
