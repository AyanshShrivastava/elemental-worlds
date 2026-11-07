--!strict
-- Fire.luau — Top-Tier Fire Element VFX
-- Multi-pass layering with Grid8x8 fluid flipbook flame, 3D sculpted meshes,
-- negative light depth craters, and anime cleave physics.

local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local CORE = Color3.fromRGB(255, 245, 190)
local GOLD = Color3.fromRGB(255, 195, 45)
local ORANGE = Color3.fromRGB(255, 105, 10)
local DEEP = Color3.fromRGB(215, 45, 10)
local FIRE = Core.seq({ CORE, GOLD, ORANGE, DEEP })
local GOLD_SEQ = Core.seq({ CORE, GOLD })
local EMBER_SEQ = Core.seq({ GOLD, ORANGE })

local Fire = {}

Fire.DOMAIN = { radius = 75, height = 45, duration = 10, fadeOut = 1.2 }

-- M1: Flaming Instant Anime Cleave & Ember Cut
function Fire.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-35, 35)))

	-- 1. Micro-Cleave Instant Slash (0.05s cut with squash + negative shadow)
	Core.dismantleCleave(cleaveCF, FIRE, 9)

	-- 2. Burst of anime fluid flame
	local anchor = Core.anchor(start)
	Core.pinnacleFlame(anchor, FIRE, 0.6)
	Core.burst(start, 14, {
		texture = Core.PinnacleTextures.Embers,
		color = EMBER_SEQ,
		speed = 18,
		life = 0.45,
		light = 1,
	})
	Core.cleanupLater({ anchor }, 0.8)
end

-- Move1: Scorching Fireball (3D Sculpted Fireball Mesh + Helical Beams + Seismic Crater Impact)
function Fire.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 65, 0.2)
	local dir = (target - origin).Unit

	-- 3D Sculpted FireBall Mesh (`rbxassetid://6553027596`)
	local corePart, coreMesh = Core.meshPart(Core.Meshes.FireBall, Vector3.one * 4.2, Core.lookCF(origin, dir), {
		color = GOLD,
		material = Enum.Material.Neon,
		transparency = 0.05,
		spin = Vector3.new(4, 8, 4),
	})

	-- Secondary Inner Core (`FancySphereLight`)
	local innerSphere, innerMesh = Core.meshPart(Core.Meshes.FancySphereLight, Vector3.one * 3.2, Core.lookCF(origin, dir), {
		color = CORE,
		material = Enum.Material.Neon,
		transparency = 0.1,
	})

	-- Grid8x8 Fluid Flame Body
	local flames = Core.pinnacleFlame(corePart, FIRE, 1.2, { rate = 55 })

	-- Helical Beams wrapping around the projectile
	local att0 = Core.attach(corePart, Vector3.new(-1.2, 0, 1.5))
	local att1 = Core.attach(corePart, Vector3.new(1.2, 0, -1.5))
	local beam = Core.beam(att0, att1, {
		texture = Core.PinnacleTextures.HelicalBeam,
		color = FIRE,
		width0 = 2.0,
		width1 = 2.0,
		curve0 = 3.5,
		curve1 = 3.5,
		textureSpeed = 5,
		light = 1,
	})

	Core.runFor(dur, function(_, t)
		local k = math.clamp(t / dur, 0, 1)
		local currentPos = origin:Lerp(target, k)
		corePart.CFrame = Core.lookCF(currentPos, dir)
		innerSphere.CFrame = CFrame.new(currentPos)
	end, function()
		flames.Fire.Enabled = false
		flames.Embers.Enabled = false
		flames.Smoke.Enabled = false
		beam:Destroy()
		corePart:Destroy()
		innerSphere:Destroy()

		-- Impact: Heavy Ground Slam Crater Engine + Tumbling Magma Shrapnel
		Core.groundSlamCrater(target, FIRE, 15, {
			duration = 2.5,
			rockCount = 26,
		})
		Core.supernovaSphere(target, FIRE, 25, { duration = 0.8 })
	end)
end

-- Move2: Infernal Beast (Summons a multi-pass fiery beast handle)
function Fire.Move2(ctx)
	local r = Core.root(ctx.character)
	local spawnPos = r and (r.Position + r.CFrame.RightVector * 5 + r.CFrame.LookVector * 2) or ctx.origin
	local duration = ctx.duration or 10

	local beastModel = Instance.new("Model")
	beastModel.Name = "InfernalBeast"
	beastModel.Parent = Core.Folder

	-- 3D Sculpted Core Body
	local corePart, mesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 3.2, CFrame.new(spawnPos), {
		color = GOLD,
		material = Enum.Material.Neon,
		transparency = 0.1,
		parent = beastModel,
	})

	-- Roaring Fluid Flame aura
	local flames = Core.pinnacleFlame(corePart, FIRE, 1.1, { rate = 40 })

	-- Fiery Eyes
	local eyeL = Core.part(Enum.PartType.Ball, Vector3.one * 0.45, CFrame.new(spawnPos), {
		color = CORE, material = Enum.Material.Neon, transparency = 0, parent = beastModel,
	})
	local eyeR = Core.part(Enum.PartType.Ball, Vector3.one * 0.45, CFrame.new(spawnPos), {
		color = CORE, material = Enum.Material.Neon, transparency = 0, parent = beastModel,
	})

	local isAlive = true
	local currentPos = spawnPos

	local function updatePose(pos, lookDir)
		currentPos = pos
		corePart.CFrame = Core.lookCF(pos, lookDir)
		eyeL.CFrame = corePart.CFrame * CFrame.new(-0.7, 0.6, -1.2)
		eyeR.CFrame = corePart.CFrame * CFrame.new(0.7, 0.6, -1.2)
	end

	-- Idle float animation
	local idleConn
	local startClock = os.clock()
	idleConn = RunService.Heartbeat:Connect(function()
		if not isAlive then
			idleConn:Disconnect()
			return
		end
		local hover = math.sin((os.clock() - startClock) * 4) * 0.4
		local rootPos = r and r.Position or spawnPos
		local targetHover = rootPos + Vector3.new(4, 2 + hover, 2)
		local lerped = currentPos:Lerp(targetHover, 0.1)
		updatePose(lerped, r and r.CFrame.LookVector or Vector3.new(0, 0, -1))
	end)

	local handle = {}

	function handle:Attack(pos: Vector3)
		if not isAlive then return end
		local lungeStart = currentPos
		local dur = 0.35
		local lungeDir = (pos - lungeStart).Unit
		Core.runFor(dur, function(_, t)
			local k = Core.smooth(t / dur)
			updatePose(lungeStart:Lerp(pos, k), lungeDir)
		end, function()
			Core.dismantleCleave(Core.lookCF(pos, lungeDir), FIRE, 10)
			Core.groundSlamCrater(pos, FIRE, 10, { duration = 1.5, rockCount = 14 })
		end)
	end

	function handle:Despawn()
		if not isAlive then return end
		isAlive = false
		flames.Fire.Enabled = false
		flames.Embers.Enabled = false
		flames.Smoke.Enabled = false
		Core.burst(currentPos, 20, { texture = Core.PinnacleTextures.Embers, color = FIRE, speed = 25, life = 0.5 })
		task.delay(0.5, function()
			beastModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isAlive then handle:Despawn() end
	end)

	return handle
end

-- Move3: Flames of Fury (Anime Instant Streak + 3D Slash Sweep + Shockwave Knockback)
function Fire.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target
	local origin = r.Position

	-- 1. Charging Ignition Aura
	Core.converge(origin, 6, 20, 0.3, GOLD)
	Core.burst(origin, 16, { texture = Core.PinnacleTextures.Embers, color = FIRE, speed = 20, life = 0.4 })

	task.delay(0.25, function()
		-- 2. Teleport Afterimage & Streak
		Core.afterimage(char, { color = GOLD, life = 0.4 })
		local dashBeam = Core.tempBeam(origin, target, 0.3, {
			texture = Core.PinnacleTextures.HelicalBeam,
			color = FIRE,
			width0 = 3.5,
			width1 = 1.0,
			light = 1,
		})

		-- 3. Curved 3D Slash Mesh Sweep (`rbxassetid://4572036304`)
		local slashCF = Core.lookCF(target, ctx.direction) * CFrame.Angles(0, math.rad(90), math.rad(25))
		local slashPart, mesh = Core.meshPart(Core.Meshes.SlashEffect, Vector3.new(22, 1, 8), slashCF, {
			color = GOLD,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		Core.runFor(0.35, function(_, t)
			local k = t / 0.35
			slashPart.Transparency = 0.1 + 0.9 * k
		end, function()
			slashPart:Destroy()
		end)

		-- 4. Cleave & Ground Slam Burst on Arrival
		Core.dismantleCleave(Core.lookCF(target, ctx.direction), FIRE, 12)
		Core.groundSlamCrater(target, FIRE, 16, { duration = 2.0, rockCount = 20 })
	end)
end

-- Move4: Infernal Judgement (Colossal 75-stud Supernova Arena Domain)
function Fire.Move4(ctx)
	local center = ctx.origin or (ctx.root and ctx.root.Position) or Vector3.zero
	local R = Fire.DOMAIN.radius
	local H = Fire.DOMAIN.height
	local duration = Fire.DOMAIN.duration
	local fadeOut = Fire.DOMAIN.fadeOut

	local isDomainActive = true
	local domainParts = {}

	-- Initial Supernova Starburst
	Core.supernovaSphere(center, FIRE, R * 0.9, { duration = 1.2 })

	-- Colossal Floor Disc (VelocityPerpendicular scorch)
	local discAnchor = Core.anchor(center + Vector3.new(0, 0.1, 0))
	local floorDisc = Core.emitter(Core.attach(discAnchor), {
		texture = Core.PinnacleTextures.ShockwaveDisc160,
		color = FIRE,
		light = 0.8,
		rate = 0,
		lifetime = NumberRange.new(duration, duration),
		size = NumberSequence.new(R * 2.2),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 1,
	})
	floorDisc:Emit(1)
	table.insert(domainParts, discAnchor)

	-- 16 Perimeter 3D Spikes forming the domain boundary (`rbxassetid://967645205`)
	local pts = Core.circle(center, R, 16, 0)
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, center - pt) * CFrame.Angles(0, math.rad(180), math.rad(15))
		local spike, m = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(4, 32, 4), cf, {
			color = ORANGE,
			material = Enum.Material.Neon,
			transparency = 0.2,
		})
		table.insert(domainParts, spike)
		Core.pinnacleFlame(spike, FIRE, 1.2, { rate = 25 })
	end

	-- Central Floating Sun (`FancySphere`)
	local sun, sunMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 10, CFrame.new(center + Vector3.new(0, H * 0.7, 0)), {
		color = CORE,
		material = Enum.Material.Neon,
		transparency = 0.1,
		spin = Vector3.new(1, 3, 1),
	})
	table.insert(domainParts, sun)

	local sunLight = Instance.new("PointLight")
	sunLight.Color = GOLD
	sunLight.Brightness = 8
	sunLight.Range = R * 1.5
	sunLight.Parent = sun
	table.insert(domainParts, sunLight)

	-- Periodic flame pillars bursting inside domain
	local pillarThread = task.spawn(function()
		while isDomainActive do
			task.wait(0.6)
			if not isDomainActive then break end
			local a = Random.new():NextNumber(0, math.pi * 2)
			local dist = Random.new():NextNumber(5, R * 0.75)
			local burstPos = center + Vector3.new(math.cos(a) * dist, 0, math.sin(a) * dist)
			Core.dismantleCleave(Core.groundCF(burstPos), FIRE, 10)
			Core.groundSlamCrater(burstPos, FIRE, 8, { duration = 1.0, rockCount = 8, useMesh = false })
		end
	end)

	local handle = {}

	function handle:End()
		if not isDomainActive then return end
		isDomainActive = false
		task.cancel(pillarThread)
		Core.supernovaSphere(center, FIRE, R * 1.1, { duration = 0.8 })
		task.delay(0.5, function()
			Core.destroyAll(domainParts)
		end)
	end

	task.delay(duration, function()
		if isDomainActive then handle:End() end
	end)

	return handle
end

return Fire
