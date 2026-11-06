-- Wind.lua — Wind element
--   M1    Compressed Wind: lightning-bolt shaped projectile with compressed-air rings
--   Move1 Airy Vortex: rotating cone of compressed wind thrown forward
--   Move2 The Cyclone of Fury: tall rotating tornado at the target. ctx.radius sets the pull area
--         (default 14). ctx.duration sets how long it lasts (default 5).
--   Move3 Maximum Speed: wind rings around the caster for ctx.duration (default 5), with a trail
--         while moving fast. Speed boost itself is server-side.
--   Move4 Wind: Death Speed: timed sequence (lift, spiral, dive, impact, ride a rock,
--         form the bolt, dash). Debris and rings are temporary. The map is never changed.

local Core = require(script.Parent.Core)

local WHITE = Color3.fromRGB(255, 255, 255)
local PCYAN = Color3.fromRGB(180, 240, 255)
local MINT = Color3.fromRGB(170, 255, 220)
local WIND = Core.seq({ WHITE, PCYAN, MINT })
local DUST = Color3.fromRGB(215, 225, 220)
local ROCK_C = Color3.fromRGB(120, 115, 110)
local SPARK = Core.Textures.Sparkle
local SMOKE = Core.Textures.Smoke
local ROCK = Enum.Material.Rock

local Wind = {}

-- Lightning bolt: zigzag points along the travel axis (local Z)
local BOLT_PTS = {
	Vector3.new(0, 0, -1.8),
	Vector3.new(0.9, 0, -0.9),
	Vector3.new(-0.6, 0, 0),
	Vector3.new(0.8, 0, 0.9),
	Vector3.new(0, 0, 1.8),
}

-- Places bolt segments so the bolt sits at cf
function Wind.placeBolt(segs, cf)
	for i, seg in ipairs(segs) do
		local a = cf * BOLT_PTS[i]
		local b = cf * BOLT_PTS[i + 1]
		local d = b - a
		seg.Size = Vector3.new(0.3, 0.3, d.Magnitude)
		seg.CFrame = CFrame.lookAt(a + d / 2, b)
	end
end

-- Creates the bolt segments at cf and returns them
local function buildBolt(cf)
	local segs = {}
	for i = 1, #BOLT_PTS - 1 do
		table.insert(segs, Core.part(Enum.PartType.Block, Vector3.new(0.3, 0.3, 1), cf, {
			color = WHITE, material = Enum.Material.Neon, transparency = 0.05,
		}))
	end
	Wind.placeBolt(segs, cf)
	return segs
end

-- Travels a bolt from `from` to `to`, leaving compressed-air rings and a trail.
-- Returns the travel time.
function Wind.dashBolt(from, to, speed)
	local delta = to - from
	local dist = delta.Magnitude
	if dist < 0.5 then
		return 0
	end
	local dir = delta.Unit
	local dur = math.clamp(dist / (speed or 120), 0.15, 1.5)
	local segs = buildBolt(Core.lookCF(from, dir))

	local tip = Core.anchor(from)
	Core.trail(tip, Core.attach(tip, Vector3.new(0.6, 0, 0)), Core.attach(tip, Vector3.new(-0.6, 0, 0)), {
		color = WIND, lifetime = 0.35,
	})

	local lastRing = 0
	Core.runFor(dur, function(_, t)
		local pos = from + dir * (dist * (t / dur))
		local cf = Core.lookCF(pos, dir)
		Wind.placeBolt(segs, cf)
		tip.CFrame = cf
		if t - lastRing >= 0.06 then
			lastRing = t
			Core.shockwave(Core.axisCF(pos, dir), { color = PCYAN, from = 0.8, to = 3.2, duration = 0.25 })
		end
	end, function()
		Core.setTransparency(segs, 1)
		Core.cleanupLater(segs, 0.1)
		Core.cleanupLater({ tip }, 0.4)
	end)
	return dur
end

-- Blocks spiral from a to b over `dur` seconds (compressed-air spiral)
function Wind.spiral(a, b, dur, radius, count, color)
	local parts = {}
	for i = 1, count do
		parts[i] = Core.part(Enum.PartType.Block, Vector3.new(0.4, 0.4, 0.9), CFrame.new(a), {
			color = color, material = Enum.Material.Neon, transparency = 0.2,
		})
	end
	Core.runFor(dur, function(_, t)
		local k = t / dur
		local c = a:Lerp(b, k)
		local r = radius * (1 - k * 0.5)
		for i, p in ipairs(parts) do
			local ang = k * math.pi * 8 + i * (math.pi * 2 / count)
			local pos = c + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
			p.CFrame = CFrame.new(pos) * CFrame.Angles(0, -ang, 0)
		end
	end, function()
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.1)
	end)
end

-- M1: compressed-wind lightning bolt
function Wind.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	local from = (hand and hand.Position or ctx.origin) + ctx.direction * 2
	local dur = Wind.dashBolt(from, ctx.target, 110)
	task.delay(dur, function()
		Core.burst(ctx.target, 10, { color = WIND, texture = SPARK, speed = 12, light = 1 })
	end)
end

-- Move1: rotating cone of compressed wind, thrown forward
function Wind.Move1(ctx)
	local dir = ctx.direction
	local origin = ctx.origin + dir * 3
	local target = ctx.target
	local dur = math.max((target - origin).Magnitude / 50, 0.4)

	local tip = Core.anchor(origin)
	local dust = Core.emitter(Core.attach(tip), {
		texture = SMOKE, color = Core.seq(DUST), rate = 25, light = 0,
		lifetime = NumberRange.new(0.6, 1.0), speed = NumberRange.new(1, 3), size = NumberSequence.new(1, 3),
	})

	local LAYERS, PER = 6, 4
	local parts, bits = { tip }, {}
	for i = 1, LAYERS do
		for k = 1, PER do
			local p = Core.part(Enum.PartType.Block, Vector3.new(0.4, 0.6, 0.6), CFrame.new(origin), {
				color = PCYAN, material = Enum.Material.Neon, transparency = 0.2,
			})
			table.insert(bits, { part = p, layer = i, idx = k })
			table.insert(parts, p)
		end
	end

	local spin = 0
	Core.runFor(dur, function(dt, t)
		spin += dt
		local base = origin:Lerp(target, math.min(t / dur, 1))
		tip.CFrame = CFrame.new(base)
		for _, b in ipairs(bits) do
			-- narrow at the front, wider behind
			local r = 0.5 + b.layer * 0.5
			local a = spin * (4 + b.layer * 0.6) + b.idx * (math.pi / 2)
			local F = Core.axisCF(base - dir * (b.layer * 0.6), dir)
			b.part.CFrame = F * CFrame.new(0, math.cos(a) * r, math.sin(a) * r)
		end
	end, function()
		dust.Enabled = false
		Core.burst(target, 20, { texture = SMOKE, color = Core.seq(DUST), speed = 10, light = 0 })
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.4)
	end)
end

-- Move2: tall cyclone at the target. Pulls particles inward every 0.8s.
function Wind.Move2(ctx)
	local ground = Vector3.new(ctx.target.X, ctx.target.Y - 3, ctx.target.Z)
	local life = ctx.duration or 5
	local R = ctx.radius or 14
	local H, LAYERS, PER = 18, 12, 5

	local boundary = Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, R * 2, R * 2), Core.groundCF(ground + Vector3.new(0, 0.1, 0)), {
		color = MINT, material = Enum.Material.Neon, transparency = 0.7,
	})
	local anchor = Core.anchor(ground + Vector3.new(0, 1, 0))
	local leaves = Core.emitter(Core.attach(anchor), {
		texture = SPARK, color = Core.seq(MINT), rate = 25, light = 0.5,
		lifetime = NumberRange.new(1.2, 1.8), speed = NumberRange.new(4, 8),
		spread = Vector2.new(180, 180), direction = Enum.NormalId.Top,
	})

	local layers, parts = {}, { boundary, anchor }
	for i = 1, LAYERS do
		for k = 1, PER do
			local p = Core.part(Enum.PartType.Block, Vector3.new(1.4, 0.3, 0.5), CFrame.new(ground), {
				color = WHITE, material = Enum.Material.Glass, transparency = 0.25,
			})
			table.insert(layers, { part = p, layer = i, idx = k })
			table.insert(parts, p)
		end
	end

	local spin, lastPull = 0, 0
	Core.runFor(life, function(dt, t)
		spin += dt
		if t - lastPull >= 0.8 then
			lastPull = t
			Core.converge(ground + Vector3.new(0, 3, 0), R, 14, 0.8, MINT)
		end
		for _, b in ipairs(layers) do
			local y = (b.layer - 1) * (H / LAYERS)
			local r = 2 + (b.layer - 1) * 0.6
			local a = spin * (10 - b.layer * 0.4) + b.idx * (math.pi * 2 / PER)
			local p = ground + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
			b.part.CFrame = CFrame.new(p) * CFrame.Angles(0, -(a + math.pi / 2), 0)
		end
	end, function()
		leaves.Enabled = false
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.5)
	end)
end

-- Move3: wind rings around the caster, with a short trail while moving fast
function Wind.Move3(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local life = ctx.duration or 5
	local heights = { -2.4, 0, 1.8 }
	local rings = {}
	for j = 1, #heights do
		for i = 1, 6 do
			table.insert(rings, { part = Core.part(Enum.PartType.Block, Vector3.new(0.5, 0.4, 0.9), CFrame.new(root.Position), {
				color = PCYAN, material = Enum.Material.Neon, transparency = 0.2,
			}), layer = j, idx = i })
		end
	end

	local spin, lastPuff = 0, 0
	Core.runFor(life, function(dt, t)
		spin += dt
		local base = root.Position
		for _, r in ipairs(rings) do
			local a = spin * (8 + r.layer * 2) + r.idx * (math.pi / 3)
			local pos = base + Vector3.new(math.cos(a) * 2.2, heights[r.layer], math.sin(a) * 2.2)
			r.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, -(a + math.pi / 2), 0)
		end
		-- short wind trail while moving fast
		if root.Parent and root.AssemblyLinearVelocity.Magnitude > 10 and t - lastPuff >= 0.08 then
			lastPuff = t
			Core.ghost(CFrame.new(base - Vector3.new(0, 1, 0)), Vector3.one * 1.2, PCYAN, 0.35, Enum.PartType.Ball)
		end
	end, function()
		local parts = {}
		for _, r in ipairs(rings) do
			table.insert(parts, r.part)
		end
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.1)
	end)
end

-- Move4: death speed sequence. Times are seconds from the start.
function Wind.Move4(ctx)
	local root = ctx.root
	local target = ctx.target
	local ground = target - Vector3.new(0, 3, 0)
	local top = ground + Vector3.new(0, 10, 0)
	local junk = {}
	local boltFrom = nil
	local boltSegs = {}

	Core.timeline(4.4, {
		{
			t = 0.0, -- 1. lift the target: spiral rising from the ground
			run = function()
				Wind.spiral(ground, top, 1.0, 3, 10, PCYAN)
			end,
		},
		{
			t = 1.1, -- 2. rise with them: second spiral above
			run = function()
				Wind.spiral(top, top + Vector3.new(0, 4, 0), 0.6, 4, 8, WHITE)
			end,
		},
		{
			t = 1.8, -- 3. dive: streaks and a downward spiral
			run = function()
				for i = 1, 6 do
					local a = i * math.pi / 3
					local off = Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3)
					Core.tempBeam(ground + Vector3.new(0, 14, 0) + off, ground + off, 0.4, {
						color = PCYAN, width0 = 0.4, width1 = 0.1, light = 1,
					})
				end
				Wind.spiral(top, ground, 0.5, 4, 10, WHITE)
			end,
		},
		{
			t = 2.2, -- 4. impact: rings, dust, and rock debris (temporary, nothing is changed)
			run = function()
				Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.2, 0)), { color = WHITE, from = 2, to = 22, duration = 0.6 })
				Core.burst(ground, 40, { texture = SMOKE, color = Core.seq(DUST), speed = 18, life = 0.8, size = NumberSequence.new(1.5, 4) })
				Core.fragments(ground, 16, { color = ROCK_C, material = ROCK, speed = 26, life = 1.0 })
			end,
		},
		{
			t = 2.5, -- 5. ride a rock that follows the caster for a moment
			run = function()
				local rock = Core.part(Enum.PartType.Block, Vector3.new(5, 1.5, 5), CFrame.new(ground), {
					color = ROCK_C, material = ROCK, transparency = 0,
				})
				table.insert(junk, rock)
				Core.runFor(1.0, function()
					if root and root.Parent then
						rock.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0))
					end
				end, function()
					rock:Destroy()
				end)
			end,
		},
		{
			t = 3.5, -- 6. form the lightning bolt in front of the caster
			run = function()
				boltFrom = (root and root.Position or ctx.origin) + ctx.direction * 4
				boltSegs = buildBolt(Core.lookCF(boltFrom, ctx.direction))
			end,
		},
		{
			t = 3.9, -- 7. dash toward the target, then impact
			run = function()
				Core.destroyAll(boltSegs)
				local dur = Wind.dashBolt(boltFrom, target, 150)
				task.delay(dur, function()
					Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.2, 0)), { color = WHITE, from = 2, to = 26, duration = 0.6 })
					Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.3, 0)), { color = PCYAN, from = 1, to = 12, duration = 0.4 })
					Core.burst(target, 70, { texture = SMOKE, color = Core.seq(DUST), speed = 30, life = 0.6, light = 0.5 })
					Core.burst(target, 40, { color = WIND, texture = SPARK, speed = 36, light = 1 })
					Core.fragments(target, 18, { color = ROCK_C, material = ROCK, speed = 34 })
				end)
			end,
		},
	}, function()
		Core.cleanupLater(junk, 0.2)
	end)
end

return Wind
