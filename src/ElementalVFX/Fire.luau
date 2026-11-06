-- Fire.lua — Fire element
--   M1    Flame Dagger: fast strike with an orange-gold fire trail
--   Move1 Scorching Fireball: rotating flame shells and an ember trail, bursts on arrival
--   Move2 Infernal Beast: summons a small fire creature. Returns a handle:
--           handle:Attack(pos) lunges at a position, handle:Despawn() removes it.
--           It also despawns by itself after ctx.duration (default 10).
--   Move3 Flames of Fury: fire builds, teleport streak behind target, beam and knockback burst
--   Move4 Infernal Judgement: fire domain. Visual boundary at Fire.DOMAIN.radius, lasts
--         Fire.DOMAIN.duration seconds, fades over the last Fire.DOMAIN.fadeOut seconds.
--         The server does the damage and blocks entry/exit; this only draws it.

local Core = require(script.Parent.Core)

local CORE = Color3.fromRGB(255, 243, 176)
local GOLD = Color3.fromRGB(255, 201, 60)
local ORANGE = Color3.fromRGB(255, 122, 0)
local DEEP = Color3.fromRGB(217, 72, 15)
local FIRE = Core.seq({ CORE, GOLD, ORANGE, DEEP })
local GOLD_SEQ = Core.seq({ CORE, GOLD })
local EMBER = Core.seq({ GOLD, ORANGE })
local FIRE_TEX = Core.Textures.Fire
local SPARK = Core.Textures.Sparkle

local Fire = {}

-- Domain settings for Move4: Colossal 75-stud anime domain arena
Fire.DOMAIN = { radius = 75, height = 45, duration = 10, fadeOut = 1.2 }

-- M1: flaming dagger with a fast orange-gold strike & anime slash burst
function Fire.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then
		return
	end
	local dir = ctx.direction
	local start = hand.Position
	local blade = Core.part(Enum.PartType.Block, Vector3.new(0.25, 0.25, 2.6), Core.lookCF(start, dir), {
		color = GOLD, material = Enum.Material.Neon, transparency = 0.15,
	})
	Core.trail(blade, Core.attach(blade, Vector3.new(0, 0.2, 0)), Core.attach(blade, Vector3.new(0, -0.2, 0)), {
		color = FIRE, lifetime = 0.25,
	})
	local flame = Core.emitter(Core.attach(blade), {
		texture = FIRE_TEX, color = FIRE, rate = 60, light = 0.8,
		lifetime = NumberRange.new(0.2, 0.35), speed = NumberRange.new(1, 3), size = NumberSequence.new(0.6, 0.1),
	})
	Core.runFor(0.3, function(_, t)
		local k = Core.smooth(t / 0.3)
		local pos = start + dir * (k * 5)
		blade.CFrame = Core.lookCF(pos, dir) * CFrame.Angles(0, 0, math.rad(60) * (1 - k))
	end, function()
		flame.Enabled = false
		blade.Transparency = 1
		Core.animeSpikeBurst(start + dir * 5, {
			color = ORANGE, coreColor = CORE, count = 5, radius = 4,
			minHeight = 4, maxHeight = 8, duration = 0.35, aimDir = dir,
		})
		Core.burst(start + dir * 5, 12, { color = GOLD_SEQ, texture = SPARK, speed = 12, light = 0.9 })
		Core.cleanupLater({ blade }, 0.6)
	end)
end

-- Move1: fireball with two rotating flame shells and an ember trail
function Fire.Move1(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dur = math.max((target - origin).Magnitude / 60, 0.2)

	local core = Core.part(Enum.PartType.Ball, Vector3.one * 2.4, CFrame.new(origin), {
		color = GOLD, material = Enum.Material.Neon, transparency = 0,
	})
	local shellA = Core.part(Enum.PartType.Ball, Vector3.one * 3.2, CFrame.new(origin), {
		color = ORANGE, material = Enum.Material.Neon, transparency = 0.6,
	})
	local shellB = Core.part(Enum.PartType.Ball, Vector3.one * 3.8, CFrame.new(origin), {
		color = ORANGE, material = Enum.Material.Neon, transparency = 0.7,
	})
	local embers = Core.emitter(Core.attach(core), {
		texture = FIRE_TEX, color = FIRE, rate = 90, light = 0.9,
		lifetime = NumberRange.new(0.4, 0.8), speed = NumberRange.new(0.5, 2), size = NumberSequence.new(0.7, 0.1),
	})
	local sparks = Core.emitter(Core.attach(core), {
		texture = SPARK, color = GOLD_SEQ, rate = 40, light = 1,
		lifetime = NumberRange.new(0.3, 0.6), speed = NumberRange.new(4, 8), size = NumberSequence.new(0.25, 0),
	})

	local spin = 0
	Core.runFor(dur, function(dt, t)
		spin += dt
		local pos = origin:Lerp(target, math.min(t / dur, 1))
		core.CFrame = CFrame.new(pos)
		shellA.CFrame = CFrame.new(pos) * CFrame.Angles(spin * 6, spin * 4, 0)
		shellB.CFrame = CFrame.new(pos) * CFrame.Angles(0, spin * -5, spin * 7)
		embers.Enabled = false
		sparks.Enabled = false
		core.Transparency = 1
		shellA.Transparency = 1
		shellB.Transparency = 1
		Core.animeSpikeBurst(target, {
			color = ORANGE,
			coreColor = CORE,
			outlineColor = Color3.fromRGB(18, 16, 22),
			count = 10,
			radius = 9,
			minHeight = 8,
			maxHeight = 17,
			duration = 0.65,
		})
		Core.shockwave(Core.groundCF(target + Vector3.new(0, 0.2, 0)), {
			color = GOLD, from = 2, to = 24, duration = 0.5,
		})
		Core.burst(target, 40, { texture = FIRE_TEX, color = FIRE, speed = 22, light = 0.9 })
		Core.cleanupLater({ core, shellA, shellB }, 1)
	end)
end

-- Builds the small fire creature (visual only). Parts are placed relative to the body.
local function buildBeast()
	local model = Instance.new("Model")
	model.Name = "InfernalBeast"

	local function bp(shape, size, cf, color, transparency)
		return Core.part(shape, size, cf, {
			color = color, material = Enum.Material.Neon, transparency = transparency or 0.05, parent = model,
		})
	end

	local body = bp(Enum.PartType.Ball, Vector3.one * 2.4, CFrame.new(0, 2.4, 0), ORANGE)
	model.PrimaryPart = body
	bp(Enum.PartType.Ball, Vector3.one * 1.5, CFrame.new(0, 3.6, -1.2), GOLD)
	bp(Enum.PartType.Block, Vector3.new(0.3, 1, 0.3), CFrame.new(-0.5, 4.7, -1.2) * CFrame.Angles(0, 0, math.rad(20)), GOLD)
	bp(Enum.PartType.Block, Vector3.new(0.3, 1, 0.3), CFrame.new(0.5, 4.7, -1.2) * CFrame.Angles(0, 0, math.rad(-20)), GOLD)
	bp(Enum.PartType.Ball, Vector3.one * 0.35, CFrame.new(-0.4, 3.8, -2.0), CORE)
	bp(Enum.PartType.Ball, Vector3.one * 0.35, CFrame.new(0.4, 3.8, -2.0), CORE)

	for i = 1, 3 do
		local seg = bp(Enum.PartType.Ball, Vector3.one * (1.2 - i * 0.25), CFrame.new(0, 2.2 + i * 0.3, 1.8 + i * 1.1), ORANGE)
		Core.emitter(Core.attach(seg), {
			texture = FIRE_TEX, color = FIRE, rate = 30, light = 0.9,
			lifetime = NumberRange.new(0.3, 0.5), speed = NumberRange.new(0.5, 1.5), size = NumberSequence.new(0.6, 0.1),
		})
	end
	Core.emitter(Core.attach(body), {
		texture = FIRE_TEX, color = FIRE, rate = 50, light = 0.9,
		lifetime = NumberRange.new(0.4, 0.7), speed = NumberRange.new(1, 3), size = NumberSequence.new(1, 0.2),
	})

	model.Parent = Core.Folder
	return model, body
end

-- Move2: summon the fire creature. Returns a handle (see header).
function Fire.Move2(ctx)
	local life = ctx.duration or 10
	local ground = Vector3.new(
		(ctx.origin + ctx.direction * 4).X,
		ctx.origin.Y - 3,
		(ctx.origin + ctx.direction * 4).Z
	)
	local base = ground + Vector3.new(0, 2.4, 0)

	-- summon circle and embers gathering into the creature
	Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.1, 0)), { color = ORANGE, from = 1, to = 8, duration = 0.6 })
	Core.converge(ground + Vector3.new(0, 1, 0), 5, 30, 0.9, GOLD)

	local model, body = buildBeast()
	model:PivotTo(CFrame.lookAt(base, base + ctx.direction))

	local t = 0
	local attackAt, attackTo = nil, nil

	local function despawn()
		Core.burst(base, 25, { texture = FIRE_TEX, color = EMBER, speed = 10, light = 0.9 })
		local parts = {}
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		Core.runFor(0.6, function(_, k)
			Core.setTransparency(parts, 0.05 + 0.95 * (k / 0.6))
		end, function()
			model:Destroy()
		end)
	end

	local finish = Core.runFor(life, function(_, time)
		t = time
		local bob = math.sin(time * 4) * 0.25
		local lunge = Vector3.zero
		if attackAt then
			local k = (time - attackAt) / 0.35
			if k >= 1 then
				attackAt = nil
			elseif attackTo then
				local dirToTarget = attackTo - base
				if dirToTarget.Magnitude > 0.1 then
					lunge = dirToTarget.Unit * math.sin(k * math.pi) * 4
				end
			end
		end
		local pos = base + Vector3.new(0, bob, 0) + lunge
		model:PivotTo(CFrame.lookAt(pos, pos + ctx.direction))
	end, despawn)

	local handle = {}
	function handle:Attack(pos)
		attackTo = pos
		attackAt = t
		Core.burst(pos, 14, { texture = FIRE_TEX, color = FIRE, speed = 16, light = 0.9 })
	end
	function handle:Despawn()
		finish()
	end
	return handle
end

-- Move3: flames build, teleport streak behind the target, concentrated beam, knockback burst
function Fire.Move3(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local from = root.Position
	local tgt = ctx.target
	local behind = ctx.targetCharacter and Core.behind(ctx.targetCharacter, 3) or (tgt - ctx.direction * 3)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })

	local auraAtt = Core.attach(root)
	local aura = Core.emitter(auraAtt, {
		texture = FIRE_TEX, color = FIRE, rate = 80, light = 0.9,
		lifetime = NumberRange.new(0.5, 0.9), speed = NumberRange.new(2, 5),
		size = NumberSequence.new(1, 0.2), direction = Enum.NormalId.Top, spread = Vector2.new(90, 90),
	})

	Core.timeline(1.0, {
		{
			t = 0.25,
			run = function()
				aura.Enabled = false
				Core.afterimage(ctx.character, { at = root.CFrame, color = ORANGE, life = 0.3 })
				Core.tempBeam(from, behind, 0.25, { color = FIRE, width0 = 1.2, light = 1 })
				Core.burst(from, 12, { texture = FIRE_TEX, color = FIRE, speed = 10 })
			end,
		},
		{
			t = 0.35,
			run = function()
				Core.shockwave(Core.groundCF(behind), { color = GOLD, from = 1, to = 8, duration = 0.35 })
			end,
		},
		{
			t = 0.45,
			run = function()
				local p0 = hand and hand.Position or from
				Core.tempBeam(p0, tgt, 0.35, { color = GOLD_SEQ, width0 = 2.2, width1 = 0.6, light = 1 })
			end,
		},
		{
			t = 0.5,
			run = function()
				Core.burst(tgt, 50, { texture = FIRE_TEX, color = FIRE, speed = 30, light = 1 })
				Core.shockwave(Core.groundCF(tgt - Vector3.new(0, 2.5, 0)), { color = ORANGE, from = 2, to = 16, duration = 0.4 })
			end,
		},
	}, function()
		aura.Enabled = false
		Core.cleanupLater({ auraAtt }, 1)
	end)
end

-- Move4: colossal fire domain (Infernal Judgement).
function Fire.Move4(ctx)
	local D = Fire.DOMAIN
	local R = ctx.radius or D.radius
	local life = ctx.duration or D.duration
	local center = ctx.origin - Vector3.new(0, 3, 0)

	Core.animeDomain(center, {
		radius = R,
		height = D.height or 45,
		duration = life,
		fadeOut = D.fadeOut or 1.2,
		color = DEEP,
		accentColor = ORANGE,
		coreColor = CORE,
		pillarCount = 36,
		pillarHeight = 35,
	})
end

return Fire
