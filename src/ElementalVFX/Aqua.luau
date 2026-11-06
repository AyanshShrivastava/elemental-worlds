-- Aqua.lua — Water element
--   M1    Water: two quick compressed streams from both hands
--   Move1 Water Hand: large translucent hand gathers, advances, strikes
--   Move2 Vortex of Destruction: spinning dense water sphere flies to target
--   Move3 Water Dragon: returns a handle. handle:End(hitPos) bursts droplets at hitPos;
--         handle:End() just dissolves it. Also ends by itself after ctx.duration (default 5).
--   Move4 Limitless Punches: rapid punches with trails, afterimages, layered splashes

local Core = require(script.Parent.Core)

local BLUE = Color3.fromRGB(0, 110, 255)
local CYAN = Color3.fromRGB(0, 255, 255)
local TURQUOISE = Color3.fromRGB(64, 224, 208)
local WATER = Core.seq({ CYAN, TURQUOISE, BLUE })
local SPARK = Core.Textures.Sparkle

local Aqua = {}

-- Move1 hand: palm, four fingers, thumb (local offsets from the palm)
local HAND = {
	{ size = Vector3.new(3.6, 3.2, 0.9), offset = Vector3.new(0, 0, 0) },
	{ size = Vector3.new(0.8, 2.4, 0.8), offset = Vector3.new(-1.35, 2.7, 0) },
	{ size = Vector3.new(0.8, 2.8, 0.8), offset = Vector3.new(-0.45, 2.9, 0) },
	{ size = Vector3.new(0.8, 2.6, 0.8), offset = Vector3.new(0.45, 2.8, 0) },
	{ size = Vector3.new(0.8, 2.0, 0.8), offset = Vector3.new(1.3, 2.5, 0) },
	{ size = Vector3.new(0.8, 1.8, 0.8), offset = Vector3.new(2.1, 0.8, 0) },
}

-- M1: two quick, compressed water streams from both hands
function Aqua.M1(ctx)
	local dir = ctx.direction
	local hands = {
		Core.getPart(ctx.character, { "LeftHand", "Left Arm" }),
		Core.getPart(ctx.character, { "RightHand", "Right Arm" }),
	}
	for _, hand in ipairs(hands) do
		if hand then
			local origin = hand.Position
			local stream = Core.anchor(origin)
			stream.CFrame = Core.lookCF(origin, dir)
			local e = Core.emitter(Core.attach(stream), {
				texture = SPARK,
				color = WATER,
				rate = 200,
				lifetime = NumberRange.new(0.2, 0.3),
				speed = NumberRange.new(90, 110),
				spread = Vector2.new(3, 3),
				direction = Enum.NormalId.Front,
				size = NumberSequence.new(0.5, 0.2),
				squash = NumberSequence.new(5),
			})
			Core.runFor(0.3, function(_, t)
				local pos = origin + dir * (t / 0.3) * 12
				stream.CFrame = Core.lookCF(pos, dir)
			end, function()
				e.Enabled = false
				Core.cleanupLater({ stream }, 0.5)
			end)
		end
	end
end

-- Move1: a large translucent water hand gathers, advances and slams the target
function Aqua.Move1(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local startPos = root.Position + ctx.direction * 4 + Vector3.new(0, 1.5, 0)
	local dir = (ctx.target - startPos).Unit
	local orient = Core.lookCF(Vector3.zero, dir)

	local parts = {}
	for i, d in ipairs(HAND) do
		parts[i] = Core.part(Enum.PartType.Block, d.size, CFrame.new(startPos), {
			color = i == 1 and TURQUOISE or CYAN,
			transparency = 0.45,
		})
	end
	local gather = Core.emitter(Core.attach(parts[1]), {
		texture = SPARK,
		color = WATER,
		rate = 60,
		lifetime = NumberRange.new(0.3, 0.5),
		speed = NumberRange.new(3, 6),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(0.35, 0.05),
	})

	local ring = Core.part(Enum.PartType.Cylinder, Vector3.new(0.2, 1, 1), CFrame.new(ctx.target), {
		color = CYAN, material = Enum.Material.Neon, transparency = 1,
	})
	local struck = false

	Core.runFor(1.15, function(_, t)
		local s, pos
		if t < 0.4 then
			-- gather
			s = 0.2 + 0.8 * Core.smooth(t / 0.4)
			pos = startPos
		elseif t < 0.75 then
			-- advance
			s = 1
			pos = startPos:Lerp(ctx.target, Core.smooth((t - 0.4) / 0.35))
		else
			-- strike
			s = 1.1
			pos = ctx.target
			if not struck then
				struck = true
				gather.Enabled = false
				Core.burst(ctx.target, 60, { color = WATER, texture = SPARK, speed = 25, light = 1 })
			end
			local k = math.clamp((t - 0.75) / 0.4, 0, 1)
			local d = 2 + 12 * k
			ring.Size = Vector3.new(0.2, d, d)
			ring.CFrame = Core.axisCF(ctx.target, dir)
			ring.Transparency = 0.35 + 0.65 * k
		end

		local fade = math.clamp((t - 0.9) / 0.25, 0, 1)
		for i, d in ipairs(HAND) do
			parts[i].Size = d.size * s
			parts[i].CFrame = CFrame.new(pos) * orient * CFrame.new(d.offset * s)
			parts[i].Transparency = 0.45 + 0.55 * fade
		end
	end, function()
		Core.destroyAll(parts)
		ring:Destroy()
	end)
end

-- Move2: dense, rapidly spinning water sphere with currents and orbiting droplets
function Aqua.Move2(ctx)
	local origin = ctx.origin
	local target = ctx.target

	local core = Core.part(Enum.PartType.Ball, Vector3.one * 3.5, CFrame.new(origin), {
		color = BLUE, transparency = 0.15,
	})
	local ringA = Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, 5.6, 5.6), CFrame.new(origin), {
		color = CYAN, transparency = 0.55,
	})
	local ringB = Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, 5.0, 5.0), CFrame.new(origin), {
		color = CYAN, transparency = 0.55,
	})
	local drops = {}
	for i = 1, 6 do
		drops[i] = Core.part(Enum.PartType.Ball, Vector3.one * 0.45, CFrame.new(origin), {
			color = CYAN, transparency = 0.1,
		})
	end
	local all = { core, ringA, ringB }
	for _, d in ipairs(drops) do
		table.insert(all, d)
	end

	local spin = 0
	Core.runFor(0.9, function(dt, t)
		spin += dt
		local c = origin:Lerp(target, math.min(t / 0.7, 1))
		local cf = CFrame.new(c)
		core.CFrame = cf * CFrame.Angles(0, spin * 25, 0)
		ringA.CFrame = cf * CFrame.Angles(math.rad(25), spin * 18, 0) * CFrame.Angles(0, 0, math.rad(90))
		ringB.CFrame = cf * CFrame.Angles(0, spin * -12, 0)
		for i, d in ipairs(drops) do
			local a = spin * 6 + i * (math.pi * 2 / #drops)
			d.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 3.2, math.sin(a * 2) * 0.9, math.sin(a) * 3.2))
		end
	end, function()
		Core.burst(target, 50, { color = WATER, texture = SPARK, speed = 22, light = 1 })
		Core.destroyAll(all)
	end)
end

-- Move3: water dragon. Spirals around the caster, forms a body with a watery trail.
-- Returns a handle: handle:End(hitPos) or handle:End()
function Aqua.Move3(ctx)
	local root = ctx.root
	if not root then
		return nil
	end
	local life = ctx.duration or 5
	local N = 9

	local segs, atts, all = {}, {}, {}
	for i = 1, N do
		local size = 2.2 - (i - 1) * 0.16
		local p = Core.part(Enum.PartType.Ball, Vector3.one * size, root.CFrame, {
			color = i == 1 and CYAN or TURQUOISE,
			transparency = 0.45,
		})
		segs[i] = { part = p, size = size }
		atts[i] = Core.attach(p)
		table.insert(all, p)
	end
	for i = 1, N - 1 do
		local b = Core.beam(atts[i], atts[i + 1], {
			color = WATER,
			transparency = Core.FADE,
			width0 = segs[i].size * 0.9,
			width1 = segs[i + 1].size * 0.9,
			light = 0.5,
		})
		table.insert(all, b)
	end

	local head = segs[1].part
	Core.trail(head, Core.attach(head, Vector3.new(0.9, 0, 0)), Core.attach(head, Vector3.new(-0.9, 0, 0)), {
		color = WATER, lifetime = 0.8,
	})

	local eyes = {}
	for i = 1, 2 do
		eyes[i] = Core.part(Enum.PartType.Ball, Vector3.one * 0.35, head.CFrame, {
			color = CYAN, material = Enum.Material.Neon, transparency = 0,
		})
		table.insert(all, eyes[i])
	end

	local drip = Core.emitter(Core.attach(segs[N].part), {
		texture = SPARK,
		color = WATER,
		rate = 30,
		lifetime = NumberRange.new(0.4, 0.6),
		speed = NumberRange.new(1, 3),
		spread = Vector2.new(60, 60),
		size = NumberSequence.new(0.4, 0.1),
	})

	local ended = false
	local finish = Core.runFor(life, function(_, time)
		local form = math.min(time / 0.8, 1) -- 0 = spiral around caster, 1 = dragon body
		local fwd, right = root.CFrame.LookVector, root.CFrame.RightVector
		local headPos = root.Position + fwd * 3 + Vector3.new(0, 1.5, 0)

		for i, s in ipairs(segs) do
			local wave = math.sin(time * 6 - i * 0.7) * 0.9 * (i / N)
			local bob = math.sin(time * 4 - i * 0.5) * 0.4
			local body = headPos - fwd * ((i - 1) * 1.1) + right * wave + Vector3.new(0, bob, 0)

			local a = time * 10 + i * 0.7
			local R = 1.5 + 3 * (1 - form)
			local spiral = root.Position + Vector3.new(math.cos(a) * R, 1 + i * 0.35, math.sin(a) * R)

			s.part.CFrame = CFrame.new(spiral:Lerp(body, form))
		end

		local hp = segs[1].part.Position
		local headCF = CFrame.lookAt(hp, hp + fwd)
		eyes[1].CFrame = headCF * CFrame.new(-0.5, 0.3, -0.9)
		eyes[2].CFrame = headCF * CFrame.new(0.5, 0.3, -0.9)
	end, function()
		ended = true
		drip.Enabled = false
		Core.cleanupLater(all, 1)
	end)

	return {
		End = function(_, hitPos)
			if ended then
				return
			end
			if hitPos then
				Core.burst(segs[1].part.Position, 40, {
					aim = hitPos, color = WATER, texture = SPARK, speed = 40, light = 1,
				})
			end
			finish()
		end,
	}
end

-- Move4: flurry of fast water punches with trails, afterimages and layered splashes
function Aqua.Move4(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local count = ctx.punches or 14
	local dir = ctx.direction

	for i = 1, count do
		task.delay((i - 1) * 0.08, function()
			if not root.Parent then
				return
			end
			local side = (i % 2 == 0) and 1 or -1
			local last = i == count
			local size = last and 3 or 1.6
			local from = (root.CFrame * CFrame.new(side * 1.4, 0.2, -1.5)).Position
			local to = ctx.target + Vector3.new(side * 0.6, 0, 0)

			local fist = Core.part(Enum.PartType.Ball, Vector3.one * size, CFrame.new(from), {
				color = CYAN, transparency = 0.3,
			})
			Core.trail(fist, Core.attach(fist, Vector3.new(0, size / 2, 0)), Core.attach(fist, Vector3.new(0, -size / 2, 0)), {
				color = WATER, lifetime = 0.25,
			})

			local ghostA, ghostB, hit = false, false, false
			Core.runFor(0.3, function(_, t)
				local k = math.min(t / 0.07, 1)
				fist.CFrame = CFrame.new(from:Lerp(to, k))
				fist.Transparency = 0.3 + 0.7 * math.max(0, (t - 0.07) / 0.23)

				-- flowing afterimages behind the fist
				if not ghostA and k >= 0.4 then
					ghostA = true
					Core.ghost(CFrame.new(from:Lerp(to, 0.4)), Vector3.one * size, CYAN, 0.25, Enum.PartType.Ball)
				end
				if not ghostB and k >= 0.7 then
					ghostB = true
					Core.ghost(CFrame.new(from:Lerp(to, 0.7)), Vector3.one * size * 0.9, TURQUOISE, 0.2, Enum.PartType.Ball)
				end

				-- layered impact: splash, a second splash slightly later, and a ring
				if not hit and k >= 1 then
					hit = true
					Core.burst(to, last and 60 or 18, {
						color = WATER, texture = SPARK, speed = last and 35 or 20, light = 1,
					})
					task.delay(0.05, function()
						Core.burst(to, last and 40 or 10, { color = WATER, texture = SPARK, speed = 25 })
					end)
					Core.shockwave(Core.axisCF(to, dir), {
						color = CYAN, from = 1, to = last and 14 or 5, duration = 0.3,
					})
				end
			end, function()
				fist:Destroy()
			end)
		end)
	end
end

return Aqua
