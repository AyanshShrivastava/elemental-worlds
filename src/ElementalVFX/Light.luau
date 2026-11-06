-- Light.lua — Light element
--   M1    Dim Light Ray: narrow controlled ray
--   Move1 Amplified Light: brighter, wider ray with a glowing core
--   Move2 Mirrors of Judgement: five mirrors, a ray bouncing between them, then a luminous slam
--   Move3 Blinding Attack: small flash, short ray, and a soft glow on the target's head for 2 seconds
--         (no screen overlay, so it stays fair and non-disruptive)
--   Move4 Divine Light Amplification: 1.2s charge, then a large projectile with layered rays

local Core = require(script.Parent.Core)

local LAV = Color3.fromRGB(200, 162, 240) -- #C8A2F0
local BRIGHT = Color3.fromRGB(233, 216, 255) -- #E9D8FF
local VIOLET = Color3.fromRGB(139, 91, 214) -- #8B5BD6
local WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT = Core.seq({ LAV, BRIGHT, VIOLET })
local SPARK = Core.Textures.Sparkle

local Light = {}

-- A glowing ray that travels from `from` to `to`. Returns its travel time.
-- o: color, width, length, speed, transparency, rate
local function ray(from, to, o)
	o = o or {}
	local delta = to - from
	local dist = delta.Magnitude
	if dist < 0.1 then
		return 0
	end
	local dir = delta.Unit
	local dur = math.clamp(dist / (o.speed or 120), 0.12, 1)
	local w = o.width or 0.4
	local body = Core.part(Enum.PartType.Cylinder, Vector3.new(o.length or 6, w, w), Core.axisCF(from, dir), {
		color = o.color or LAV, material = Enum.Material.Neon, transparency = o.transparency or 0.1,
	})
	local glitter = Core.emitter(Core.attach(body), {
		texture = SPARK, color = LIGHT, rate = o.rate or 40, light = 1,
		lifetime = NumberRange.new(0.2, 0.4), speed = NumberRange.new(0.5, 2), size = NumberSequence.new(0.4, 0.05),
	})
	Core.runFor(dur, function(_, t)
		local pos = from + dir * (dist * (t / dur))
		body.CFrame = Core.axisCF(pos, dir)
	end, function()
		glitter.Enabled = false
		body.Transparency = 1
		Core.cleanupLater({ body }, 0.5)
	end)
	return dur
end

-- Straight radiating spoke that grows out from a centre and fades
local function spoke(center, dir, len, color)
	local cyl = Core.part(Enum.PartType.Cylinder, Vector3.new(1, 0.4, 0.4), Core.axisCF(center, dir), {
		color = color, material = Enum.Material.Neon, transparency = 0.1,
	})
	Core.runFor(0.5, function(_, t)
		local k = Core.smooth(t / 0.5)
		local L = math.max(len * k, 0.1)
		local w = 0.4 * (1 - k * 0.7)
		cyl.Size = Vector3.new(L, w, w)
		cyl.CFrame = Core.axisCF(center + dir * (L / 2), dir)
		cyl.Transparency = 0.1 + 0.9 * k
	end, function()
		cyl:Destroy()
	end)
end

local function handOrOrigin(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	return hand and hand.Position or ctx.origin
end

-- M1: dim ray
function Light.M1(ctx)
	local from = handOrOrigin(ctx)
	local dur = ray(from, ctx.target, { color = LAV, width = 0.4, length = 6, speed = 120 })
	task.delay(dur, function()
		Core.burst(ctx.target, 8, { color = LIGHT, texture = SPARK, speed = 8, light = 1 })
	end)
end

-- Move1: amplified ray. Outer glow and a bright core travel together.
function Light.Move1(ctx)
	local from = handOrOrigin(ctx)
	local dur = ray(from, ctx.target, { color = LAV, width = 1.6, length = 8, speed = 90, transparency = 0.5, rate = 80 })
	ray(from, ctx.target, { color = BRIGHT, width = 0.6, length = 8, speed = 90, transparency = 0.05 })
	task.delay(dur, function()
		Core.burst(ctx.target, 30, { color = LIGHT, texture = SPARK, speed = 22, light = 1 })
		Core.shockwave(Core.groundCF(ctx.target - Vector3.new(0, 2, 0)), { color = LAV, from = 1, to = 10, duration = 0.4 })
	end)
end

-- Move2: five mirrors around the target; a ray bounces between them, then slams the target
function Light.Move2(ctx)
	local center = ctx.target + Vector3.new(0, 2, 0)
	local N, R = 5, 9
	local mirrors, mirrorPos = {}, {}

	for i = 1, N do
		local a = (i - 1) / N * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)
		mirrorPos[i] = pos
		local toCenter = (center - pos).Unit
		table.insert(mirrors, Core.part(Enum.PartType.Block, Vector3.new(4, 5, 0.3), Core.lookCF(pos, toCenter), {
			color = BRIGHT, material = Enum.Material.Glass, transparency = 0.25, reflectance = 0.8,
		}))
	end

	-- bounce order around the ring, then the target
	local order = { 1, 3, 5, 2, 4 }
	local pts = { ctx.origin + Vector3.new(0, 2, 0) }
	for _, idx in ipairs(order) do
		table.insert(pts, mirrorPos[idx])
	end
	table.insert(pts, center)

	local segs = {}
	local events = {}
	for i = 1, #pts - 1 do
		local p0, p1 = pts[i], pts[i + 1]
		table.insert(events, {
			t = 0.2 + (i - 1) * 0.2,
			run = function()
				local d = p1 - p0
				local seg = Core.part(Enum.PartType.Cylinder, Vector3.new(d.Magnitude, 0.5, 0.5), Core.axisCF(p0 + d / 2, d.Unit), {
					color = BRIGHT, material = Enum.Material.Neon, transparency = 0.05,
				})
				table.insert(segs, seg)
				Core.burst(p1, 8, { color = LIGHT, texture = SPARK, speed = 8, light = 1 })
			end,
		})
	end

	local slamT = 0.2 + (#pts - 1) * 0.2
	table.insert(events, {
		t = slamT,
		run = function()
			Core.burst(center, 60, { color = BRIGHT, texture = SPARK, speed = 30, light = 1 })
			Core.shockwave(Core.groundCF(ctx.target - Vector3.new(0, 2, 0)), { color = LAV, from = 1, to = 16, duration = 0.5 })
			Core.shockwave(Core.groundCF(ctx.target - Vector3.new(0, 1.8, 0)), { color = VIOLET, from = 1, to = 10, duration = 0.35 })
		end,
	})

	Core.timeline(slamT + 0.8, events, function()
		Core.setTransparency(segs, 1)
		Core.cleanupLater(segs, 0.2)
		Core.cleanupLater(mirrors, 0.2)
	end)
end

-- Move3: blinding attack
function Light.Move3(ctx)
	local from = handOrOrigin(ctx)
	local head = ctx.targetCharacter and ctx.targetCharacter:FindFirstChild("Head")
	local hitPos = head and head.Position or (ctx.target + Vector3.new(0, 2, 0))
	local BLIND = 2

	local dur = ray(from, hitPos, { color = BRIGHT, width = 0.5, length = 7, speed = 150 })
	task.delay(dur, function()
		-- small controlled flash at the target
		local flash = Core.part(Enum.PartType.Ball, Vector3.one * 0.5, CFrame.new(hitPos), {
			color = WHITE, material = Enum.Material.Neon, transparency = 0.1,
		})
		Core.runFor(0.25, function(_, t)
			local k = t / 0.25
			flash.Size = Vector3.one * (0.5 + 3 * k)
			flash.Transparency = 0.1 + 0.9 * k
		end, function()
			flash:Destroy()
		end)

		-- blind: soft glow that follows the head for 2 seconds
		local glow = Core.part(Enum.PartType.Ball, Vector3.one * 2.6, CFrame.new(hitPos), {
			color = BRIGHT, material = Enum.Material.Neon, transparency = 0.9,
		})
		local sparks = Core.emitter(Core.attach(glow), {
			texture = SPARK, color = LIGHT, rate = 12, light = 0.8,
			lifetime = NumberRange.new(0.4, 0.8), speed = NumberRange.new(0.5, 1.5), size = NumberSequence.new(0.3, 0.05),
		})
		Core.runFor(BLIND, function(_, t)
			local p = (head and head.Parent) and head.Position or hitPos
			glow.CFrame = CFrame.new(p)
			local k = math.sin(math.min(t / BLIND, 1) * math.pi)
			glow.Transparency = 0.95 - 0.8 * k
		end, function()
			sparks.Enabled = false
			Core.cleanupLater({ glow }, 1)
		end)
	end)
end

-- Move4: divine light amplification
function Light.Move4(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local origin = root.Position
	local target = ctx.target
	local CHARGE = 1.2
	local flight = math.clamp((target - origin).Magnitude / 80, 0.35, 0.8)

	-- 1. charge: light gathers around the caster and a glow grows
	Core.converge(origin, 6, 40, CHARGE, BRIGHT)
	local charge = Core.part(Enum.PartType.Ball, Vector3.one * 0.5, CFrame.new(origin), {
		color = BRIGHT, material = Enum.Material.Neon, transparency = 0.2,
	})
	Core.runFor(CHARGE, function(_, t)
		local k = Core.smooth(t / CHARGE)
		charge.Size = Vector3.one * (0.5 + 4.5 * k)
		charge.CFrame = CFrame.new(origin)
	end, function()
		charge:Destroy()

		-- 2. release: big luminous projectile with layered rays along its path
		local orb = Core.part(Enum.PartType.Ball, Vector3.one * 5, CFrame.new(origin), {
			color = LAV, material = Enum.Material.Neon, transparency = 0.05,
		})
		local dist = (target - origin).Magnitude
		ray(origin, target, { color = LAV, width = 1.2, length = 8, speed = dist / flight, transparency = 0.5, rate = 60 })
		ray(origin, target, { color = VIOLET, width = 2.4, length = 8, speed = dist / flight, transparency = 0.7, rate = 30 })
		ray(origin, target, { color = WHITE, width = 0.4, length = 8, speed = dist / flight, transparency = 0.05, rate = 40 })

		Core.runFor(flight, function(_, t)
			orb.CFrame = CFrame.new(origin:Lerp(target, Core.smooth(t / flight)))
		end, function()
			-- 3. impact: burst, staggered rings, radiating spokes
			orb.Transparency = 1
			Core.burst(target, 80, { color = LIGHT, texture = SPARK, speed = 40, light = 1, life = 0.5 })
			for i = 1, 3 do
				task.delay((i - 1) * 0.08, function()
					Core.shockwave(Core.groundCF(target - Vector3.new(0, 2, 0)), {
						color = i == 1 and WHITE or LAV, from = 1, to = 6 + i * 6, duration = 0.5,
					})
				end)
			end
			for i = 1, 8 do
				local a = (i - 1) / 8 * math.pi * 2
				spoke(target, Vector3.new(math.cos(a), 0, math.sin(a)), 10, BRIGHT)
			end
			Core.cleanupLater({ orb }, 0.6)
		end)
	end)
end

return Light
