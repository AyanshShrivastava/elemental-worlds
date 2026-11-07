--!strict
-- Light.luau — Top-Tier Light Element VFX
-- Ultimate helical beam laser cannon, 3D prism mirrors with Grid8x8 lightning ricochets,
-- instant blinding muzzle flashes, and supernova amplification.

local Core = require(script.Parent.Core)

local LAV = Color3.fromRGB(200, 162, 240)
local BRIGHT = Color3.fromRGB(240, 230, 255)
local VIOLET = Color3.fromRGB(145, 95, 225)
local GOLD_LIGHT = Color3.fromRGB(255, 235, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT = Core.seq({ WHITE, BRIGHT, LAV, VIOLET })
local SOLAR = Core.seq({ WHITE, GOLD_LIGHT, BRIGHT })

local Light = {}

-- M1: Instant Strobe Needle Ray + Muzzle Flash
function Light.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local start = hand.Position
	local dir = ctx.direction
	local target = ctx.target or (start + dir * 35)

	-- Concentric Muzzle Flash (`rbxassetid://10382927269`)
	local muzzleAnchor = Core.anchor(start)
	local muzzleAtt = Core.attach(muzzleAnchor)
	local flash = Core.emitter(muzzleAtt, {
		texture = Core.PinnacleTextures.MuzzleFlash,
		color = LIGHT,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.1, 0.18),
		speed = NumberRange.new(0.5, 2),
		size = NumberSequence.new(5, 0),
		zOffset = 18,
	})
	local lines = Core.emitter(muzzleAtt, {
		texture = Core.PinnacleTextures.MuzzleLines,
		color = ColorSequence.new(WHITE),
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.1, 0.15),
		speed = NumberRange.new(5, 12),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(4, 0),
		zOffset = 19,
	})
	flash:Emit(2)
	lines:Emit(4)

	-- Instant Strobe Beam
	Core.tempBeam(start, target, 0.2, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = LIGHT,
		width0 = 1.8,
		width1 = 0.8,
		light = 1,
	})

	-- Target Impact Glint
	Core.burst(target, 12, {
		texture = Core.PinnacleTextures.PopStar,
		color = LIGHT,
		speed = 18,
		life = 0.3,
		light = 1,
	})

	Core.cleanupLater({ muzzleAnchor }, 0.4)
end

-- Move1: Solar Beam (Helical Multi-Beam Laser Cannon Engine)
function Light.Move1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" }) or Core.root(ctx.character)
	local start = hand and hand.Position or ctx.origin
	local target = ctx.target or (start + ctx.direction * 55)

	-- Execute the Pinnacle Laser Cannon Engine (Cylinder mesh + 14 wrapped helical beams)
	Core.meshLaserCannon(start, target, SOLAR, {
		coreColor = WHITE,
		width = 5.5,
		duration = 0.75,
		numHelical = 10,
	})

	-- Ground Scorch and Shockwave on Impact
	task.delay(0.1, function()
		Core.groundSlamCrater(target, SOLAR, 14, { duration = 1.8, rockCount = 14 })
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = GOLD_LIGHT,
			from = 2,
			to = 24,
			duration = 0.5,
		})
	end)
end

-- Move2: Mirrors of Judgement (3D Prism Star Meshes + Grid8x8 Lightning Ricochets)
function Light.Move2(ctx)
	local target = ctx.target or (ctx.origin + ctx.direction * 25)
	local numMirrors = 5
	local R = 18
	local pts = Core.circle(target, R, numMirrors, 4)
	local mirrorParts = {}

	-- Spawn 3D Sculpted Star3D Prism Mirrors (`rbxassetid://4886514859`)
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, target - pt)
		local mirror, m = Core.meshPart(Core.Meshes.Star3D, Vector3.one * 4.5, cf, {
			color = BRIGHT,
			material = Enum.Material.Neon,
			transparency = 0.1,
			spin = Vector3.new(3, 6, 3),
		})
		table.insert(mirrorParts, mirror)
	end

	-- Ricochet Grid8x8 Hand-Drawn Lightning Bolts between mirrors
	for i = 1, numMirrors do
		task.delay((i - 1) * 0.12, function()
			local p0 = pts[i]
			local p1 = pts[(i % numMirrors) + 1]
			Core.animatedLightning(p0, p1, SOLAR, { width = 3.0, boltCount = 3 })
			Core.burst(p0, 10, { texture = Core.PinnacleTextures.PopStar, color = SOLAR, speed = 15, life = 0.3 })
		end)
	end

	-- Luminous Slam Convergence at Target
	task.delay(numMirrors * 0.12 + 0.1, function()
		for _, pt in ipairs(pts) do
			Core.animatedLightning(pt, target, SOLAR, { width = 4.0, boltCount = 2 })
		end
		Core.supernovaSphere(target, SOLAR, 28, { duration = 1.0 })
		Core.groundSlamCrater(target, SOLAR, 16, { duration = 2.0, rockCount = 20 })
		task.delay(0.6, function()
			Core.destroyAll(mirrorParts)
		end)
	end)
end

-- Move3: Flash Step / Blinding Attack (3D Flash Mesh Snap + Speedline Implosion)
function Light.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local origin = r.Position
	local target = ctx.target

	-- 1. Origin Blinding Flash Mesh (`rbxassetid://2620058357`)
	local flashPart, fMesh = Core.meshPart(Core.Meshes.Flash, Vector3.one * 8, CFrame.new(origin), {
		color = WHITE,
		material = Enum.Material.Neon,
		transparency = 0.05,
	})
	Core.runFor(0.25, function(_, t)
		flashPart.Transparency = 0.05 + 0.95 * (t / 0.25)
	end, function()
		flashPart:Destroy()
	end)

	-- Afterimage & Strobe streak
	Core.afterimage(char, { color = WHITE, life = 0.35 })
	Core.tempBeam(origin, target, 0.2, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = LIGHT,
		width0 = 3.5,
		width1 = 0.5,
	})

	-- 2. Reappearance Shockwave Disc at Target (`CircleShockwave` mesh)
	task.delay(0.12, function()
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = WHITE,
			from = 2,
			to = 20,
			duration = 0.45,
			meshId = Core.Meshes.CircleShockwave,
		})
		Core.burst(target, 25, {
			texture = Core.PinnacleTextures.PopStar,
			color = SOLAR,
			speed = 25,
			life = 0.4,
			light = 1,
		})
	end)
end

-- Move4: Divine Light Amplification (Full Supernova Starburst Domain Wave)
function Light.Move4(ctx)
	local center = ctx.target or ctx.origin
	local char = ctx.character
	local r = Core.root(char)
	local chargePos = r and (r.Position + Vector3.new(0, 3, 0)) or ctx.origin

	-- 1.2s Charge Convergence with Floating 3D Star
	local chargeStar, sMesh = Core.meshPart(Core.Meshes.Star3D, Vector3.one * 3, CFrame.new(chargePos), {
		color = WHITE,
		material = Enum.Material.Neon,
		transparency = 0.1,
		spin = Vector3.new(4, 10, 4),
	})
	Core.converge(chargePos, 14, 30, 1.1, WHITE)

	Core.runFor(1.2, function(_, t)
		local scale = 1.0 + (t / 1.2) * 2.5
		chargeStar.Size = Vector3.one * (3 * scale)
	end, function()
		chargeStar:Destroy()

		-- Colossal Supernova Sphere: 254 radial beams + 358-stud flash + 160-stud shockwave disc
		Core.supernovaSphere(center, SOLAR, 55, {
			duration = 1.8,
			coreColor = WHITE,
		})

		-- Multilateral laser barrages across the perimeter
		local pts = Core.circle(center, 30, 8, 2)
		for _, pt in ipairs(pts) do
			Core.meshLaserCannon(center + Vector3.new(0, 15, 0), pt, SOLAR, { width = 2.5, duration = 0.5 })
		end

		Core.groundSlamCrater(center, SOLAR, 25, { duration = 3.0, rockCount = 35 })
	end)
end

return Light
