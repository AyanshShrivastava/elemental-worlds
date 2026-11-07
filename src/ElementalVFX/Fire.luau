--!strict
-- Fire.luau — Pinnacle Fire Element VFX Engine
-- Colossal anime slashes, 130-stud fireballs, multi-pass fluid flipbook flames,
-- zero mid-air cracks, and the grand Hellfire Domain Expansion (Infernal Judgement).

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Core = require(script.Parent.Core)

local CORE = Color3.fromRGB(255, 245, 190)
local GOLD = Color3.fromRGB(255, 195, 45)
local ORANGE = Color3.fromRGB(255, 105, 10)
local DEEP = Color3.fromRGB(215, 45, 10)
local FIRE = Core.seq({ CORE, GOLD, ORANGE, DEEP })
local GOLD_SEQ = Core.seq({ CORE, GOLD })
local EMBER_SEQ = Core.seq({ GOLD, ORANGE })

local Fire = {}

Fire.DOMAIN = { radius = 80, height = 55, duration = 12, fadeOut = 1.4 }

-- M1: Grand Flaming Anime Cleave (28-stud wide crescent traveling 45 studs!)
function Fire.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then return end
	local dir = ctx.direction
	local start = hand.Position + dir * 2.5
	local cleaveCF = Core.lookCF(start, dir) * CFrame.Angles(0, 0, math.rad(Random.new():NextNumber(-30, 30)))

	-- 1. Colossal Anime Slash Wave (travels 45 studs, sweeping forward)
	Core.colossalSlash(cleaveCF, 45, FIRE, {
		width = 28,
		height = 5,
		duration = 0.45,
		meshColor = GOLD,
		soundId = Core.Sounds.SwordSlash,
	})

	-- 2. Burst of anime fluid flame & ember trail at the sword hand
	local anchor = Core.anchor(start)
	Core.pinnacleFlame(anchor, FIRE, 0.8)
	Core.burst(start, 20, {
		texture = Core.PinnacleTextures.Embers,
		color = EMBER_SEQ,
		speed = 22,
		life = 0.45,
		light = 1,
	})
	Core.cleanupLater({ anchor }, 0.8)
end

-- Move1: Scorching Fireball (Colossal 8-stud comet traveling 130 studs + 26-stud detonation!)
function Fire.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local dir = ctx.direction

	-- Travel 130 studs forward with animated flame flipbook & rotating ember wake
	Core.colossalProjectile(origin, dir, 130, 95, FIRE, {
		size = 8.5,
		meshId = Core.Meshes.FireballMesh,
		flipbookTexture = Core.PinnacleTextures.FluidFire8x8,
		coreColor = CORE,
		detonationRadius = 26,
		launchSound = Core.Sounds.FireBurst,
		hitSound = Core.Sounds.Explosion,
		onHit = function(hitPos)
			-- Additional radial Supernova burst at detonation
			Core.supernovaSphere(hitPos, FIRE, 30, { duration = 0.8 })
		end,
	})
end

-- Move2: Infernal Beast (Summons a roaring flame beast that lunges 100 studs!)
function Fire.Move2(ctx)
	local r = Core.root(ctx.character)
	local spawnPos = r and (r.Position + r.CFrame.RightVector * 5 + r.CFrame.LookVector * 2) or ctx.origin
	local duration = ctx.duration or 10

	local beastModel = Instance.new("Model")
	beastModel.Name = "InfernalBeast"
	beastModel.Parent = Core.Folder

	-- 3D Sculpted Beast Core Body
	local corePart, mesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 5.0, CFrame.new(spawnPos), {
		color = GOLD,
		material = Enum.Material.Neon,
		transparency = 0.05,
		parent = beastModel,
	})

	-- Roaring Fluid Flame aura
	local flames = Core.pinnacleFlame(corePart, FIRE, 1.4, { rate = 55 })

	-- Fiery Glowing Horns / Eyes
	local eyeL = Core.part(Enum.PartType.Ball, Vector3.one * 0.7, CFrame.new(spawnPos), {
		color = CORE, material = Enum.Material.Neon, transparency = 0, parent = beastModel,
	})
	local eyeR = Core.part(Enum.PartType.Ball, Vector3.one * 0.7, CFrame.new(spawnPos), {
		color = CORE, material = Enum.Material.Neon, transparency = 0, parent = beastModel,
	})

	local isAlive = true
	local currentPos = spawnPos

	local function updatePose(pos, lookDir)
		currentPos = pos
		corePart.CFrame = Core.lookCF(pos, lookDir)
		eyeL.CFrame = corePart.CFrame * CFrame.new(-1.1, 0.9, -1.8)
		eyeR.CFrame = corePart.CFrame * CFrame.new(1.1, 0.9, -1.8)
	end

	-- Idle float animation
	local idleConn
	local startClock = os.clock()
	idleConn = RunService.Heartbeat:Connect(function()
		if not isAlive then
			idleConn:Disconnect()
			return
		end
		local hover = math.sin((os.clock() - startClock) * 4) * 0.5
		local rootPos = r and r.Position or spawnPos
		local targetHover = rootPos + Vector3.new(5, 3 + hover, 2)
		local lerped = currentPos:Lerp(targetHover, 0.12)
		updatePose(lerped, r and r.CFrame.LookVector or Vector3.new(0, 0, -1))
	end)

	local handle = {}

	function handle:Attack(pos: Vector3)
		if not isAlive then return end
		local lungeStart = currentPos
		local dur = 0.4
		local lungeDir = (pos - lungeStart).Unit

		Core.runFor(dur, function(_, t)
			local k = Core.smooth(t / dur)
			updatePose(lungeStart:Lerp(pos, k), lungeDir)
		end, function()
			-- Grand anime impact: 30-stud crescent slash + detonation + screen shake!
			Core.colossalSlash(Core.lookCF(pos, lungeDir), 30, FIRE, { width = 26, duration = 0.4 })
			Core.impactExplosion(pos, FIRE, 18, {
				soundId = Core.Sounds.Explosion,
				shakeDur = 0.3,
				shakeIntens = 2.2,
			})
		end)
	end

	function handle:Despawn()
		if not isAlive then return end
		isAlive = false
		flames.Fire.Enabled = false
		flames.Embers.Enabled = false
		flames.Smoke.Enabled = false
		Core.burst(currentPos, 26, { texture = Core.PinnacleTextures.Embers, color = FIRE, speed = 28, life = 0.55 })
		task.delay(0.5, function()
			beastModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isAlive then handle:Despawn() end
	end)

	return handle
end

-- Move3: Flames of Fury (Anime Triple Crescent Cleave Barrage + Dash Shockwave)
function Fire.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local target = ctx.target
	local origin = r.Position

	-- 1. Charging Ignition Aura
	Core.converge(origin, 8, 26, 0.25, GOLD)
	Core.burst(origin, 22, { texture = Core.PinnacleTextures.Embers, color = FIRE, speed = 25, life = 0.4 })
	Core.cameraShake(0.15, 1.2)

	task.delay(0.2, function()
		-- 2. Teleport Afterimage & High-Speed Streak
		Core.afterimage(char, { color = GOLD, life = 0.45 })
		local dashBeam = Core.tempBeam(origin, target, 0.35, {
			texture = Core.PinnacleTextures.HelicalBeam,
			color = FIRE,
			width0 = 4.5,
			width1 = 1.5,
			light = 1,
		})

		-- 3. Triple Colossal Flame Slash Barrage (3 sweeping crescent waves at angles)
		local dir = ctx.direction
		local angles = { -35, 0, 35 }
		for i, ang in ipairs(angles) do
			task.delay((i - 1) * 0.08, function()
				local slashCF = Core.lookCF(target, dir) * CFrame.Angles(0, 0, math.rad(ang))
				Core.colossalSlash(slashCF, 35, FIRE, {
					width = 30,
					height = 5.5,
					duration = 0.4,
					meshColor = GOLD,
					soundId = Core.Sounds.SwordSlash,
				})
			end)
		end

		-- 4. Final Detonation on Arrival (ZERO floating air cracks!)
		task.delay(0.25, function()
			Core.impactExplosion(target, FIRE, 22, {
				soundId = Core.Sounds.Explosion,
				shakeDur = 0.35,
				shakeIntens = 2.8,
			})
		end)
	end)
end

-- Move4: Infernal Judgement (Colossal Anime Purgatory Domain Expansion!)
function Fire.Move4(ctx)
	local center = ctx.origin or (ctx.root and ctx.root.Position) or Vector3.zero
	local R = Fire.DOMAIN.radius
	local H = Fire.DOMAIN.height
	local duration = Fire.DOMAIN.duration
	local fadeOut = Fire.DOMAIN.fadeOut

	local isDomainActive = true
	local domainParts = {}

	-- 1. Initial Domain Activation: Blinding Supernova & Heavy Screen Shake!
	Core.cameraShake(0.65, 4.5)
	Core.supernovaSphere(center, FIRE, R * 0.95, { duration = 1.4 })
	Core.sound(center, Core.Sounds.Explosion, 1.2, 0.8)

	-- 2. Glowing Magma Floor Arena Disc
	local floorDisc = Core.part(Enum.PartType.Cylinder, Vector3.new(0.3, R * 2, R * 2), Core.groundCF(center + Vector3.new(0, 0.05, 0)), {
		color = DEEP,
		material = Enum.Material.Neon,
		transparency = 0.35,
	})
	table.insert(domainParts, floorDisc)

	-- Pulsing Magma Heat Texture on Floor
	local discAnchor = Core.anchor(center + Vector3.new(0, 0.1, 0))
	local floorDiscEmitter = Core.emitter(Core.attach(discAnchor), {
		texture = Core.PinnacleTextures.ShockwaveDisc160,
		color = FIRE,
		light = 0.9,
		rate = 0,
		lifetime = NumberRange.new(duration, duration),
		size = NumberSequence.new(R * 2.1),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 2,
	})
	floorDiscEmitter:Emit(1)
	table.insert(domainParts, discAnchor)

	-- 3. Perimeter Hellfire Barrier: 20 Towering Flame Pillars shooting 45 studs high!
	local N = 20
	local pts = Core.circle(center, R, N, 0)
	for i, pt in ipairs(pts) do
		local cf = Core.lookCF(pt, center - pt) * CFrame.Angles(0, math.rad(180), 0)

		-- Sculpted Flame Pillar Mesh (`rbxassetid://4901269283`)
		local pillar, m = Core.meshPart(Core.Meshes.FlamePillarCore, Vector3.new(7, 45, 7), cf * CFrame.new(0, 22.5, 0), {
			color = ORANGE,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		table.insert(domainParts, pillar)

		-- Swirling flame flipbooks on each pillar
		Core.pinnacleFlame(pillar, FIRE, 1.5, { rate = 35 })

		-- Rotating flame discs at the base of each pillar (`rbxassetid://2836527412`)
		local disc, discM = Core.meshPart(Core.Meshes.FlameDisc, Vector3.new(12, 1.5, 12), CFrame.new(pt + Vector3.new(0, 1, 0)), {
			color = GOLD,
			material = Enum.Material.Neon,
			transparency = 0.25,
			spin = Vector3.new(0, 6, 0),
		})
		table.insert(domainParts, disc)
	end

	-- 4. Central Floating Mini-Sun of Purgatory (Entei - 24-stud Flame Emperor Core!)
	local sunPos = center + Vector3.new(0, 28, 0)
	local sunCore, sunCoreMesh = Core.meshPart(Core.Meshes.FlameEmperor, Vector3.one * 24, CFrame.new(sunPos), {
		color = CORE,
		material = Enum.Material.Neon,
		transparency = 0.05,
		spin = Vector3.new(1, 2, 1),
	})
	table.insert(domainParts, sunCore)

	-- Counter-rotating orbital flame rings around the sun core (`rbxassetid://2836527412`)
	local ring1, ringMesh1 = Core.meshPart(Core.Meshes.FlameDisc, Vector3.new(34, 2, 34), CFrame.new(sunPos), {
		color = GOLD,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(0, 4, 2),
	})
	local ring2, ringMesh2 = Core.meshPart(Core.Meshes.FlameDisc, Vector3.new(42, 2, 42), CFrame.new(sunPos), {
		color = ORANGE,
		material = Enum.Material.Neon,
		transparency = 0.25,
		spin = Vector3.new(2, -5, 0),
	})
	table.insert(domainParts, ring1)
	table.insert(domainParts, ring2)

	-- Supernova Blazing Corona Flare
	local sunAtt = Core.attach(sunCore)
	local sunCorona = Core.emitter(sunAtt, {
		texture = Core.PinnacleTextures.SupernovaFlash,
		color = FIRE,
		light = 1,
		rate = 15,
		lifetime = NumberRange.new(0.6, 1.0),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(38, 48),
		zOffset = 20,
	})
	table.insert(domainParts, sunCorona)

	-- Massive Radiant Sunlight illuminating the entire arena
	local sunLight = Instance.new("PointLight")
	sunLight.Color = GOLD
	sunLight.Brightness = 12
	sunLight.Range = R * 1.8
	sunLight.Parent = sunCore
	table.insert(domainParts, sunLight)

	-- 5. Dynamic Eruptions inside the Domain (Volcanic Geysers & Anime Cleaves)
	local eruptionThread = task.spawn(function()
		local rng = Random.new()
		while isDomainActive do
			task.wait(0.55)
			if not isDomainActive then break end
			local a = rng:NextNumber(0, math.pi * 2)
			local dist = rng:NextNumber(8, R * 0.72)
			local burstPos = center + Vector3.new(math.cos(a) * dist, 0, math.sin(a) * dist)

			-- Spurt of erupting volcanic flame pillar
			local eruptionCF = Core.groundCF(burstPos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			Core.colossalSlash(eruptionCF, 20, FIRE, { width = 20, duration = 0.35, soundId = Core.Sounds.FireBurst })
			Core.airBurst(burstPos + Vector3.new(0, 4, 0), FIRE, 14, { sparkCount = 20, shardCount = 12 })
			Core.cameraShake(0.15, 1.2)
		end
	end)

	local handle = {}

	function handle:End()
		if not isDomainActive then return end
		isDomainActive = false
		task.cancel(eruptionThread)

		-- 6. Domain Collapse: Central Sun collapses inward, then detonates in a 100-stud Supernova!
		sunCorona.Enabled = false
		TweenService:Create(sunCore, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = Vector3.one * 0.1,
		}):Play()
		TweenService:Create(ring1, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = Vector3.zero,
		}):Play()
		TweenService:Create(ring2, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = Vector3.zero,
		}):Play()

		task.delay(0.5, function()
			Core.cameraShake(0.8, 5.0)
			Core.supernovaSphere(center, FIRE, R * 1.3, { duration = 1.2 })
			Core.sound(center, Core.Sounds.Explosion, 1.3, 0.7)

			-- Colossal 35-stud expanding shockwave mesh
			local colShock, sm = Core.meshPart(Core.Meshes.ShockwaveColossal, Vector3.new(R * 0.5, 8, R * 0.5), CFrame.new(center + Vector3.new(0, 2, 0)), {
				color = GOLD,
				material = Enum.Material.Neon,
				transparency = 0.05,
			})
			Core.runFor(0.8, function(_, t)
				local k = t / 0.8
				local sz = (R * 0.5) + (R * 2.2) * Core.smooth(k)
				colShock.Size = Vector3.new(sz, 8 * (1 - k * 0.5), sz)
				colShock.Transparency = 0.05 + 0.95 * k
			end, function()
				colShock:Destroy()
			end)

			task.delay(0.6, function()
				Core.destroyAll(domainParts)
			end)
		end)
	end

	task.delay(duration, function()
		if isDomainActive then handle:End() end
	end)

	return handle
end

return Fire
