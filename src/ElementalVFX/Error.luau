-- Error.lua — Error element (secret)
--   M1    Glitched Dash: dash with a glitch trail, afterimages and digital fragments
--   Move1 Chaotic Destruction: glitched frame on the right hand, then a dash and shatter
--   Move2 404 Not Found: eyes glow, a compressed dark-purple projectile, fragmented impact
--   Move3 Got Glitched: caster breaks into fragments and goes hidden for ctx.duration (default 5).
--         Returns a handle: handle:End() restores the character early.
--         Invisibility and immunity are server-enforced. This only hides it on this client.
--   Move4 Spatial Distortion: bubble, glitch portal and a glitched arena for ctx.duration
--         (default 7). Returns a handle: handle:End() closes it early. ctx.arenaCFrame sets
--         where the arena visual appears (default: high above the map). The server moves
--         players and returns them, even if this is interrupted.
--   Move5 Unparalleled: outlines, orbiting fragments and a distortion disc on each target
--         for ctx.duration (default 5). ctx.targets is a list of models (or ctx.targetCharacter).
--         The server prevents movement.
--
--   Error.Meter(character, pct): shows the Error Meter above the character's head (0..1).
--         Glitch effects increase as it rises. Meter value and gains are server-owned.

local Core = require(script.Parent.Core)

local BLACK = Color3.fromRGB(15, 15, 20)
local PURPLE = Color3.fromRGB(60, 20, 90)
local BLUE = Color3.fromRGB(40, 90, 255)
local GLITCH = Core.seq({ PURPLE, BLUE })
local SPARK = Core.Textures.Sparkle

local Error = {}

-- Dash with a glitch trail: ghosts with distorted outlines and digital fragments
local function glitchDash(from, dir, dist, dur)
	local rng = Random.new()
	local lastGhost = 0
	Core.runFor(dur, function(_, t)
		local pos = from + dir * (dist * (t / dur))
		if t - lastGhost >= 0.04 then
			lastGhost = t
			local g = Core.ghost(Core.lookCF(pos, dir), Vector3.new(2, 5, 1), PURPLE, 0.35)
			local outline = Instance.new("SelectionBox")
			outline.Adornee = g
			outline.Color3 = BLUE
			outline.LineThickness = 0.03
			outline.Transparency = 0.2
			outline.Parent = Core.Folder
			task.delay(0.35, function()
				outline:Destroy()
			end)
		end
		if rng:NextNumber() < 0.35 then
			Core.fragments(pos + Vector3.new(0, rng:NextNumber(-1, 2), 0), 2, {
				color = BLUE, material = Enum.Material.Neon, minSize = 0.2, maxSize = 0.4,
				speed = 6, life = 0.4, gravity = 5,
			})
		end
	end, function()
		Core.burst(from + dir * dist, 12, { color = GLITCH, texture = SPARK, speed = 12, light = 1, life = 0.3 })
	end)
end

-- Four-bar frame on a plane facing dir. Returns the parts.
local function buildFrame(pos, dir, W, H)
	local F = Core.lookCF(pos, dir)
	local parts = {}
	table.insert(parts, Core.part(Enum.PartType.Block, Vector3.new(W, H, 0.1), F, {
		color = PURPLE, material = Enum.Material.Glass, transparency = 0.7,
	}))
	local bars = {
		{ size = Vector3.new(W, 0.15, 0.15), off = Vector3.new(0, H / 2, 0) },
		{ size = Vector3.new(W, 0.15, 0.15), off = Vector3.new(0, -H / 2, 0) },
		{ size = Vector3.new(0.15, H, 0.15), off = Vector3.new(W / 2, 0, 0) },
		{ size = Vector3.new(0.15, H, 0.15), off = Vector3.new(-W / 2, 0, 0) },
	}
	for _, b in ipairs(bars) do
		table.insert(parts, Core.part(Enum.PartType.Block, b.size, F * CFrame.new(b.off), {
			color = BLUE, material = Enum.Material.Neon, transparency = 0.1,
		}))
	end
	return parts
end

-- M1: glitched dash
function Error.M1(ctx)
	glitchDash(ctx.origin, ctx.direction, ctx.dashDistance or 18, 0.3)
end

-- Move1: glitched frame appears around the right hand, then the dash and shatter
function Error.Move1(ctx)
	local hand = Core.getPart(ctx.character, { "RightHand", "Right Arm" })
	local dir = ctx.direction
	local dist = ctx.dashDistance or 22
	local frame = buildFrame(hand and hand.Position or ctx.origin, dir, 3, 4)
	Core.flicker(frame, 0.35, 0.4)

	Core.runFor(0.35, nil, function()
		Core.destroyAll(frame)
		glitchDash(ctx.origin, dir, dist, 0.35)
		task.delay(0.35, function()
			local e = ctx.origin + dir * dist
			Core.animeSpikeBurst(e, {
				color = PURPLE, coreColor = BLUE, outlineColor = BLACK,
				count = 9, radius = 7, minHeight = 7, maxHeight = 15, duration = 0.55,
			})
			Core.fragments(e, 16, { color = BLUE, material = Enum.Material.Neon, speed = 28, life = 0.7, minSize = 0.3, maxSize = 0.9 })
			Core.fragments(e, 10, { color = PURPLE, material = Enum.Material.Neon, speed = 22, life = 0.7 })
			Core.shockwave(Core.axisCF(e, dir), { color = BLUE, from = 1, to = 10, duration = 0.4 })
		end)
	end)
end

-- Move2: 404 Not Found projectile
function Error.Move2(ctx)
	local character = ctx.character
	local head = character:FindFirstChild("Head")
	local lh = Core.getPart(character, { "LeftHand", "Left Arm" })
	local rh = Core.getPart(character, { "RightHand", "Right Arm" })

	-- 1. eyes glow for a moment, following the head
	local eyes = {}
	for i = 1, 2 do
		local eye = Core.part(Enum.PartType.Ball, Vector3.one * 0.35, CFrame.new(ctx.origin), {
			color = BLUE, material = Enum.Material.Neon, transparency = 0,
		})
		local light = Instance.new("PointLight")
		light.Color = BLUE
		light.Range = 6
		light.Brightness = 1.5
		light.Parent = eye
		table.insert(eyes, eye)
	end
	Core.runFor(0.6, function()
		if head and head.Parent then
			local cf = head.CFrame
			eyes[1].CFrame = cf * CFrame.new(-0.4, 0.1, -0.5)
			eyes[2].CFrame = cf * CFrame.new(0.4, 0.1, -0.5)
		end
	end, function()
		Core.cleanupLater(eyes, 0.2)
	end)

	-- 2. glitch energy between the hands compresses into a projectile
	local mid = ((lh and lh.Position or ctx.origin) + (rh and rh.Position or ctx.origin)) / 2
	local orb = Core.part(Enum.PartType.Ball, Vector3.one * 3, CFrame.new(mid), {
		color = PURPLE, material = Enum.Material.Neon, transparency = 0.1,
	})
	Core.flicker({ orb }, 0.6, 0.5)

	Core.runFor(0.6, function(_, t)
		orb.Size = Vector3.one * (3 - 1.8 * Core.smooth(t / 0.6))
	end, function()
		-- 3. fly to the target
		local target = ctx.target
		local flight = math.clamp((target - mid).Magnitude / 50, 0.2, 1.2)
		Core.runFor(flight, function(_, t)
			orb.CFrame = CFrame.new(mid:Lerp(target, t / flight))
			-- 4. impact: anime glitch spike burst, fragments, AoE ring, dark shell expanding out
			orb.Transparency = 1
			Core.animeSpikeBurst(target, {
				color = PURPLE, coreColor = BLUE, outlineColor = BLACK,
				count = 11, radius = 9, minHeight = 9, maxHeight = 18, duration = 0.65,
			})
			Core.fragments(target, 22, { color = PURPLE, material = Enum.Material.Neon, speed = 30, life = 0.8, minSize = 0.3, maxSize = 1.1 })
			Core.fragments(target, 14, { color = BLUE, material = Enum.Material.Neon, speed = 24, life = 0.7 })
			local R = ctx.radius or 14
			Core.shockwave(Core.groundCF(target - Vector3.new(0, 2.5, 0)), { color = BLUE, from = 2, to = R * 2, duration = 0.5 })
			local shell = Core.part(Enum.PartType.Ball, Vector3.one, CFrame.new(target), {
				color = BLACK, material = Enum.Material.Glass, transparency = 0.5,
			})
			Core.runFor(0.45, function(_, t)
				local k = t / 0.45
				shell.Size = Vector3.one * (2 + (R * 2 - 2) * Core.smooth(k))
				shell.Transparency = 0.5 + 0.5 * k
			end, function()
				shell:Destroy()
			end)
			Core.cleanupLater({ orb }, 0.5)
		end)
	end)
end

-- Move3: got glitched (hidden + fragments). Returns a handle with :End().
function Error.Move3(ctx)
	local root = ctx.root
	if not root then
		return nil
	end
	local life = ctx.duration or 5
	local fpos = root.Position - Vector3.new(0, 2.8, 0)

	-- break into fragments
	local hidden = {}
	for _, d in ipairs(ctx.character:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(hidden, d)
			Core.fragments(d.Position, 1, {
				color = d.Name == "Head" and BLUE or PURPLE,
				material = Enum.Material.Neon, speed = 14, life = 0.8, minSize = 0.2, maxSize = 0.6,
			})
		end
	end
	for _, p in ipairs(hidden) do
		p.LocalTransparencyModifier = 1
	end

	-- a spatial distortion remains where the caster vanished
	local field = Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, 6, 6), Core.groundCF(fpos), {
		color = PURPLE, material = Enum.Material.Neon, transparency = 0.5,
	})

	local lastRing = 0
	local function restore()
		for _, p in ipairs(hidden) do
			if p.Parent then
				p.LocalTransparencyModifier = 0
			end
		end
		field.Transparency = 1
		Core.cleanupLater({ field }, 0.4)
	end

	local finish = Core.runFor(life, function(_, t)
		if t - lastRing >= 0.8 then
			lastRing = t
			Core.shockwave(Core.groundCF(fpos), { color = BLUE, from = 1, to = 7, duration = 0.6 })
		end
	end, restore)

	return {
		End = function()
			finish()
		end,
	}
end

-- Move4: colossal spatial distortion glitched domain (80 studs radius). Returns a handle with :End().
function Error.Move4(ctx)
	local life = ctx.duration or 7
	local origin = ctx.origin
	local dir = ctx.direction
	local R = ctx.radius or 80
	local center = ctx.target or (origin - Vector3.new(0, 3, 0))

	-- 1. distortion bubble expands around the caster, fragments fly out
	local bubble = Core.part(Enum.PartType.Ball, Vector3.one * 4, CFrame.new(origin), {
		color = PURPLE, material = Enum.Material.Glass, transparency = 0.4,
	})
	Core.fragments(origin, 30, { color = BLUE, material = Enum.Material.Neon, speed = 36, life = 1.0 })
	Core.runFor(1.2, function(_, t)
		if t < 0.6 then
			bubble.Size = Vector3.one * (4 + (R * 1.5) * Core.smooth(t / 0.6))
		else
			bubble.Transparency = 0.4 + 0.6 * ((t - 0.6) / 0.6)
		end
		bubble.CFrame = CFrame.new(origin)
	end, function()
		bubble:Destroy()
	end)

	-- 2. glitch portal in front of the caster, flickering
	local portal = buildFrame(origin + dir * 6, dir, 8, 12)
	local portalFlicker = Core.flicker(portal, life, 0.25)

	-- 3. Colossal Grounded Anime Domain (80 studs radius)
	Core.animeDomain(center, {
		radius = R,
		height = 50,
		duration = life,
		fadeOut = 1.0,
		color = PURPLE,
		accentColor = BLUE,
		coreColor = Color3.fromRGB(0, 255, 255),
		pillarCount = 32,
		pillarHeight = 40,
	})

	-- 4. Cybernetic grid floor lines across the entire 160-stud arena
	local gridParts = {}
	local step = 16
	for i = -4, 4 do
		local off = i * step
		table.insert(gridParts, Core.part(Enum.PartType.Block, Vector3.new(R * 2, 0.15, 0.4),
			CFrame.new(center + Vector3.new(0, 0.2, off)), { color = BLUE, material = Enum.Material.Neon, transparency = 0.3 }))
		table.insert(gridParts, Core.part(Enum.PartType.Block, Vector3.new(0.4, 0.15, R * 2),
			CFrame.new(center + Vector3.new(off, 0.2, 0)), { color = BLUE, material = Enum.Material.Neon, transparency = 0.3 }))
	end
	local gridFlicker = Core.flicker(gridParts, life, 0.3)

	local finish = Core.runFor(life, function(_, t)
		if t > life - 0.8 then
			local k = (t - (life - 0.8)) / 0.8
			Core.setTransparency(gridParts, 0.3 + 0.7 * k)
			Core.setTransparency(portal, 0.1 + 0.9 * k)
		end
	end, function()
		portalFlicker()
		gridFlicker()
		Core.destroyAll(portal)
		Core.destroyAll(gridParts)
	end)

	return {
		End = function()
			finish()
		end,
	}
end

-- Move5: unparalleled. Outlines, orbiting fragments and a distortion disc on each target.
function Error.Move5(ctx)
	local life = ctx.duration or 5
	local targets = ctx.targets or { ctx.targetCharacter }
	local rng = Random.new()

	local parts, boxes, orbiters = {}, {}, {}
	for _, model in ipairs(targets) do
		local root = Core.root(model)
		if root then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = root
			box.Size = model:GetExtentsSize() + Vector3.new(0.6, 0.6, 0.6)
			box.Color3 = PURPLE
			box.Transparency = 0.6
			box.ZIndex = 1
			box.Parent = Core.Folder
			table.insert(boxes, box)

			for i = 1, 6 do
				local f = Core.part(Enum.PartType.Block, Vector3.one * 0.45, CFrame.new(root.Position), {
					color = BLUE, material = Enum.Material.Neon, transparency = 0.1,
				})
				table.insert(orbiters, { part = f, root = root, idx = i })
			end

			table.insert(parts, Core.part(Enum.PartType.Cylinder, Vector3.new(0.15, 6, 6), Core.groundCF(root.Position - Vector3.new(0, 2.8, 0)), {
				color = PURPLE, material = Enum.Material.Neon, transparency = 0.6,
			}))

			Core.fragments(root.Position, 8, { color = BLUE, material = Enum.Material.Neon, speed = 12, life = 0.6 })
		end
	end

	local spin = 0
	Core.runFor(life, function(dt, t)
		spin += dt
		for _, o in ipairs(orbiters) do
			if o.root.Parent then
				local a = spin * 4 + o.idx * (math.pi * 2 / 6)
				o.part.CFrame = CFrame.new(o.root.Position + Vector3.new(math.cos(a) * 3.2, math.sin(a * 2) * 1.2, math.sin(a) * 3.2))
			end
		end
		-- glitch: occasionally jump the outline transparency
		if rng:NextNumber() < 0.2 then
			for _, b in ipairs(boxes) do
				b.Transparency = rng:NextNumber(0.3, 0.8)
			end
		end
	end, function()
		for _, o in ipairs(orbiters) do
			o.part:Destroy()
		end
		Core.destroyAll(parts)
		Core.destroyAll(boxes)
	end)
end

-- Error Meter: a small bar above the character's head. pct is 0..1.
-- Call whenever the meter changes. Glitch effects grow as it rises.
local meters = {}

function Error.Meter(character, pct)
	pct = math.clamp(pct or 0, 0, 1)
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end

	local m = meters[character]
	if not m then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(140, 16)
		gui.StudsOffset = Vector3.new(0, 3.2, 0)
		gui.AlwaysOnTop = true
		gui.Adornee = head
		gui.Parent = head

		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = BLACK
		bg.BorderSizePixel = 0
		bg.Parent = gui

		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = BLUE
		fill.BorderSizePixel = 0
		fill.Parent = bg

		m = { gui = gui, fill = fill }
		meters[character] = m
		character.Destroying:Connect(function()
			meters[character] = nil
		end)
	end

	m.fill.Size = UDim2.fromScale(pct, 1)
	m.fill.BackgroundColor3 = PURPLE:Lerp(BLUE, pct)
	if pct >= 0.5 then
		local jitter = (pct - 0.5) * 2
		m.fill.Position = UDim2.fromScale(math.random() * jitter * 0.02 - jitter * 0.01, 0)
		if math.random() < pct * 0.4 then
			Core.fragments(head.Position + Vector3.new(0, 2.5, 0), 2, {
				color = BLUE, material = Enum.Material.Neon, speed = 6, life = 0.5, minSize = 0.2, maxSize = 0.4,
			})
		end
	else
		m.fill.Position = UDim2.fromScale(0, 0)
	end
end

return Error
