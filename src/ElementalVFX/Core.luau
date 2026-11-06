-- Core.lua
-- Shared helpers for every Elemental Worlds VFX.
-- Client-side visuals only (use from a LocalScript).
-- Damage, collision, movement and cooldowns belong to the server.

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Core = {}

Core.Textures = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	AnimeSlash = "rbxassetid://15788309933",
	AnimeSlashArc = "rbxassetid://13876022839",
	AnimeSmoke = "rbxassetid://15350639550",
	WaterDroplet = "rbxassetid://8030760338",
	SpeedLines = "rbxassetid://15292043166",
	RockDebris = "rbxassetid://149185730",
	ClockDial = "rbxassetid://1084991219",
	TorusMesh = "rbxassetid://3270017",
	RockMesh = "rbxassetid://1290033",
}

Core.FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})

local folder = workspace:FindFirstChild("ElementalVFX")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "ElementalVFX"
	folder.Parent = workspace
end
Core.Folder = folder

---------------------------------------------------------------------------
-- Colour and math
---------------------------------------------------------------------------

-- A Color3, a ColorSequence, or a list of Color3s spread evenly into a gradient
function Core.seq(colors)
	if typeof(colors) == "ColorSequence" then
		return colors
	end
	if typeof(colors) == "Color3" then
		return ColorSequence.new(colors)
	end
	if typeof(colors) == "table" then
		if #colors == 0 then
			return ColorSequence.new(Color3.new(1, 1, 1))
		elseif #colors == 1 then
			return ColorSequence.new(colors[1])
		end
		local keys = {}
		for i, c in ipairs(colors) do
			table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
		end
		return ColorSequence.new(keys)
	end
	return ColorSequence.new(Color3.new(1, 1, 1))
end

function Core.smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Points on a flat circle around center
function Core.circle(center, radius, n, y)
	local pts = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2
		table.insert(pts, center + Vector3.new(math.cos(a) * radius, y or 0, math.sin(a) * radius))
	end
	return pts
end

---------------------------------------------------------------------------
-- Orientation. A Cylinder's axis is its X. A Block's length is its Z.
---------------------------------------------------------------------------

-- Cylinder lying flat on the ground at pos
function Core.groundCF(pos)
	return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
end

-- Block whose length (Z) points along dir
function Core.lookCF(pos, dir)
	return CFrame.lookAt(pos, pos + dir)
end

-- Cylinder whose axis (X) points along dir
function Core.axisCF(pos, dir)
	return CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0)
end

---------------------------------------------------------------------------
-- Timing
---------------------------------------------------------------------------

-- Calls step(dt, elapsed) every frame for `duration` seconds, then onDone().
-- Returns a function that ends it early (onDone still runs, once).
function Core.runFor(duration, step, onDone)
	local elapsed, done = 0, false
	local conn
	local function finish()
		if done then
			return
		end
		done = true
		if conn then
			conn:Disconnect()
		end
		if onDone then
			onDone()
		end
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if done then
			return
		end
		elapsed = math.min(elapsed + dt, duration)
		if step then
			step(dt, elapsed)
		end
		if elapsed >= duration then
			finish()
		end
	end)
	return finish
end

-- Runs events[i].run(elapsed) once each, at events[i].t seconds
function Core.timeline(duration, events, onDone)
	table.sort(events, function(a, b)
		return a.t < b.t
	end)
	local i = 1
	return Core.runFor(duration, function(_, t)
		while events[i] and t >= events[i].t do
			events[i].run(t)
			i += 1
		end
	end, onDone)
end

---------------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------------

function Core.destroyAll(list)
	for _, x in ipairs(list) do
		x:Destroy()
	end
end

function Core.cleanupLater(list, seconds)
	for _, x in ipairs(list) do
		Debris:AddItem(x, seconds)
	end
end

-- Sets Transparency on Parts and NumberSequence on Beams
function Core.setTransparency(list, v)
	for _, x in ipairs(list) do
		if x:IsA("BasePart") then
			x.Transparency = v
		elseif x:IsA("Beam") then
			x.Transparency = NumberSequence.new(v)
		end
	end
end

---------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------

-- Anchored, non-colliding, see-through part.
-- o: color, material, transparency, collide, reflectance, parent
function Core.part(shape, size, cf, o)
	o = o or {}
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = o.collide == true
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = o.material or Enum.Material.Glass
	p.Color = o.color or Color3.new(1, 1, 1)
	p.Transparency = o.transparency or 0.4
	p.Reflectance = o.reflectance or 0
	p.Parent = o.parent or folder
	return p
end

-- Invisible anchor point, used for emitters, beams and trails
function Core.anchor(pos)
	return Core.part(Enum.PartType.Ball, Vector3.one * 0.2, CFrame.new(pos), { transparency = 1 })
end

function Core.attach(part, offset)
	local a = Instance.new("Attachment")
	a.Position = offset or Vector3.zero
	a.Parent = part
	return a
end

-- Particle emitter. Rate 0 means it only fires when :Emit() is called.
-- o: texture, color, light, transparency, size, lifetime, speed, spread, direction,
--    acceleration, drag, rate, squash, enabled
function Core.emitter(parent, o)
	o = o or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.texture or Core.Textures.Sparkle
	e.Color = Core.seq(o.color or Color3.new(1, 1, 1))
	e.LightEmission = o.light or 0.6
	e.Transparency = if typeof(o.transparency) == "NumberSequence" then o.transparency elseif typeof(o.transparency) == "number" then NumberSequence.new(o.transparency) else Core.FADE
	e.Size = if typeof(o.size) == "NumberSequence" then o.size elseif typeof(o.size) == "number" then NumberSequence.new(o.size) else NumberSequence.new(0.5, 0.1)
	e.Lifetime = o.lifetime or NumberRange.new(0.4, 0.7)
	e.Speed = o.speed or NumberRange.new(2, 5)
	e.SpreadAngle = o.spread or Vector2.new(180, 180)
	e.EmissionDirection = o.direction or Enum.NormalId.Top
	e.Acceleration = o.acceleration or Vector3.zero
	e.Drag = o.drag or 0
	e.Rate = o.rate or 0
	if o.squash then
		e.Squash = o.squash
	end
	if o.enabled == false then
		e.Enabled = false
	end
	e.Parent = parent
	return e
end

-- One-shot splash of droplets. o.aim points it toward a position.
function Core.burst(pos, count, o)
	o = o or {}
	local a = Core.anchor(pos)
	if o.aim then
		a.CFrame = CFrame.lookAt(pos, o.aim)
	end
	local s = o.speed or 20
	local life = o.life or 0.35
	local e = Core.emitter(Core.attach(a), {
		texture = o.texture,
		color = o.color,
		light = o.light or 0.8,
		lifetime = NumberRange.new(life, life * 1.7),
		speed = NumberRange.new(s, s * 1.8),
		spread = o.aim and Vector2.new(25, 25) or Vector2.new(180, 180),
		direction = o.aim and Enum.NormalId.Front or Enum.NormalId.Top,
		size = o.size or NumberSequence.new(0.6, 0.05),
		drag = o.drag or 2,
	})
	e:Emit(count)
	Core.cleanupLater({ a }, 2)
end

-- Ribbon trail between two attachments (put them side by side, across the motion)
function Core.trail(part, a0, a1, o)
	o = o or {}
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = o.lifetime or 0.3
	t.Color = Core.seq(o.color or Color3.new(1, 1, 1))
	t.Transparency = if typeof(o.transparency) == "NumberSequence" then o.transparency elseif typeof(o.transparency) == "number" then NumberSequence.new(o.transparency) else Core.FADE
	t.LightEmission = o.light or 0.5
	t.FaceCamera = true
	t.Parent = part
	return t
end

-- Glowing beam between two attachments
-- o: color, transparency, width0, width1, light, segments, curve
function Core.beam(a0, a1, o)
	o = o or {}
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = Core.seq(o.color or Color3.new(1, 1, 1))
	b.Transparency = if typeof(o.transparency) == "NumberSequence" then o.transparency elseif typeof(o.transparency) == "number" then NumberSequence.new(o.transparency) else NumberSequence.new(0.1)
	b.Width0 = o.width0 or 1
	b.Width1 = o.width1 or o.width0 or 1
	b.LightEmission = o.light or 0.7
	b.FaceCamera = true
	b.Segments = o.segments or 10
	b.CurveSize0 = o.curve or 0
	b.CurveSize1 = o.curve or 0
	b.Parent = folder
	return b
end

-- Beam between two points that fades out and cleans itself up
function Core.tempBeam(p0, p1, life, o)
	local a, b = Core.anchor(p0), Core.anchor(p1)
	local beam = Core.beam(Core.attach(a), Core.attach(b), o)
	Core.runFor(life, function(_, t)
		beam.Transparency = NumberSequence.new(math.clamp(0.1 + 0.9 * (t / life), 0, 1))
	end, function()
		Core.destroyAll({ beam, a, b })
	end)
	return beam
end

-- Expanding ring. cf sets position and orientation (see groundCF / axisCF).
-- o: color, from, to (diameters), duration
function Core.shockwave(cf, o)
	o = o or {}
	local ring = Core.part(Enum.PartType.Cylinder, Vector3.new(0.2, 1, 1), cf, {
		color = o.color, material = Enum.Material.Neon, transparency = 0.2,
	})
	local mesh = nil
	if o.useMesh ~= false then
		mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = Core.Textures.TorusMesh
		mesh.Parent = ring
	end
	local from, to = o.from or 1, o.to or 20
	local dur = o.duration or 0.6
	Core.runFor(dur, function(_, t)
		local k = t / dur
		local d = from + (to - from) * Core.smooth(k)
		ring.Size = Vector3.new(0.2, d, d)
		if mesh then
			mesh.Scale = Vector3.new(d * 0.5, d * 0.5, 0.2)
		end
		ring.Transparency = 0.2 + 0.8 * k
	end, function()
		ring:Destroy()
	end)
end

-- Sweeping Curved Anime Slash Ribbon Arc
function Core.animeSlashArc(p0, p1, color, coreColor, curve, width, life)
	local a0 = Core.anchor(p0)
	local a1 = Core.anchor(p1)
	local att0 = Core.attach(a0)
	local att1 = Core.attach(a1)

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Texture = Core.Textures.AnimeSlashArc
	beam.CurveSize0 = curve or 8
	beam.CurveSize1 = curve or 8
	beam.Width0 = width or 3
	beam.Width1 = (width or 3) * 0.15
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, coreColor or Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, color or Color3.fromRGB(255, 120, 20)),
		ColorSequenceKeypoint.new(1, color or Color3.fromRGB(255, 60, 0)),
	})
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Parent = folder

	Core.runFor(life or 0.4, function(_, t)
		local k = t / (life or 0.4)
		beam.Transparency = NumberSequence.new(math.clamp(0.05 + 0.95 * k, 0, 1))
	end, function()
		Core.destroyAll({ beam, a0, a1 })
	end)
end

-- 3-Layer Stylized Anime Spike Burst (matching reference: dark outline, vibrant body, neon core)
-- o: color, coreColor, outlineColor, count, radius, minHeight, maxHeight, duration, aimDir, slashArc, groundRing
function Core.animeSpikeBurst(pos, o)
	o = o or {}
	local color = o.color or Color3.fromRGB(255, 120, 20)
	local coreColor = o.coreColor or Color3.fromRGB(255, 255, 220)
	local outlineColor = o.outlineColor or Color3.fromRGB(18, 16, 22)
	local count = o.count or 8
	local radius = o.radius or 5
	local minH = o.minHeight or 7
	local maxH = o.maxHeight or 15
	local dur = o.duration or 0.55
	local aimDir = o.aimDir
	local rng = Random.new()

	local parts = {}
	local spikeData = {}

	-- Ground shockwave & crack ring
	if o.groundRing ~= false then
		Core.shockwave(Core.groundCF(pos + Vector3.new(0, 0.1, 0)), {
			color = color,
			from = 1,
			to = radius * 2.8,
			duration = dur * 0.7,
		})
	end

	-- Directional / fan angle calculations
	for i = 1, count do
		local angle
		if aimDir then
			local baseA = math.atan2(aimDir.X, aimDir.Z)
			angle = baseA + (i - (count + 1) * 0.5) * (math.rad(80) / count) + rng:NextNumber(-0.15, 0.15)
		else
			angle = (i - 1) * (math.pi * 2 / count) + rng:NextNumber(-0.2, 0.2)
		end

		local dist = rng:NextNumber(radius * 0.35, radius)
		local h = rng:NextNumber(minH, maxH)
		local w = rng:NextNumber(1.2, 2.4)
		local d = rng:NextNumber(1.8, 3.2)

		local spikePos = pos + Vector3.new(math.sin(angle) * dist, 0, math.cos(angle) * dist)
		local cf = CFrame.new(spikePos)
			* CFrame.Angles(0, angle + math.pi, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(-10, 15)), 0, math.rad(rng:NextNumber(8, 22)))

		-- 1. Dark silhouette outline (back/under)
		local outline = Instance.new("WedgePart")
		outline.Size = Vector3.new(w * 1.25, h * 1.05, d * 1.25)
		outline.CFrame = cf * CFrame.new(0, 0, -0.1)
		outline.Color = outlineColor
		outline.Material = Enum.Material.SmoothPlastic
		outline.Transparency = 0.05
		outline.Anchored = true
		outline.CanCollide = false
		outline.CanQuery = false
		outline.CanTouch = false
		outline.CastShadow = false
		outline.Parent = folder
		table.insert(parts, outline)

		-- 2. Vibrant elemental body
		local body = Instance.new("WedgePart")
		body.Size = Vector3.new(w, h, d)
		body.CFrame = cf
		body.Color = color
		body.Material = Enum.Material.Neon
		body.Transparency = 0.1
		body.Anchored = true
		body.CanCollide = false
		body.CanQuery = false
		body.CanTouch = false
		body.CastShadow = false
		body.Parent = folder
		table.insert(parts, body)

		-- 3. Neon white/hot core
		local inner = Instance.new("WedgePart")
		inner.Size = Vector3.new(w * 0.55, h * 0.85, d * 0.55)
		inner.CFrame = cf * CFrame.new(0, 0, 0.15)
		inner.Color = coreColor
		inner.Material = Enum.Material.Neon
		inner.Transparency = 0.05
		inner.Anchored = true
		inner.CanCollide = false
		inner.CanQuery = false
		inner.CanTouch = false
		inner.CastShadow = false
		inner.Parent = folder
		table.insert(parts, inner)

		table.insert(spikeData, {
			outline = outline,
			body = body,
			inner = inner,
			cf = cf,
			targetSize = Vector3.new(w, h, d),
		})
	end

	-- Curved Anime Slash Arc sweeping across the spike tips
	if o.slashArc ~= false then
		local p0 = pos + Vector3.new(rng:NextNumber(-radius, -radius * 0.4), rng:NextNumber(2, 4), rng:NextNumber(-radius, radius))
		local p1 = pos + Vector3.new(rng:NextNumber(radius * 0.4, radius), rng:NextNumber(minH * 0.6, maxH * 0.9), rng:NextNumber(-radius, radius))
		Core.animeSlashArc(p0, p1, color, coreColor, rng:NextNumber(6, 12), rng:NextNumber(2.5, 4.5), dur * 0.8)
	end

	-- High speed spark burst
	Core.burst(pos + Vector3.new(0, 1, 0), o.sparkCount or 16, {
		texture = Core.Textures.Sparkle,
		color = Core.seq({ coreColor, color }),
		speed = 24,
		life = 0.45,
		light = 1,
	})

	-- Animate: Fast erupt (0 -> 0.12s), hold (0.12 -> 0.35s), smooth dissolve (0.35 -> dur)
	Core.runFor(dur, function(_, t)
		if t <= 0.12 then
			local grow = Core.smooth(t / 0.12)
			for _, s in ipairs(spikeData) do
				local sz = s.targetSize * Vector3.new(1, grow, 1)
				s.body.Size = sz
				s.outline.Size = sz * Vector3.new(1.25, 1.05, 1.25)
				s.inner.Size = sz * Vector3.new(0.55, 0.85, 0.55)
			end
		elseif t >= dur * 0.65 then
			local fade = (t - dur * 0.65) / (dur * 0.35)
			local shrink = 1 - fade * 0.4
			for _, s in ipairs(spikeData) do
				local sz = s.targetSize * Vector3.new(shrink, shrink, shrink)
				s.body.Size = sz
				s.outline.Size = sz * Vector3.new(1.25, 1.05, 1.25)
				s.inner.Size = sz * Vector3.new(0.55, 0.85, 0.55)
				s.body.Transparency = 0.1 + 0.9 * fade
				s.outline.Transparency = 0.05 + 0.95 * fade
				s.inner.Transparency = 0.05 + 0.95 * fade
			end
		end
	end, function()
		Core.destroyAll(parts)
	end)
end

-- Colossal Anime Domain Expansion Builder (Huge radius 60-80 studs, towering boundary)
-- o: radius, height, duration, fadeOut, color, accentColor, coreColor, pillarCount, pillarHeight
function Core.animeDomain(center, o)
	o = o or {}
	local R = o.radius or 75
	local H = o.height or 45
	local life = o.duration or 10
	local fadeOut = o.fadeOut or 1.2
	local color = o.color or Color3.fromRGB(255, 100, 20)
	local accent = o.accentColor or Color3.fromRGB(255, 200, 50)
	local coreCol = o.coreColor or Color3.fromRGB(255, 255, 220)
	local N = o.pillarCount or 32
	local pH = o.pillarHeight or 35

	local visible = {}
	local emitters = {}
	local junk = {}

	-- 1. Initial Domain Expansion Blast: Massive double shockwave
	Core.shockwave(Core.groundCF(center + Vector3.new(0, 0.2, 0)), {
		color = color,
		from = 2,
		to = R * 2.2,
		duration = 0.8,
	})
	Core.shockwave(Core.groundCF(center + Vector3.new(0, 0.4, 0)), {
		color = accent,
		from = 1,
		to = R * 1.6,
		duration = 0.6,
	})

	-- 2. Colossal Domain Floor Disc
	local floor = Core.part(Enum.PartType.Cylinder, Vector3.new(0.25, R * 2, R * 2), Core.groundCF(center + Vector3.new(0, 0.05, 0)), {
		color = color, material = Enum.Material.Neon, transparency = 0.65,
	})
	table.insert(visible, floor)

	-- 3. Concentric Inner Rune Rings
	local innerRing = Core.part(Enum.PartType.Cylinder, Vector3.new(0.28, R * 1.2, R * 1.2), Core.groundCF(center + Vector3.new(0, 0.08, 0)), {
		color = accent, material = Enum.Material.Neon, transparency = 0.75,
	})
	table.insert(visible, innerRing)

	-- 4. Towering Perimeter Anime Pillars with glowing beams
	local tops = {}
	local pts = Core.circle(center, R, N, 2)
	for i, p in ipairs(pts) do
		local pillar = Core.part(Enum.PartType.Block, Vector3.new(1.2, pH, 1.2), CFrame.new(p + Vector3.new(0, pH * 0.5 - 2, 0)), {
			color = color, material = Enum.Material.Neon, transparency = 0.35,
		})
		table.insert(visible, pillar)
		tops[i] = Core.attach(pillar, Vector3.new(0, pH * 0.5, 0))

		local e = Core.emitter(tops[i], {
			texture = o.pillarTexture or Core.Textures.Fire,
			color = Core.seq({ accent, color }),
			rate = 20,
			light = 0.9,
			speed = NumberRange.new(8, 14),
			direction = Enum.NormalId.Top,
			spread = Vector2.new(12, 12),
			lifetime = NumberRange.new(0.8, 1.4),
			size = NumberSequence.new(1.8, 0.3),
		})
		table.insert(emitters, e)
	end

	for i = 1, N do
		local b = Core.beam(tops[i], tops[i % N + 1], {
			color = Core.seq({ accent, coreCol, accent }),
			width0 = 1.6,
			light = 1,
			curve = 0.5,
		})
		table.insert(visible, b)
	end

	-- 5. Translucent Outer Forcefield Shell
	local shell = Core.part(Enum.PartType.Cylinder, Vector3.new(H, R * 2, R * 2), Core.groundCF(center + Vector3.new(0, H * 0.5, 0)), {
		color = color, material = Enum.Material.ForceField, transparency = 0.82,
	})
	table.insert(visible, shell)

	-- 6. Floating Central Core / Sun
	local coreBall = Core.part(Enum.PartType.Ball, Vector3.one * 8, CFrame.new(center + Vector3.new(0, H * 0.65, 0)), {
		color = coreCol, material = Enum.Material.Neon, transparency = 0.15,
	})
	table.insert(visible, coreBall)

	local coreHalo = Core.part(Enum.PartType.Ball, Vector3.one * 12, CFrame.new(center + Vector3.new(0, H * 0.65, 0)), {
		color = accent, material = Enum.Material.Neon, transparency = 0.65,
	})
	table.insert(visible, coreHalo)

	local coreLight = Instance.new("PointLight")
	coreLight.Color = accent
	coreLight.Brightness = 6
	coreLight.Range = R * 1.2
	coreLight.Parent = coreBall
	table.insert(visible, coreLight)

	-- Periodic anime spike eruptions inside domain
	for i = 1, 6 do
		local a = (i - 1) * (math.pi * 2 / 6)
		local burstPos = center + Vector3.new(math.sin(a) * (R * 0.5), 0, math.cos(a) * (R * 0.5))
		task.delay(0.2 + i * 0.1, function()
			Core.animeSpikeBurst(burstPos, {
				color = color,
				coreColor = coreCol,
				count = 8,
				radius = 8,
				minHeight = 10,
				maxHeight = 20,
				duration = 1.2,
			})
		end)
	end

	local fadeStart = life - fadeOut
	Core.runFor(life, function(_, t)
		coreBall.Size = Vector3.one * (8 + math.sin(t * 5) * 1.2)
		coreHalo.Size = Vector3.one * (12 + math.sin(t * 3) * 2.0)
		if t >= fadeStart then
			local k = (t - fadeStart) / fadeOut
			Core.setTransparency(visible, 0.3 + 0.7 * k)
			for _, e in ipairs(emitters) do
				e.Enabled = false
			end
		end
	end, function()
		Core.destroyAll(visible)
		Core.destroyAll(junk)
	end)
end

-- Short fading afterimage block (or ball if shape is given)
function Core.ghost(cf, size, color, life, shape)
	life = life or 0.3
	local g = Core.part(shape or Enum.PartType.Block, size, cf, {
		color = color, material = Enum.Material.Neon, transparency = 0.5,
	})
	Core.runFor(life, function(_, t)
		g.Transparency = 0.5 + 0.5 * (t / life)
	end, function()
		g:Destroy()
	end)
	return g
end

-- Fading copy of a character's pose. o.at places it (default: where the character stands).
-- o: at, color, life
function Core.afterimage(character, o)
	o = o or {}
	if not character then
		return
	end
	local ok, clone = pcall(function()
		return character:Clone()
	end)
	if not ok or not clone then
		return
	end
	local life = o.life or 0.35
	local color = o.color or Color3.fromRGB(0, 200, 255)
	local parts = {}
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Material = Enum.Material.Neon
			d.Color = color
			d.Transparency = 0.5
			table.insert(parts, d)
		end
	end
	clone.Name = "Afterimage"
	if o.at then
		clone:PivotTo(o.at)
	end
	clone.Parent = folder
	Core.runFor(life, function(_, t)
		Core.setTransparency(parts, 0.5 + 0.5 * (t / life))
	end, function()
		clone:Destroy()
	end)
end

-- Chunks that fly out, fall and fade.
-- o: color, material, shape, speed, life, gravity, dirY (Vector2 range), minSize, maxSize
function Core.fragments(pos, count, o)
	o = o or {}
	local rng = Random.new()
	local speed = o.speed or 20
	local life = o.life or 0.8
	local gravity = o.gravity or 35
	local dirY = o.dirY or Vector2.new(0.2, 1)
	local list = {}
	for _ = 1, count do
		local s = rng:NextNumber(o.minSize or 0.3, o.maxSize or 0.8)
		local p = Core.part(o.shape or Enum.PartType.Block, Vector3.new(s, s * rng:NextNumber(0.5, 1), s), CFrame.new(pos), {
			color = o.color, material = o.material or Enum.Material.Rock, transparency = 0.1,
		})
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(dirY.X, dirY.Y), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.01 then
			dir = Vector3.yAxis
		end
		table.insert(list, {
			part = p,
			pos = pos,
			vel = dir.Unit * rng:NextNumber(speed * 0.5, speed),
			rot = CFrame.new(),
			spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)),
		})
	end
	Core.runFor(life, function(dt, t)
		for _, f in ipairs(list) do
			f.vel = f.vel - Vector3.new(0, gravity * dt, 0)
			f.pos = f.pos + f.vel * dt
			f.rot = f.rot * CFrame.Angles(f.spin.X * dt, f.spin.Y * dt, f.spin.Z * dt)
			f.part.CFrame = CFrame.new(f.pos) * f.rot
			f.part.Transparency = 0.1 + 0.9 * math.clamp((t - life * 0.6) / (life * 0.4), 0, 1)
		end
	end, function()
		for _, f in ipairs(list) do
			f.part:Destroy()
		end
	end)
end

-- Glowing particles that gather from a ring into a centre (charges, summons, pulls)
function Core.converge(center, radius, count, life, color)
	local rng = Random.new()
	local list = {}
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local start = center + Vector3.new(math.cos(a) * radius, rng:NextNumber(-1, 3), math.sin(a) * radius)
		local p = Core.part(Enum.PartType.Ball, Vector3.one * rng:NextNumber(0.2, 0.5), CFrame.new(start), {
			color = color, material = Enum.Material.Neon, transparency = 0.1,
		})
		table.insert(list, { part = p, from = start, delay = rng:NextNumber(0, life * 0.4) })
	end
	Core.runFor(life, function(_, t)
		for _, c in ipairs(list) do
			local k = math.clamp((t - c.delay) / (life - c.delay), 0, 1)
			c.part.CFrame = CFrame.new(c.from:Lerp(center, Core.smooth(k)))
		end
	end, function()
		for _, c in ipairs(list) do
			c.part:Destroy()
		end
	end)
end

-- Random glitch flicker on parts for `duration` seconds (Error element)
function Core.flicker(parts, duration, chance)
	local rng = Random.new()
	return Core.runFor(duration, function()
		for _, p in ipairs(parts) do
			if p.Parent and rng:NextNumber() < (chance or 0.25) then
				p.Transparency = rng:NextNumber(0, 0.85)
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Character helpers and move context
---------------------------------------------------------------------------

function Core.root(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

-- First of `names` that exists on the character, else its root
function Core.getPart(character, names)
	for _, n in ipairs(names) do
		local p = character and character:FindFirstChild(n)
		if p then
			return p
		end
	end
	return Core.root(character)
end

-- A point `dist` studs behind a model's root
function Core.behind(model, dist)
	local r = Core.root(model)
	if not r then
		return nil
	end
	return r.Position - r.CFrame.LookVector * (dist or 3)
end

-- Fills in defaults so every move can rely on them.
-- ctx fields: character, origin, direction, target, targetCharacter, targets,
--             duration, radius, and move-specific extras.
function Core.context(ctx)
	local root = Core.root(ctx.character)
	ctx.root = root
	ctx.origin = ctx.origin or (root and root.Position) or Vector3.zero
	local dir = ctx.direction or (root and root.CFrame.LookVector) or Vector3.new(0, 0, -1)
	ctx.direction = dir.Unit
	if not ctx.target then
		local tr = Core.root(ctx.targetCharacter)
		ctx.target = tr and tr.Position or (ctx.origin + ctx.direction * 30)
	end
	return ctx
end

return Core
