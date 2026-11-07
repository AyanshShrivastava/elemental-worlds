--!strict
-- Light.luau — Top-Tier Light Element VFX
-- Ultimate helical beam laser cannon, 3D prism mirrors with Grid8x8 lightning ricochets,
-- instant blinding muzzle flashes, and supernova amplification domain.

local Core = require(script.Parent.Core)

local LAV = Color3.fromRGB(200, 162, 240)
local BRIGHT = Color3.fromRGB(240, 230, 255)
local VIOLET = Color3.fromRGB(145, 95, 225)
local GOLD_LIGHT = Color3.fromRGB(255, 235, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT = Core.seq({ WHITE, BRIGHT, LAV, VIOLET })
local SOLAR = Core.seq({ WHITE, GOLD_LIGHT, BRIGHT })

local Light = {}

-- M1: Instant Strobe Needle Ray + Muzzle Flash (100 Studs Range)
function Light.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local start = hand.Position
	local dir = ctx.direction
	local range = 100
	local target = ctx.target or (start + dir * range)

	-- Concentric Muzzle Flash (`rbxassetid://10382927269`)
	local muzzleAnchor = Core.anchor(start)
	local muzzleAtt = Core.attach(muzzleAnchor)
	local flash = Core.emitter(muzzleAtt, {
		texture = Core.PinnacleTextures.MuzzleFlash,
		color = LIGHT,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.12, 0.2),
		speed = NumberRange.new(0.5, 2),
		size = NumberSequence.new(6, 0),
		zOffset = 18,
	})
	local lines = Core.emitter(muzzleAtt, {
		texture = Core.PinnacleTextures.MuzzleLines,
		color = ColorSequence.new(WHITE),
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.1, 0.18),
		speed = NumberRange.new(8, 16),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(5, 0),
		zOffset = 19,
	})
	flash:Emit(3)
	lines:Emit(6)

	-- Instant Strobe Beam (100 studs)
	Core.tempBeam(start, target, 0.22, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = LIGHT,
		width0 = 2.4,
		width1 = 1.0,
		light = 1,
	})

	-- Target Impact Glint & Air Burst (Zero cracks in air)
	Core.airBurst(target, LIGHT, 6, { sparkCount = 14, shardCount = 8 })
	Core.sound(start, Core.Sounds.LaserBeam, 0.6, 1.25)
	Core.cameraShake(0.12, 1.3)

	Core.cleanupLater({ muzzleAnchor }, 0.5)
end

-- Move1: Solar Beam (Colossal Helical Laser Cannon Engine - 150 Studs Range)
function Light.Move1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" }) or Core.root(ctx.character)
	local start = hand and hand.Position or ctx.origin
	local dir = ctx.direction.Unit
	local range = 150
	local target = ctx.target or (start + dir * range)

	-- Colossal Piercing Energy Beam (150 studs)
	Core.colossalBeam(start, dir, range, SOLAR, {
		coreColor = WHITE,
		glowColor = GOLD_LIGHT,
		width = 7.5,
		duration = 1.2,
		numHelical = 12,
	})

	-- Terminal Impact & Shockwave (Checks ground beneath; never cracks in mid-air!)
	task.delay(0.1, function()
		Core.impactExplosion(target, SOLAR, 22, {
			duration = 2.0,
			rockCount = 20,
			shakeDur = 0.45,
			shakeIntens = 2.8,
			meshColor = GOLD_LIGHT,
		})
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = GOLD_LIGHT,
			from = 3,
			to = 32,
			duration = 0.6,
		})
	end)
end

-- Move2: Mirrors of Judgement (3D Prism Star Meshes + 8 Lightning Ricochets)
function Light.Move2(ctx)
	local target = ctx.target or (ctx.origin + ctx.direction * 35)
	local numMirrors = 8
	local R = 28
	local pts = Core.circle(target, R, numMirrors, 5)
	local mirrorParts = {}

	-- Spawn 8 Sculpted Star3D Prism Mirrors (`rbxassetid://4886514859`)
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, target - pt)
		local mirror, m = Core.meshPart(Core.Meshes.Star3D, Vector3.one * 5.5, cf, {
			color = BRIGHT,
			material = Enum.Material.Neon,
			transparency = 0.05,
			spin = Vector3.new(3, 8, 3),
		})
		table.insert(mirrorParts, mirror)
	end

	-- Ricochet Hand-Drawn Lightning Bolts between mirrors in a ring
	for i = 1, numMirrors do
		task.delay((i - 1) * 0.08, function()
			local p0 = pts[i]
			local p1 = pts[(i % numMirrors) + 1]
			Core.animatedLightning(p0, p1, SOLAR, { width = 3.5, boltCount = 3 })
			Core.airBurst(p0, SOLAR, 5, { sparkCount = 10, shardCount = 6 })
		end)
	end

	-- Luminous Slam Convergence at Target from all 8 mirrors
	task.delay(numMirrors * 0.08 + 0.12, function()
		for _, pt in ipairs(pts) do
			Core.animatedLightning(pt, target, SOLAR, { width = 4.5, boltCount = 2 })
		end
		Core.supernovaSphere(target, SOLAR, 35, { duration = 1.2 })
		Core.impactExplosion(target, SOLAR, 24, {
			duration = 2.2,
			rockCount = 24,
			shakeDur = 0.45,
			shakeIntens = 3.0,
		})
		task.delay(0.6, function()
			Core.destroyAll(mirrorParts)
		end)
	end)
end

-- Move3: Flash Step / Blinding Attack (3D Flash Mesh Snap + Reappearance Shockwave)
function Light.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local origin = r.Position
	local target = ctx.target or (origin + ctx.direction * 40)

	-- 1. Origin Blinding Flash Mesh (`rbxassetid://2620058357`)
	local flashPart, fMesh = Core.meshPart(Core.Meshes.Flash, Vector3.one * 10, CFrame.new(origin), {
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
	Core.afterimage(char, { color = WHITE, life = 0.4 })
	Core.tempBeam(origin, target, 0.22, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = LIGHT,
		width0 = 4.5,
		width1 = 0.8,
	})
	Core.cameraShake(0.18, 1.6)

	-- 2. Reappearance Shockwave Disc at Target
	task.delay(0.12, function()
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = WHITE,
			from = 3,
			to = 26,
			duration = 0.5,
			meshId = Core.Meshes.CircleShockwave,
		})
		Core.airBurst(target, SOLAR, 12, { sparkCount = 28, shardCount = 18 })
	end)
end

-- Move4: Divine Light Amplification (Colossal Supernova Starburst Domain)
function Light.Move4(ctx)
	local center = ctx.target or ctx.origin
	local char = ctx.character
	local r = Core.root(char)
	local chargePos = r and (r.Position + Vector3.new(0, 4, 0)) or ctx.origin

	-- 1.2s Charge Convergence with Floating 3D Star + Concentric Charge Rings
	local chargeStar, sMesh = Core.meshPart(Core.Meshes.Star3D, Vector3.one * 4, CFrame.new(chargePos), {
		color = WHITE,
		material = Enum.Material.Neon,
		transparency = 0.05,
		spin = Vector3.new(5, 12, 5),
	})
	Core.converge(chargePos, 18, 40, 1.1, WHITE)

	Core.runFor(1.2, function(_, t)
		local scale = 1.0 + (t / 1.2) * 3.0
		chargeStar.Size = Vector3.one * (4 * scale)
	end, function()
		chargeStar:Destroy()

		-- Colossal Supernova Sphere: 80-stud diameter starburst
		Core.supernovaSphere(center, SOLAR, 65, {
			duration = 2.0,
			coreColor = WHITE,
		})

		-- Multilateral laser sweeps across 8 perimeter points (60 studs range)
		local pts = Core.circle(center, 40, 8, 3)
		for _, pt in ipairs(pts) do
			Core.meshLaserCannon(center + Vector3.new(0, 18, 0), pt, SOLAR, { width = 3.5, duration = 0.6 })
		end

		-- Terminal Impact: Huge screen shake, sound, and floor crater (only if ground beneath!)
		Core.impactExplosion(center, SOLAR, 32, {
			duration = 3.5,
			rockCount = 38,
			shakeDur = 0.85,
			shakeIntens = 4.2,
		})
		Core.sound(center, Core.Sounds.Explosion, 1.0, 0.85)
	end)
end

return Light
