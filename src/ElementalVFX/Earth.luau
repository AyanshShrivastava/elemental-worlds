-- Earth.lua — Earth element
--   M1    Earth Sword: rocky blade with a short stone trail
--   Move1 Earthy Wall: returns a handle for the wall's state:
--           handle:SetHealth(0..1)  shows cracks at 66% and 33%, shakes, shatters at 0
--           handle:Shatter()        breaks it apart now
--           handle:End()            sinks it into the ground now
--         It also sinks by itself after Earth.WALL.duration seconds.
--         Health and defence are server-owned. Collision: Earth.WALL.collidable is applied to the
--         visual parts only, so the server must still block movement with its own check.
--   Move2 Boulder of Destruction: rotating rock with orbiting debris and a dust trail
--   Move3 Accelerated Earth Punch: fist with rock plates that close in right before impact
--   Move4 The Master of Terra: five timed beats (launch, teleport, descend, dagger, strike).
--         Timing is in seconds from the start. No graphic effects.

local Core = require(script.Parent.Core)

local STONE = Color3.fromRGB(140, 140, 140)
local BROWN = Color3.fromRGB(110, 78, 50)
local DUST = Color3.fromRGB(190, 180, 160)
local DARK = Color3.fromRGB(80, 60, 45)
local EARTH = Core.seq({ STONE, BROWN, DUST })
local ROCK = Enum.Material.Rock
local SMOKE = Core.Textures.Smoke

local Earth = {}

-- Wall settings
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

-- M1: close-range earth sword with rocky chunks and a stone trail
function Earth.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then
		return
	end
	local dir = ctx.direction
	local start = hand.Position

	local blade = Core.part(Enum.PartType.Block, Vector3.new(0.5, 0.4, 3.6), Core.lookCF(start, dir), {
		color = STONE, material = ROCK, transparency = 0,
	})
	local parts = { blade }
	local chunks = {}
	for i = 1, 3 do
		local c = Core.part(Enum.PartType.Block, Vector3.new(0.7, 0.6, 0.7), blade.CFrame, {
			color = BROWN, material = ROCK, transparency = 0,
		})
		table.insert(chunks, { part = c, z = -1.2 + (i - 1) * 1.2 })
		table.insert(parts, c)
	end
	Core.trail(blade, Core.attach(blade, Vector3.new(0.2, 0, -1.8)), Core.attach(blade, Vector3.new(-0.2, 0, -1.8)), {
		color = EARTH, lifetime = 0.25,
	})

	local dur = 0.3
	Core.runFor(dur, function(_, t)
		local k = Core.smooth(t / dur)
		local pos = start + dir * 0.5
		blade.CFrame = Core.lookCF(pos, dir) * CFrame.Angles(0, math.rad(120) * (k - 0.5), 0)
		for _, c in ipairs(chunks) do
			c.part.CFrame = blade.CFrame * CFrame.new(0.4, 0.3, c.z)
		end
	end, function()
		Core.setTransparency(parts, 1)
		Core.burst(start + dir * 2, 8, { texture = SMOKE, color = DUST, speed = 6, light = 0 })
		Core.cleanupLater(parts, 0.5)
	end)
end

-- Move1: stone wall rises in front of the caster. Returns a handle (see header).
function Earth.Move1(ctx)
	local cfg = Earth.WALL
	local life = ctx.duration or cfg.duration
	local rng = Random.new()

	local flat = Vector3.new(ctx.direction.X, 0, ctx.direction.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local groundPos = ctx.origin - Vector3.new(0, 3, 0) + flat.Unit * 7
	local base = CFrame.lookAt(groundPos, groundPos + flat.Unit)

	local W, H, D = cfg.blockW, cfg.blockH, cfg.blockD
	local blocks = {}
	for c = 1, cfg.cols do
		for r = 1, cfg.rows do
			local x = (c - (cfg.cols + 1) / 2) * W
			local y = (r - 0.5) * H
			local part = Core.part(Enum.PartType.Block, Vector3.new(W, H, D), base, {
				color = rng:NextNumber() < 0.5 and STONE or BROWN,
				material = ROCK,
				transparency = 0,
				collide = cfg.collidable,
			})
			table.insert(blocks, { part = part, x = x, y = y, delay = (c + r) * 0.05 })
		end
	end

	local cracks = {}
	local crackStage = 0
	local shake = 0
	local mode = nil

	local function addCracks(n)
		for _ = 1, n do
			local part = Core.part(Enum.PartType.Block, Vector3.new(0.15, 1.6, 0.1), base, {
				color = DARK, material = ROCK, transparency = 0.1,
			})
			table.insert(cracks, {
				part = part,
				x = rng:NextNumber(-cfg.cols * W / 2, cfg.cols * W / 2),
				y = rng:NextNumber(0.5, cfg.rows * H - 0.5),
				z = -D / 2 - 0.05,
				rot = rng:NextNumber(0, math.pi),
			})
		end
	end

	local finish = Core.runFor(life, function(dt, t)
		local jitter = Vector3.zero
		if shake > 0 then
			shake = math.max(shake - dt * 3, 0)
			jitter = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), 0) * shake * 0.3
		end
		for _, b in ipairs(blocks) do
			local k = Core.smooth((t - b.delay) / 0.5)
			b.part.CFrame = base * CFrame.new(b.x + jitter.X, b.y + jitter.Y - (1 - k) * 10, 0)
		end
		for _, c in ipairs(cracks) do
			c.part.CFrame = base * CFrame.new(c.x + jitter.X, c.y + jitter.Y, c.z) * CFrame.Angles(0, 0, c.rot)
		end
	end, function()
		if mode == "shatter" then
			for _, b in ipairs(blocks) do
				Core.fragments(b.part.Position, 3, {
					color = b.part.Color, material = ROCK, speed = 16, minSize = 0.6, maxSize = 1.4,
				})
			end
			Core.burst(base.Position, 30, { texture = SMOKE, color = DUST, speed = 10, life = 0.8, size = NumberSequence.new(1.5, 4) })
			for _, b in ipairs(blocks) do
				b.part:Destroy()
			end
			for _, c in ipairs(cracks) do
				c.part:Destroy()
			end
		else
			-- sink into the ground (timeout or handle:End)
			for _, c in ipairs(cracks) do
				c.part:Destroy()
			end
			cracks = {}
			Core.runFor(cfg.sinkTime, function(_, k)
				for _, b in ipairs(blocks) do
					b.part.CFrame = base * CFrame.new(b.x, b.y - (k / cfg.sinkTime) * 10, 0)
				end
			end, function()
				for _, b in ipairs(blocks) do
					b.part:Destroy()
				end
			end)
		end
	end)

	local handle = {}
	function handle:SetHealth(pct)
		pct = math.clamp(pct, 0, 1)
		if pct <= 0 then
			return handle:Shatter()
		end
		if pct < 0.66 and crackStage < 1 then
			crackStage = 1
			addCracks(6)
			shake = 0.6
		end
		if pct < 0.33 and crackStage < 2 then
			crackStage = 2
			addCracks(8)
			shake = 1
		end
	end
	function handle:Shatter()
		if mode then
			return
		end
		mode = "shatter"
		finish()
	end
	function handle:End()
		if mode then
			return
		end
		mode = "sink"
		finish()
	end
	return handle
end

-- Move2: giant rotating boulder with orbiting debris, dust trail and impact
function Earth.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dur = math.max((target - origin).Magnitude / 45, 0.4)

	local rock = Core.part(Enum.PartType.Ball, Vector3.one * 5, CFrame.new(origin), {
		color = BROWN, material = ROCK, transparency = 0,
	})
	local dust = Core.emitter(Core.attach(rock), {
		texture = SMOKE, color = Core.seq(DUST), rate = 30, light = 0,
		lifetime = NumberRange.new(0.8, 1.4), speed = NumberRange.new(1, 3),
		size = NumberSequence.new(1.5, 4),
	})
	local all = { rock }
	local bits = {}
	for i = 1, 5 do
		local b = Core.part(Enum.PartType.Block, Vector3.one, CFrame.new(origin), {
			color = STONE, material = ROCK, transparency = 0,
		})
		table.insert(bits, { part = b, idx = i })
		table.insert(all, b)
	end

	local spin = 0
	Core.runFor(dur, function(dt, t)
		spin += dt
		local pos = origin:Lerp(target, math.min(t / dur, 1))
		rock.CFrame = CFrame.new(pos) * CFrame.Angles(spin * 5, spin * 3, spin * 4)
		for _, b in ipairs(bits) do
			local a = spin * 5 + b.idx * (math.pi * 2 / 5)
			b.part.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 4, math.sin(a * 2) * 0.8, math.sin(a) * 4))
				* CFrame.Angles(a, a, a)
		end
	end, function()
		dust.Enabled = false
		Core.animeSpikeBurst(target, {
			color = STONE, coreColor = DUST, outlineColor = DARK,
			count = 10, radius = 9, minHeight = 9, maxHeight = 17, duration = 0.65,
		})
		Core.shockwave(Core.groundCF(target - Vector3.new(0, 2.5, 0)), { color = DUST, from = 2, to = 20, duration = 0.6 })
		Core.burst(target, 30, { texture = SMOKE, color = DUST, speed = 16, light = 0, size = NumberSequence.new(2, 4), life = 0.8 })
		Core.fragments(target, 14, { color = BROWN, material = ROCK, speed = 25, minSize = 0.4, maxSize = 1.2 })
		Core.setTransparency(all, 1)
		Core.cleanupLater(all, 1)
	end)
end

-- Move3: punch that turns earth-infused just before impact
function Earth.Move3(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	if not hand then
		return
	end
	local from = hand.Position
	local to = ctx.target
	local dir = (to - from).Unit

	local fist = Core.part(Enum.PartType.Block, Vector3.one * 1.2, CFrame.new(from), {
		color = BROWN, material = ROCK, transparency = 0,
	})
	local plates = {}
	for i = 1, 4 do
		plates[i] = Core.part(Enum.PartType.Block, Vector3.new(2.2, 0.4, 2.2), CFrame.new(from), {
			color = STONE, material = ROCK, transparency = 1,
		})
	end
	local all = { fist }
	for _, p in ipairs(plates) do
		table.insert(all, p)
	end

	local dur = 0.45
	Core.runFor(dur, function(_, t)
		local k = math.min(t / dur, 1)
		local pos = from:Lerp(to, k * k) -- accelerates into the target
		local F = Core.lookCF(pos, dir)
		fist.CFrame = F

		-- rock plates close in during the last ~25% of the travel
		local p = math.clamp((t - 0.34) / 0.11, 0, 1)
		for i, plate in ipairs(plates) do
			local a = i * math.pi / 2 + t * 8
			local radius = 2.5 - 1.1 * p
			plate.Transparency = 1 - p * 0.9
			plate.CFrame = F * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a)
		end
	end, function()
		Core.animeSpikeBurst(to, {
			color = STONE, coreColor = DUST, outlineColor = DARK,
			count = 8, radius = 6, minHeight = 6, maxHeight = 12, duration = 0.5,
		})
		Core.burst(to, 30, { texture = SMOKE, color = Core.seq(DUST), speed = 14, life = 0.6, size = NumberSequence.new(1, 3) })
		Core.fragments(to, 12, { color = STONE, material = ROCK, speed = 22 })
		Core.shockwave(Core.groundCF(to - Vector3.new(0, 2.5, 0)), { color = DUST, from = 1, to = 10, duration = 0.4 })
		Core.destroyAll(all)
	end)
end

-- Move4: colossal terra domain (70 studs radius)
function Earth.Move4(ctx)
	local target = ctx.target
	local behind = ctx.targetCharacter and Core.behind(ctx.targetCharacter, 3) or (target - ctx.direction * 3)
	local ground = target - Vector3.new(0, 3, 0)
	local junk = {}
	local R = ctx.radius or 70

	Core.timeline(3.5, {
		{
			t = 0.0, -- 1. launch: rock burst under the target, dust pushing up
			run = function()
				Core.burst(ground, 35, {
					texture = SMOKE, color = Core.seq(DUST), speed = 22, life = 0.8,
					size = NumberSequence.new(1.5, 4), aim = ground + Vector3.new(0, 12, 0),
				})
				Core.fragments(ground, 14, { color = STONE, material = ROCK, speed = 18, dirY = Vector2.new(0.6, 1) })
			end,
		},
		{
			t = 0.6, -- 2. teleport behind: afterimages along the path
			run = function()
				if ctx.root then
					Core.afterimage(ctx.character, { at = ctx.root.CFrame, color = BROWN, life = 0.4 })
				end
				Core.afterimage(ctx.character, { at = CFrame.new(behind), color = BROWN, life = 0.4 })
				Core.burst(behind, 16, { texture = SMOKE, color = Core.seq(DUST), speed = 8, life = 0.6 })
			end,
		},
		{
			t = 1.2, -- 3. both descend: falling rock above the target
			run = function()
				Core.fragments(target + Vector3.new(0, 8, 0), 16, {
					color = BROWN, material = ROCK, speed = 6, dirY = Vector2.new(-1, -0.3), life = 1.0,
				})
			end,
		},
		{
			t = 1.6, -- 4. earth dagger appears at the marker and drops onto the target
			run = function()
				local dagger = Core.part(Enum.PartType.Block, Vector3.new(0.6, 0.6, 4), CFrame.new(target + Vector3.new(0, 8, 0)), {
					color = STONE, material = ROCK, transparency = 0,
				})
				table.insert(junk, dagger)
				Core.runFor(0.25, function(_, t)
					local pos = (target + Vector3.new(0, 8, 0)):Lerp(target, Core.smooth(t / 0.25))
					dagger.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, 0)
				end, function()
					dagger.Transparency = 1
				end)
			end,
		},
		{
			t = 1.85, -- 5. colossal terra domain eruption finishing strike
			run = function()
				Core.animeDomain(ground, {
					radius = R,
					height = 40,
					duration = 3.5,
					fadeOut = 0.8,
					color = DARK,
					accentColor = STONE,
					coreColor = DUST,
					pillarCount = 20,
					pillarHeight = 35,
				})
				Core.animeSpikeBurst(ground, {
					color = STONE,
					coreColor = DUST,
					outlineColor = DARK,
					count = 16,
					radius = 14,
					minHeight = 14,
					maxHeight = 26,
					duration = 0.9,
				})
				Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.2, 0)), { color = DUST, from = 2, to = R, duration = 0.6 })
				Core.burst(target, 60, { texture = SMOKE, color = Core.seq(DUST), speed = 28, life = 0.9, size = NumberSequence.new(1.5, 5) })
				Core.fragments(target, 28, { color = STONE, material = ROCK, speed = 36, life = 1.1 })
			end,
		},
	}, function()
		Core.cleanupLater(junk, 1)
	end)
end

return Earth
