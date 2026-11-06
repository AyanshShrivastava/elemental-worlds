-- Time.lua — Time element (secret)
--   M1    Time Punch: cyan-blue aura around the fist, ripple at impact
--   Move1 Got Throwed: temporal ring holds the target, afterimages mark the teleport,
--         then a hard punch. The 0.5s hold is enforced by the server.
--   Move2 Time Injection: clock ring freezes, abstract symbol streams, echoes, then a high-damage
--         impact. Symbols are abstract glyphs, not graphic imagery.
--   Move3 Untouchable: translucent temporal shield with concentric rings that follows the caster.
--         Returns a handle: handle:Hit() flashes the shield when an attack is blocked,
--         handle:End() ends it early. Duration is ctx.duration (default 4), a balance setting.
--         Blocking and cooldown are server-side.
--   Move4 Virtual Kill: rings close on the target, the scene distorts, then a blue release.
--         No graphic imagery. The 150s cooldown and KO rules are server-side.

local Core = require(script.Parent.Core)

local DEEP = Color3.fromRGB(20, 60, 200)
local CYAN = Color3.fromRGB(0, 255, 255)
local BRIGHT = Color3.fromRGB(210, 245, 255)
local TIME = Core.seq({ DEEP, CYAN, BRIGHT })
local SPARK = Core.Textures.Sparkle

local SYMBOLS = { "Ω", "∑", "≈", "◆", "▲", "∆", "0", "1" }

local Time = {}
local rng = Random.new()

-- Abstract symbol drifting outward from a centre and fading
local function symbol(center)
	local a = rng:NextNumber(0, math.pi * 2)
	local dir = Vector3.new(math.cos(a), rng:NextNumber(0.1, 0.6), math.sin(a))
	local anchor = Core.anchor(center + dir * 2)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(40, 40)
	gui.AlwaysOnTop = true
	gui.Adornee = anchor
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Code
	label.TextColor3 = BRIGHT
	label.Text = SYMBOLS[rng:NextInteger(1, #SYMBOLS)]
	label.Parent = gui

	Core.runFor(0.6, function(_, t)
		local k = t / 0.6
		anchor.CFrame = CFrame.new(center + dir * (2 + 6 * k))
		label.TextTransparency = k
	end, function()
		anchor:Destroy()
	end)
end

-- M1: time punch
function Time.M1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	local from = hand and hand.Position or ctx.origin
	local to = ctx.target
	local dir = (to - from).Unit

	local fist = Core.part(Enum.PartType.Ball, Vector3.one * 1.4, CFrame.new(from), {
		color = CYAN, material = Enum.Material.ForceField, transparency = 0.1,
	})
	local aura1 = Core.part(Enum.PartType.Ball, Vector3.one * 3, CFrame.new(from), {
		color = CYAN, material = Enum.Material.Glass, transparency = 0.75,
	})
	local aura2 = Core.part(Enum.PartType.Ball, Vector3.one * 4, CFrame.new(from), {
		color = DEEP, material = Enum.Material.Glass, transparency = 0.85,
	})
	local parts = { fist, aura1, aura2 }
	local glow = Core.emitter(Core.attach(fist), {
		texture = SPARK, color = TIME, rate = 60, light = 1,
		lifetime = NumberRange.new(0.2, 0.4), speed = NumberRange.new(1, 3), size = NumberSequence.new(0.4, 0.05),
	})

	local dur = math.clamp((to - from).Magnitude / 110, 0.15, 0.6)
	Core.runFor(dur, function(_, t)
		local pos = from:Lerp(to, t / dur)
		fist.CFrame = CFrame.new(pos)
		aura1.CFrame = CFrame.new(pos)
		aura2.CFrame = CFrame.new(pos)
	end, function()
		glow.Enabled = false
		Core.shockwave(Core.axisCF(to, dir), { color = BRIGHT, from = 1, to = 10, duration = 0.4 })
		Core.shockwave(Core.axisCF(to, dir), { color = CYAN, from = 1, to = 6, duration = 0.3 })
		Core.burst(to, 20, { color = TIME, texture = SPARK, speed = 18, light = 1 })
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.5)
	end)
end

-- Move1: temporal ring, afterimages during the teleport, then a hard punch
function Time.Move1(ctx)
	local root = ctx.root
	if not root then
		return
	end
	local target = ctx.target
	local behind = ctx.targetCharacter and Core.behind(ctx.targetCharacter, 3) or (target - ctx.direction * 3)

	Core.shockwave(Core.groundCF(target - Vector3.new(0, 2.8, 0)), { color = CYAN, from = 7, to = 2, duration = 0.5 })

	Core.timeline(1.1, {
		{
			t = 0.5,
			run = function()
				Core.afterimage(ctx.character, { at = root.CFrame, color = CYAN, life = 0.3 })
			end,
		},
		{
			t = 0.6,
			run = function()
				Core.afterimage(ctx.character, { at = CFrame.new((ctx.origin + behind) / 2), color = CYAN, life = 0.3 })
			end,
		},
		{
			t = 0.7,
			run = function()
				Core.afterimage(ctx.character, { at = CFrame.new(behind), color = CYAN, life = 0.3 })
			end,
		},
		{
			t = 0.75,
			run = function()
				Core.tempBeam(ctx.origin, behind, 0.2, { color = TIME, width0 = 0.8, light = 1 })
			end,
		},
		{
			t = 0.85,
			run = function()
				local fist = Core.part(Enum.PartType.Ball, Vector3.one * 1.6, CFrame.new(behind), {
					color = CYAN, material = Enum.Material.ForceField, transparency = 0.1,
				})
				Core.runFor(0.12, function(_, t)
					fist.CFrame = CFrame.new(behind:Lerp(target, t / 0.12))
				end, function()
					fist:Destroy()
					Core.shockwave(Core.axisCF(target, ctx.direction), { color = BRIGHT, from = 1, to = 12, duration = 0.4 })
					Core.burst(target, 30, { color = TIME, texture = SPARK, speed = 24, light = 1 })
				end)
			end,
		},
	})
end

-- Move2: time injection
function Time.Move2(ctx)
	local tr = Core.root(ctx.targetCharacter)
	local center = tr and tr.Position or ctx.target
	local feet = center - Vector3.new(0, 2.8, 0)

	local parts = {}
	local ring = Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, 7, 7), Core.groundCF(feet), {
		color = CYAN, material = Enum.Material.Neon, transparency = 0.5,
	})
	table.insert(parts, ring)

	-- clock ticks around the ring
	for i = 1, 12 do
		local a = (i - 1) / 12 * math.pi * 2
		table.insert(parts, Core.part(Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.6),
			CFrame.new(feet + Vector3.new(math.cos(a) * 3.5, 0.05, math.sin(a) * 3.5)) * CFrame.Angles(0, math.pi / 2 - a, 0), {
				color = BRIGHT, material = Enum.Material.Neon, transparency = 0.1,
			}))
	end

	-- two clock hands that spin, then freeze
	local hands = {}
	for i = 1, 2 do
		hands[i] = Core.part(Enum.PartType.Block, Vector3.new(0.2, 0.2, 2.4), CFrame.new(feet), {
			color = BRIGHT, material = Enum.Material.Neon, transparency = 0.1,
		})
		table.insert(parts, hands[i])
	end

	local sparkAnchor = Core.anchor(center)
	table.insert(parts, sparkAnchor)
	local sparks = Core.emitter(Core.attach(sparkAnchor), {
		texture = SPARK, color = TIME, rate = 60, light = 1,
		lifetime = NumberRange.new(0.4, 0.8), speed = NumberRange.new(2, 6),
		spread = Vector2.new(180, 180), size = NumberSequence.new(0.4, 0.05),
	})

	-- symbol streams and overlapping echoes
	for i = 1, 14 do
		task.delay(i * 0.04, function()
			symbol(center)
		end)
	end
	if tr then
		for i = 1, 4 do
			task.delay(0.05 * i, function()
				if tr.Parent then
					Core.ghost(tr.CFrame * CFrame.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5)),
						Vector3.new(2, 5, 1), CYAN, 0.6)
				end
			end)
		end
	end

	Core.runFor(1.2, function(_, t)
		for i, h in ipairs(hands) do
			local th = math.min(t, 0.4) * 12 * i -- spin, then freeze at 0.4s
			h.CFrame = CFrame.new(feet) * CFrame.Angles(0, th, 0) * CFrame.new(0, 0, -1.2)
		end
	end, function()
		sparks.Enabled = false
		Core.shockwave(Core.groundCF(feet), { color = BRIGHT, from = 8, to = 1, duration = 0.4 })
		Core.burst(center, 40, { color = BRIGHT, texture = SPARK, speed = 26, light = 1 })
		Core.setTransparency(parts, 1)
		Core.cleanupLater(parts, 0.3)
	end)
end

-- Move3: untouchable shield. Returns a handle with :Hit() and :End().
function Time.Move3(ctx)
	local root = ctx.root
	if not root then
		return nil
	end
	local life = ctx.duration or 4

	local shield = Core.part(Enum.PartType.Ball, Vector3.one * 7, CFrame.new(root.Position), {
		color = CYAN, material = Enum.Material.ForceField, transparency = 0.6,
	})
	local rings = {}
	for i = 1, 3 do
		rings[i] = Core.part(Enum.PartType.Cylinder, Vector3.new(0.12, 8, 8), CFrame.new(root.Position), {
			color = BRIGHT, material = Enum.Material.Neon, transparency = 0.5,
		})
	end

	local flash = 0
	local finish = Core.runFor(life, function(dt, t)
		local p = root.Position
		shield.CFrame = CFrame.new(p)
		for i, r in ipairs(rings) do
			r.CFrame = CFrame.new(p) * CFrame.Angles(math.rad(30 * i), t * (1 + i * 0.6), 0) * CFrame.Angles(0, 0, math.rad(90))
		end
		if flash > 0 then
			flash = math.max(flash - dt * 4, 0)
			shield.Transparency = 0.6 - 0.4 * flash
		end
	end, function()
		shield.Transparency = 1
		for _, r in ipairs(rings) do
			r.Transparency = 1
		end
		Core.cleanupLater({ shield }, 0.2)
		Core.cleanupLater(rings, 0.2)
	end)

	return {
		Hit = function()
			flash = 1
			Core.shockwave(Core.groundCF(root.Position), { color = CYAN, from = 1, to = 8, duration = 0.4 })
		end,
		End = function()
			finish()
		end,
	}
end

-- Move4: virtual kill sequence
function Time.Move4(ctx)
	local tr = Core.root(ctx.targetCharacter)
	local center = tr and tr.Position or ctx.target
	local ground = center - Vector3.new(0, 2.8, 0)

	-- 1. four temporal rings close in on the target
	for i = 1, 4 do
		task.delay((i - 1) * 0.12, function()
			Core.shockwave(Core.groundCF(ground + Vector3.new(0, (i - 1) * 0.6, 0)), {
				color = i % 2 == 0 and BRIGHT or CYAN, from = 14, to = 2, duration = 1.0,
			})
		end)
	end

	Core.timeline(2.4, {
		{
			t = 1.0, -- 2. scene distortion around the target
			run = function()
				local bubble = Core.part(Enum.PartType.Ball, Vector3.one * 4, CFrame.new(center), {
					color = CYAN, material = Enum.Material.Glass, transparency = 0.6,
				})
				Core.runFor(0.5, function(_, t)
					local k = t / 0.5
					bubble.Size = Vector3.one * (4 + 2 * math.sin(k * math.pi))
					bubble.Transparency = 0.6 + 0.3 * k
				end, function()
					bubble:Destroy()
				end)
			end,
		},
		{
			t = 1.5, -- 3. concentrated blue release
			run = function()
				local core = Core.part(Enum.PartType.Ball, Vector3.one, CFrame.new(center), {
					color = BRIGHT, material = Enum.Material.Neon, transparency = 0,
				})
				Core.runFor(0.25, function(_, t)
					local k = t / 0.25
					core.Size = Vector3.one * (1 + 6 * Core.smooth(k))
					core.Transparency = k * 0.8
				end, function()
					core:Destroy()
				end)
				Core.tempBeam(center, center + Vector3.new(0, 40, 0), 0.5, {
					color = TIME, width0 = 3, width1 = 0.5, light = 1,
				})
				Core.shockwave(Core.groundCF(ground + Vector3.new(0, 0.2, 0)), { color = BRIGHT, from = 1, to = 14, duration = 0.4 })
				Core.burst(center, 50, { color = TIME, texture = SPARK, speed = 30, light = 1 })
			end,
		},
	})
end

return Time
