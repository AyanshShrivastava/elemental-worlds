--!strict
-- Core.luau
-- Pinnacle Elemental VFX Compositing Engine for Elemental Worlds.
-- Client-side visuals only. Multi-pass layering, sculpted 3D meshes,
-- negative light emission, VelocityPerpendicular/Parallel physics,
-- Grid8x8 animated flipbooks, and depth-sorted ZOffsets.

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Core = {}

Core.Sounds = {
	Punch = "rbxassetid://1720389178",
	HeavyHit = "rbxassetid://3041191430",
	SwordSlash = "rbxassetid://6760643020",
	Explosion = "rbxassetid://3802269741",
	FireBurst = "rbxassetid://5898090542",
	WaterSplash = "rbxassetid://5850414902",
	WaterGeyser = "rbxassetid://6543434968",
	RockSlam = "rbxassetid://3802269741",
	RockSlash = "rbxassetid://7863855238",
	LaserBeam = "rbxassetid://1839806527",
	LightFlash = "rbxassetid://3356359494",
	LightRay = "rbxassetid://1840218341",
	WindSlash = "rbxassetid://624706518",
	TornadoRoar = "rbxassetid://3484593077",
	GlitchHeavy = "rbxassetid://2767090000",
	GlitchBuzz = "rbxassetid://5599818817",
	TimeFreeze = "rbxassetid://4744477218",
	TimeShield = "rbxassetid://6148384813",
}

function Core.sound(pos: Vector3?, soundId: string, volume: number?, pitch: number?)
	if not soundId or soundId == "" then return end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 0.75
	s.PlaybackSpeed = (pitch or 1.0) * (0.95 + math.random() * 0.1)

	if pos then
		local soundPart = Instance.new("Part")
		soundPart.Name = "SFX_Spatial"
		soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		soundPart.CFrame = CFrame.new(pos)
		soundPart.Transparency = 1
		soundPart.CanCollide = false
		soundPart.CanTouch = false
		soundPart.CanQuery = false
		soundPart.Anchored = true
		soundPart.Parent = Core.Folder

		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 15
		s.RollOffMaxDistance = 160
		s.Parent = soundPart
		s:Play()

		s.Ended:Once(function()
			soundPart:Destroy()
		end)
		Debris:AddItem(soundPart, 5)
	else
		s.Parent = SoundService
		s:Play()
		s.Ended:Once(function()
			s:Destroy()
		end)
		Debris:AddItem(s, 5)
	end
end

---------------------------------------------------------------------------
-- Master Texture & Mesh Catalogs (Extracted from Workspace reference packs)
---------------------------------------------------------------------------

Core.Textures = {
	Sparkle = "rbxassetid://15401642957", -- Anime star glint
	Fire = "rbxassetid://12136774260", -- Grid8x8 64-frame animated fire
	Smoke = "rbxassetid://12141720576", -- Grid8x8 animated smoke
	AnimeSlash = "rbxassetid://15638729672", -- 0.05s instant anime cleave
	AnimeSlashArc = "rbxassetid://13876022839",
	AnimeSmoke = "rbxassetid://9171262291", -- Grid8x8 thick ground dust column
	WaterDroplet = "rbxassetid://8030760338",
	SpeedLines = "rbxassetid://15292043166",
	RockDebris = "rbxassetid://6760190948", -- High-fidelity tumbling rock shrapnel
	ClockDial = "rbxassetid://1084991219",
	TorusMesh = "rbxassetid://3270017",
	RockMesh = "rbxassetid://1290033",
}

-- Specialized Benchmark Assets
Core.PinnacleTextures = {
	FluidFire8x8 = "rbxassetid://12136774260", -- 64-frame fluid anime flame
	FluidSmoke8x8 = "rbxassetid://12141720576",
	Embers = "rbxassetid://6612338229",
	CleaveInstant = "rbxassetid://15638729672", -- 0.05s cleave cut
	CleaveShadow = "rbxassetid://15640022727",
	PopStar = "rbxassetid://15401642957",
	NegativeCrater = "rbxassetid://11396737930", -- LightEmission = -1.2, VelocityPerpendicular
	TumblingRock = "rbxassetid://6760190948",
	GroundFlash = "rbxassetid://15161996973",
	AxoieVoid100 = "rbxassetid://13327161584", -- LightEmission = -100 space absorption
	AxoieVoid30 = "rbxassetid://7216855914", -- LightEmission = -30 core
	LightningBolt8x8 = "rbxassetid://12390063093", -- 64-frame hand-drawn lightning
	LightningDischarge8x8 = "rbxassetid://12390113643",
	HelicalBeam = "rbxassetid://14816445799",
	LaserBeamWide = "rbxassetid://14050898403",
	WaterBeam15 = "rbxassetid://10820007429",
	SupernovaFlash = "rbxassetid://6673021984",
	SupernovaBeams = "rbxassetid://13622546112",
	ShockwaveDisc160 = "rbxassetid://15048784530",
	BlackFlash1 = "rbxassetid://114078620420379", -- LightEmission = -10
	BlackFlash2 = "rbxassetid://117629123154439",
	DivergentRing = "rbxassetid://15613847392", -- LightEmission = -20
	TornadoSlash = "rbxassetid://15637447149", -- RotSpeed -2000
	WindRingPerp = "rbxassetid://9281305957",
	CelestialRing = "rbxassetid://8099244106",
	GlassShatter = "http://www.roblox.com/asset/?id=281633012",
	MuzzleFlash = "rbxassetid://10382927269",
	MuzzleLines = "rbxassetid://10382942533",
	RapidSlashGrid = "rbxassetid://104922764134050",
	LimbFireAura = "rbxassetid://16676455805",
	LimbWaterAura = "rbxassetid://16664715772",
	DiamondSpark = "rbxassetid://15583586686",
}

-- Custom Sculpted 3D VFX Meshes (Extracted from Workspace.VFX)
Core.Meshes = {
	GroundSpikes = "rbxassetid://967645205",
	Bonk = "rbxassetid://4316118084",
	Smash10 = "rbxassetid://489415286",
	Smash8 = "rbxassetid://489415447",
	Smash6 = "rbxassetid://489415572",
	SlashEffect = "rbxassetid://4572036304", -- Curved 3D slash (21x0.9x7.7)
	SlashSkill1 = "rbxassetid://452960473",
	FancySphere = "rbxassetid://5703278366",
	FancySphereLight = "rbxassetid://5703288879",
	GravityShockwave = "rbxassetid://750305703",
	CircleShockwave = "rbxassetid://1474874211",
	DecalShockwave = "rbxassetid://2788580235",
	RoughShockwave = "rbxassetid://903888897",
	InwardShockwave = "rbxassetid://6220387416",
	SpinnyThings = "rbxassetid://6133078795",
	Tornado = "rbxassetid://5705014362",
	LightWind = "rbxassetid://4681227436",
	Vento2 = "rbxassetid://6063631009",
	Flash = "rbxassetid://2620058357",
	Star3D = "rbxassetid://4886514859",
	BeamCylinder = "rbxassetid://14254104486",
	WaveMesh = "rbxassetid://2689837482",
	WaveMeshLarge = "rbxassetid://5696416905",
	GlitchBall = "rbxassetid://6553021063",
	GlitchWind = "rbxassetid://6553151264",
	FireBall = "rbxassetid://6553027596",
	ExplosionCube = "rbxassetid://4933939180",
	ThunderSpark = "rbxassetid://6553130477",
	LeafMesh = "rbxassetid://5129539702",
	InvertedSpike = "rbxassetid://1826588507",
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
-- Colour, Math & Sequences
---------------------------------------------------------------------------

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

function Core.circle(center, radius, n, y)
	local pts = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2
		table.insert(pts, center + Vector3.new(math.cos(a) * radius, y or 0, math.sin(a) * radius))
	end
	return pts
end

---------------------------------------------------------------------------
-- Orientation Helpers
---------------------------------------------------------------------------

function Core.groundCF(pos)
	return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
end

function Core.lookCF(pos, dir)
	if dir.Magnitude < 0.001 then
		return CFrame.new(pos)
	end
	return CFrame.lookAt(pos, pos + dir)
end

function Core.axisCF(pos, dir)
	if dir.Magnitude < 0.001 then
		return CFrame.new(pos)
	end
	return CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0)
end

---------------------------------------------------------------------------
-- Timing & Cleanup
---------------------------------------------------------------------------

function Core.runFor(duration, step, onDone)
	local elapsed, done = 0, false
	local conn
	local function finish()
		if done then return end
		done = true
		if conn then conn:Disconnect() end
		if onDone then onDone() end
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if done then return end
		elapsed = math.min(elapsed + dt, duration)
		if step then step(dt, elapsed) end
		if elapsed >= duration then finish() end
	end)
	return finish
end

function Core.timeline(duration, events, onDone)
	table.sort(events, function(a, b) return a.t < b.t end)
	local i = 1
	return Core.runFor(duration, function(_, t)
		while events[i] and t >= events[i].t do
			events[i].run(t)
			i += 1
		end
	end, onDone)
end

function Core.destroyAll(list)
	for _, x in ipairs(list) do
		if typeof(x) == "Instance" and x.Parent then
			x:Destroy()
		end
	end
end

function Core.cleanupLater(list, seconds)
	for _, x in ipairs(list) do
		Debris:AddItem(x, seconds)
	end
end

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
-- Core Visual Instances
---------------------------------------------------------------------------

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

-- Custom Sculpted 3D VFX Mesh Spawner
function Core.meshPart(meshId, size, cf, o)
	o = o or {}
	local p = Instance.new("Part")
	p.Size = size or Vector3.new(2, 2, 2)
	p.CFrame = cf or CFrame.new()
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = o.material or Enum.Material.Neon
	p.Color = o.color or Color3.new(1, 1, 1)
	p.Transparency = o.transparency or 0.1
	p.Parent = o.parent or folder

	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.FileMesh
	m.MeshId = meshId
	m.Scale = o.scale or Vector3.new(1, 1, 1)
	m.Parent = p

	if o.spin then
		local spinSpeed = o.spin
		local baseCF = cf
		local start = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if not p.Parent then
				conn:Disconnect()
				return
			end
			local dt = os.clock() - start
			p.CFrame = baseCF * CFrame.Angles(spinSpeed.X * dt, spinSpeed.Y * dt, spinSpeed.Z * dt)
		end)
	end

	return p, m
end

function Core.anchor(pos)
	return Core.part(Enum.PartType.Ball, Vector3.one * 0.1, CFrame.new(pos), { transparency = 1 })
end

function Core.attach(part, offset)
	local a = Instance.new("Attachment")
	a.Position = offset or Vector3.zero
	a.Parent = part
	return a
end

function Core.emitter(parent, o)
	o = o or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.texture or Core.Textures.Sparkle
	e.Color = Core.seq(o.color or Color3.new(1, 1, 1))
	e.LightEmission = o.light ~= nil and o.light or 0.6
	e.Transparency = if typeof(o.transparency) == "NumberSequence" then o.transparency elseif typeof(o.transparency) == "number" then NumberSequence.new(o.transparency) else Core.FADE
	e.Size = if typeof(o.size) == "NumberSequence" then o.size elseif typeof(o.size) == "number" then NumberSequence.new(o.size) else NumberSequence.new(0.5, 0.1)
	e.Lifetime = o.lifetime or NumberRange.new(0.4, 0.7)
	e.Speed = o.speed or NumberRange.new(2, 5)
	e.SpreadAngle = o.spread or Vector2.new(180, 180)
	e.EmissionDirection = o.direction or Enum.NormalId.Top
	e.Acceleration = o.acceleration or Vector3.zero
	e.Drag = o.drag or 0
	e.Rate = o.rate or 0
	e.ZOffset = o.zOffset or 0
	e.RotSpeed = o.rotSpeed or NumberRange.new(0, 0)
	e.Orientation = o.orientation or Enum.ParticleOrientation.FacingCamera

	if o.flipbookLayout then
		e.FlipbookLayout = o.flipbookLayout
		e.FlipbookMode = o.flipbookMode or Enum.ParticleFlipbookMode.Loop
		e.FlipbookFramerate = o.flipbookFramerate or NumberRange.new(30, 30)
	end

	if o.squash then
		e.Squash = o.squash
	end
	if o.enabled == false then
		e.Enabled = false
	end
	e.Parent = parent
	return e
end

function Core.burst(pos, count, o)
	o = o or {}
	local a = Core.anchor(pos)
	if o.aim then
		a.CFrame = Core.lookCF(pos, o.aim - pos)
	end
	local s = o.speed or 20
	local life = o.life or 0.35
	local e = Core.emitter(Core.attach(a), {
		texture = o.texture,
		color = o.color,
		light = o.light or 0.8,
		lifetime = NumberRange.new(life, life * 1.5),
		speed = NumberRange.new(s * 0.7, s * 1.3),
		spread = o.aim and Vector2.new(25, 25) or Vector2.new(180, 180),
		direction = o.aim and Enum.NormalId.Front or Enum.NormalId.Top,
		size = o.size or NumberSequence.new(0.6, 0.05),
		drag = o.drag or 2,
		zOffset = o.zOffset or 8,
		orientation = o.orientation or Enum.ParticleOrientation.FacingCamera,
	})
	e:Emit(count)
	Core.cleanupLater({ a }, 2)
end

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

function Core.beam(a0, a1, o)
	o = o or {}
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Texture = o.texture or ""
	b.Color = Core.seq(o.color or Color3.new(1, 1, 1))
	b.Transparency = if typeof(o.transparency) == "NumberSequence" then o.transparency elseif typeof(o.transparency) == "number" then NumberSequence.new(o.transparency) else NumberSequence.new(0.1)
	b.Width0 = o.width0 or 1
	b.Width1 = o.width1 or o.width0 or 1
	b.LightEmission = o.light or 0.7
	b.FaceCamera = true
	b.Segments = o.segments or 14
	b.CurveSize0 = o.curve or o.curve0 or 0
	b.CurveSize1 = o.curve or o.curve1 or 0
	b.TextureSpeed = o.textureSpeed or 1
	b.TextureLength = o.textureLength or 1
	b.ZOffset = o.zOffset or 5
	b.Parent = folder
	return b
end

function Core.tempBeam(p0, p1, life, o)
	local a, b = Core.anchor(p0), Core.anchor(p1)
	local att0, att1 = Core.attach(a), Core.attach(b)
	local beam = Core.beam(att0, att1, o)
	Core.runFor(life, function(_, t)
		local k = t / life
		beam.Transparency = NumberSequence.new(math.clamp(0.05 + 0.95 * k, 0, 1))
	end, function()
		Core.destroyAll({ beam, a, b })
	end)
	return beam
end

function Core.shockwave(cf, o)
	o = o or {}
	local from, to = o.from or 1, o.to or 20
	local dur = o.duration or 0.6
	local ring = Core.part(Enum.PartType.Cylinder, Vector3.new(0.2, from, from), cf, {
		color = o.color or Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		transparency = 0.2,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = o.meshId or Core.Meshes.GravityShockwave
	mesh.Scale = Vector3.new(from * 0.2, from * 0.2, 0.2)
	mesh.Parent = ring

	Core.runFor(dur, function(_, t)
		local k = t / dur
		local d = from + (to - from) * Core.smooth(k)
		ring.Size = Vector3.new(0.2, d, d)
		mesh.Scale = Vector3.new(d * 0.2, d * 0.2, 0.2)
		ring.Transparency = 0.2 + 0.8 * k
	end, function()
		ring:Destroy()
	end)
end

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
	beam.ZOffset = 10
	beam.Parent = folder

	Core.runFor(life or 0.4, function(_, t)
		local k = t / (life or 0.4)
		beam.Transparency = NumberSequence.new(math.clamp(0.05 + 0.95 * k, 0, 1))
	end, function()
		Core.destroyAll({ beam, a0, a1 })
	end)
end

---------------------------------------------------------------------------
-- THE 8 PINNACLE COMPOSITING ENGINES (Top-Tier Benchmark implementations)
---------------------------------------------------------------------------

-- 1. Fluid Flipbook Flame Engine (Grid8x8 64 frames + embers + smoke column)
function Core.pinnacleFlame(parentPart, colorSeq, sizeMult, o)
	o = o or {}
	sizeMult = sizeMult or 1.0
	local att = parentPart:IsA("Attachment") and parentPart or Core.attach(parentPart)

	local fire = Core.emitter(att, {
		texture = Core.PinnacleTextures.FluidFire8x8,
		color = colorSeq,
		light = o.light or 0.85,
		rate = o.rate or 45,
		lifetime = NumberRange.new(0.4, 0.75),
		speed = NumberRange.new(2, 6),
		spread = Vector2.new(15, 15),
		direction = Enum.NormalId.Top,
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.2 * sizeMult),
			NumberSequenceKeypoint.new(0.5, 2.4 * sizeMult),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.Loop,
		flipbookFramerate = NumberRange.new(30, 30),
		zOffset = 12,
		orientation = Enum.ParticleOrientation.FacingCamera,
	})

	local embers = Core.emitter(att, {
		texture = Core.PinnacleTextures.Embers,
		color = colorSeq,
		light = 1,
		rate = 30,
		lifetime = NumberRange.new(0.5, 1.2),
		speed = NumberRange.new(6, 14),
		spread = Vector2.new(25, 25),
		direction = Enum.NormalId.Top,
		size = NumberSequence.new(0.35 * sizeMult, 0.05),
		zOffset = 9,
	})

	local smoke = Core.emitter(att, {
		texture = Core.PinnacleTextures.FluidSmoke8x8,
		color = ColorSequence.new(Color3.fromRGB(30, 30, 35)),
		light = 0,
		rate = 15,
		lifetime = NumberRange.new(0.8, 1.6),
		speed = NumberRange.new(3, 7),
		spread = Vector2.new(20, 20),
		direction = Enum.NormalId.Top,
		size = NumberSequence.new(1.8 * sizeMult, 4.0 * sizeMult),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.Loop,
		flipbookFramerate = NumberRange.new(20, 20),
		zOffset = 4,
	})

	return { Fire = fire, Embers = embers, Smoke = smoke }
end

-- 2. Micro-Cleave Instant Anime Slash (0.05s cut with squash + negative ink frame)
function Core.dismantleCleave(cf, colorSeq, size, o)
	o = o or {}
	size = size or 8
	local anchor = Core.anchor(cf.Position)
	anchor.CFrame = cf
	local att = Core.attach(anchor)

	-- Fast stretching squash curve for violent momentum
	local squashCurve = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 5.5),
		NumberSequenceKeypoint.new(0.8, 2.0),
		NumberSequenceKeypoint.new(1, 0),
	})

	-- Core High-Velocity Slash
	local cleave = Core.emitter(att, {
		texture = Core.PinnacleTextures.CleaveInstant,
		color = colorSeq,
		light = o.light or 0.8,
		lifetime = NumberRange.new(0.06, 0.12),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(size, size * 1.2),
		rate = 0,
		squash = squashCurve,
		orientation = Enum.ParticleOrientation.VelocityParallel,
		zOffset = 15,
	})

	-- Negative ink shadow frame (LightEmission = -10)
	local shadow = Core.emitter(att, {
		texture = Core.PinnacleTextures.CleaveShadow,
		color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		light = -10,
		lifetime = NumberRange.new(0.08, 0.14),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(size * 1.1, size * 1.3),
		rate = 0,
		squash = squashCurve,
		orientation = Enum.ParticleOrientation.VelocityParallel,
		zOffset = 14,
	})

	-- Pop star flash glint
	local pop = Core.emitter(att, {
		texture = Core.PinnacleTextures.PopStar,
		color = colorSeq,
		light = 1,
		lifetime = NumberRange.new(0.1, 0.2),
		speed = NumberRange.new(1, 4),
		size = NumberSequence.new(size * 0.4, 0),
		rate = 0,
		zOffset = 18,
	})

	cleave:Emit(o.cleaveCount or 3)
	shadow:Emit(o.shadowCount or 3)
	pop:Emit(4)

	Core.sound(cf.Position, o.soundId or Core.Sounds.SwordSlash, o.volume or 0.75, o.pitch or 1.15)
	Core.cleanupLater({ anchor }, 0.5)
end

-- 3. Heavy Seismic Ground Slam Crater Engine
function Core.groundSlamCrater(pos, colorSeq, radius, o)
	o = o or {}
	radius = radius or 12
	local anchor = Core.anchor(pos + Vector3.new(0, 0.05, 0))
	local att = Core.attach(anchor)

	-- Layer 0: Flat Ground Scorch Decal / Crater (VelocityPerpendicular, Light = -1.2, ZOffset = 0.001)
	local crater = Core.emitter(att, {
		texture = Core.PinnacleTextures.NegativeCrater,
		color = ColorSequence.new(Color3.fromRGB(20, 18, 16)),
		light = -1.2,
		rate = 0,
		lifetime = NumberRange.new(2.5, 3.5),
		speed = NumberRange.new(0.01, 0.05),
		size = NumberSequence.new(radius * 1.8, radius * 2.0),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 0.001,
	})

	-- Layer 1: Ground Flash
	local flash = Core.emitter(att, {
		texture = Core.PinnacleTextures.GroundFlash,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.15, 0.25),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(radius * 2.2, radius * 0.5),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 16,
	})

	-- Layer 2: Tumbling Shrapnel Rocks (700 deg/s with heavy gravity)
	local rocks = Core.emitter(att, {
		texture = Core.PinnacleTextures.TumblingRock,
		color = ColorSequence.new(Color3.fromRGB(110, 100, 90)),
		light = 0,
		rate = 0,
		lifetime = NumberRange.new(0.8, 1.4),
		speed = NumberRange.new(25, 45),
		spread = Vector2.new(45, 45),
		direction = Enum.NormalId.Top,
		acceleration = Vector3.new(0, -171.5, 0), -- Realistic Roblox gravity pull
		drag = 2.75,
		rotSpeed = NumberRange.new(-700, 700),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.7, 1.4),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		zOffset = 9,
	})

	-- Layer 3: Grid8x8 Smoke Geyser Column
	local smoke = Core.emitter(att, {
		texture = Core.Textures.AnimeSmoke,
		color = ColorSequence.new(Color3.fromRGB(140, 130, 120)),
		light = 0.1,
		rate = 0,
		lifetime = NumberRange.new(1.0, 1.8),
		speed = NumberRange.new(18, 32),
		spread = Vector2.new(20, 20),
		direction = Enum.NormalId.Top,
		drag = 3.0,
		size = NumberSequence.new(radius * 0.4, radius * 1.4),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.OneShot,
		flipbookFramerate = NumberRange.new(24, 24),
		zOffset = 4,
	})

	crater:Emit(1)
	flash:Emit(2)
	rocks:Emit(o.rockCount or 22)
	smoke:Emit(14)
	Core.sound(pos, o.soundId or Core.Sounds.Explosion, o.volume or 0.85, o.pitch or 0.95)

	-- 3D Sculpted Smash Mesh Impact (`10smash` or `bonk`)
	if o.useMesh ~= false then
		local smashPart, smashMesh = Core.meshPart(Core.Meshes.Smash10, Vector3.new(radius, 2, radius), CFrame.new(pos + Vector3.new(0, 0.2, 0)), {
			color = Color3.fromRGB(160, 150, 140),
			material = Enum.Material.Rock,
			transparency = 0.1,
		})
		Core.runFor(o.duration or 2.5, function(_, t)
			if t >= 1.5 then
				local k = (t - 1.5) / 1.0
				smashPart.Transparency = 0.1 + 0.9 * k
			end
		end, function()
			smashPart:Destroy()
		end)
	end

	Core.cleanupLater({ anchor }, 4)
end

-- 4. Negative Light Singularity Void Engine (LightEmission = -100 absorption)
function Core.negativeSingularity(pos, radius, o)
	o = o or {}
	radius = radius or 8
	local anchor = Core.anchor(pos)
	local att = Core.attach(anchor)
	Core.sound(pos, o.soundId or Core.Sounds.GlitchHeavy, o.volume or 0.9, o.pitch or 0.85)

	-- -100 Extreme Light Absorption (Tears a literal hole in Roblox viewport lighting)
	local void100 = Core.emitter(att, {
		texture = Core.PinnacleTextures.AxoieVoid100,
		color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		light = -100,
		rate = 30,
		lifetime = NumberRange.new(0.3, 0.5),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(radius * 1.8, radius * 0.2),
		rotSpeed = NumberRange.new(-300, 300),
		zOffset = 18,
	})

	-- -30 Intense Void Core
	local void30 = Core.emitter(att, {
		texture = Core.PinnacleTextures.AxoieVoid30,
		color = ColorSequence.new(Color3.fromRGB(15, 0, 30)),
		light = -30,
		rate = 25,
		lifetime = NumberRange.new(0.2, 0.4),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(radius * 1.2, radius * 0.1),
		rotSpeed = NumberRange.new(400, 600),
		zOffset = 19,
	})

	-- 3D Sculpted Gravity Ball Shockwave Mesh (inward spin)
	local gravPart, gravMesh = Core.meshPart(Core.Meshes.GravityShockwave, Vector3.new(radius, 0.5, radius), CFrame.new(pos), {
		color = Color3.fromRGB(30, 0, 60),
		material = Enum.Material.Neon,
		transparency = 0.3,
		spin = Vector3.new(0, 8, 0),
	})

	local life = o.duration or 3.0
	Core.runFor(life, function(_, t)
		local pulse = 1.0 + math.sin(t * 12) * 0.15
		gravPart.Size = Vector3.new(radius * pulse, 0.5, radius * pulse)
	end, function()
		void100.Enabled = false
		void30.Enabled = false
		gravPart:Destroy()
		Core.cleanupLater({ anchor }, 1)
	end)

	return { Anchor = anchor, Void100 = void100, Void30 = void30, MeshPart = gravPart }
end

-- 5. High-Voltage Hand-Drawn Animated Lightning (Grid8x8 64 frames)
function Core.animatedLightning(p0, p1, colorSeq, o)
	o = o or {}
	local dist = (p1 - p0).Magnitude
	local cf = Core.lookCF(p0, p1 - p0)
	local anchor = Core.anchor(p0)
	anchor.CFrame = cf
	local att = Core.attach(anchor)

	-- Grid8x8 Animated Bolt with Strobe Transparency
	local bolt = Core.emitter(att, {
		texture = Core.PinnacleTextures.LightningBolt8x8,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.15, 0.25),
		speed = NumberRange.new(dist * 3, dist * 4),
		spread = Vector2.new(4, 4),
		direction = Enum.NormalId.Front,
		size = NumberSequence.new(o.width or 2.5, (o.width or 2.5) * 0.4),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.OneShot,
		flipbookFramerate = NumberRange.new(30, 30),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(0.6, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		zOffset = 14,
	})

	-- Discharge Flash Sparks
	local discharge = Core.emitter(att, {
		texture = Core.PinnacleTextures.LightningDischarge8x8,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.1, 0.2),
		speed = NumberRange.new(10, 25),
		spread = Vector2.new(180, 180),
		size = NumberSequence.new(1.8, 0.2),
		flipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
		flipbookMode = Enum.ParticleFlipbookMode.OneShot,
		flipbookFramerate = NumberRange.new(30, 30),
		zOffset = 16,
	})

	bolt:Emit(o.boltCount or 3)
	discharge:Emit(o.dischargeCount or 8)
	Core.sound(p0, o.soundId or Core.Sounds.LaserBeam, o.volume or 0.75, o.pitch or 1.2)

	Core.cleanupLater({ anchor }, 0.6)
end

-- 6. Helical Multi-Beam Laser Cannon Engine (Cylinder mesh + 14 wrapped beams)
function Core.meshLaserCannon(p0, p1, colorSeq, o)
	o = o or {}
	local delta = p1 - p0
	local dist = delta.Magnitude
	local dir = delta.Unit
	local cf = Core.lookCF(p0 + dir * (dist * 0.5), dir)
	local width = o.width or 4.5
	local dur = o.duration or 0.6

	-- Central Core 3D Cylinder Mesh (`rbxassetid://14254104486`)
	local corePart, coreMesh = Core.meshPart(Core.Meshes.BeamCylinder, Vector3.new(width, width, dist), cf, {
		color = o.coreColor or Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		transparency = 0.1,
	})
	Core.sound(p0, o.soundId or Core.Sounds.LaserBeam, o.volume or 0.95, o.pitch or 1.0)

	-- 14 Helical Beams wrapped around the perimeter
	local beams = {}
	local anchors = {}
	local numHelical = o.numHelical or 8
	local radius = width * 0.75

	for i = 1, numHelical do
		local a = (i - 1) * (math.pi * 2 / numHelical)
		local offset0 = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		local offset1 = Vector3.new(math.cos(a + math.pi * 0.75) * radius, math.sin(a + math.pi * 0.75) * radius, 0)

		local a0 = Core.anchor(p0 + offset0)
		local a1 = Core.anchor(p1 + offset1)
		table.insert(anchors, a0)
		table.insert(anchors, a1)

		local b = Core.beam(Core.attach(a0), Core.attach(a1), {
			texture = Core.PinnacleTextures.HelicalBeam,
			color = colorSeq,
			width0 = width * 0.35,
			width1 = width * 0.65,
			curve0 = 5.6,
			curve1 = 5.6,
			light = 0.85,
			textureSpeed = 4,
			textureLength = 3,
			zOffset = 12,
		})
		table.insert(beams, b)
	end

	-- Concentric Muzzle Flash at origin
	local muzzlePart = Core.anchor(p0)
	local muzzleAtt = Core.attach(muzzlePart)
	local muzzleEmitter = Core.emitter(muzzleAtt, {
		texture = Core.PinnacleTextures.MuzzleFlash,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.15, 0.25),
		speed = NumberRange.new(1, 3),
		size = NumberSequence.new(width * 2.5, 0),
		zOffset = 18,
	})
	muzzleEmitter:Emit(4)
	table.insert(anchors, muzzlePart)

	Core.runFor(dur, function(_, t)
		local k = t / dur
		if k >= 0.6 then
			local fade = (k - 0.6) / 0.4
			corePart.Transparency = 0.1 + 0.9 * fade
			for _, b in ipairs(beams) do
				b.Transparency = NumberSequence.new(math.clamp(0.1 + 0.9 * fade, 0, 1))
			end
		end
	end, function()
		corePart:Destroy()
		Core.destroyAll(beams)
		Core.destroyAll(anchors)
	end)
end

-- 7. Supernova Domain Sphere Engine (254 radial beams + 358-stud flash + 160-stud shockwave disc)
function Core.supernovaSphere(center, colorSeq, maxRadius, o)
	o = o or {}
	maxRadius = maxRadius or 70
	local dur = o.duration or 1.5
	local anchor = Core.anchor(center)
	local att = Core.attach(anchor)
	Core.sound(center, o.soundId or Core.Sounds.Explosion, o.volume or 1.0, o.pitch or 0.8)

	-- 160-stud Flat Floor Shockwave Disc (VelocityPerpendicular)
	local disc = Core.emitter(att, {
		texture = Core.PinnacleTextures.ShockwaveDisc160,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.6, 0.9),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 10),
			NumberSequenceKeypoint.new(0.5, maxRadius * 2.2),
			NumberSequenceKeypoint.new(1, maxRadius * 2.5),
		}),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
		zOffset = 10,
	})

	-- 358-stud Massive Celestial Core Flash
	local flash = Core.emitter(att, {
		texture = Core.PinnacleTextures.SupernovaFlash,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.3, 0.5),
		speed = NumberRange.new(0.1, 0.5),
		size = NumberSequence.new(maxRadius * 2.6, maxRadius * 0.2),
		zOffset = 20,
	})

	-- Radial Beams Starburst
	local radial = Core.emitter(att, {
		texture = Core.PinnacleTextures.SupernovaBeams,
		color = colorSeq,
		light = 1,
		rate = 0,
		lifetime = NumberRange.new(0.5, 0.8),
		speed = NumberRange.new(1, 5),
		size = NumberSequence.new(maxRadius * 2.4, 0),
		rotSpeed = NumberRange.new(-60, 60),
		zOffset = 16,
	})

	disc:Emit(2)
	flash:Emit(3)
	radial:Emit(4)

	-- Expanding 3D Sculpted FancySphere Core (`rbxassetid://5703278366`)
	local spherePart, sphereMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 4, CFrame.new(center), {
		color = o.coreColor or Color3.fromRGB(255, 255, 240),
		material = Enum.Material.Neon,
		transparency = 0.05,
	})

	Core.runFor(dur, function(_, t)
		local k = t / dur
		local sz = 4 + (maxRadius - 4) * Core.smooth(k)
		spherePart.Size = Vector3.one * sz
		sphereMesh.Scale = Vector3.one * (sz * 0.1)
		if k >= 0.4 then
			local fade = (k - 0.4) / 0.6
			spherePart.Transparency = 0.05 + 0.95 * fade
		end
	end, function()
		spherePart:Destroy()
		Core.cleanupLater({ anchor }, 1)
	end)
end

-- 8. 3-Layer Stylized Anime Spike Burst (preserved & upgraded with custom GroundSpikes mesh)
function Core.animeSpikeBurst(pos, o)
	o = o or {}
	local color = o.color or Color3.fromRGB(255, 120, 20)
	local coreColor = o.coreColor or Color3.fromRGB(255, 255, 220)
	local count = o.count or 8
	local radius = o.radius or 5
	local minH = o.minHeight or 7
	local maxH = o.maxHeight or 15
	local dur = o.duration or 0.55
	local aimDir = o.aimDir
	local rng = Random.new()

	local parts = {}
	local spikeData = {}

	-- Ground shockwave
	if o.groundRing ~= false then
		Core.shockwave(Core.groundCF(pos + Vector3.new(0, 0.1, 0)), {
			color = color,
			from = 1,
			to = radius * 2.8,
			duration = dur * 0.7,
		})
	end

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
		local w = rng:NextNumber(1.4, 2.8)

		local spikePos = pos + Vector3.new(math.sin(angle) * dist, 0, math.cos(angle) * dist)
		local cf = CFrame.new(spikePos)
			* CFrame.Angles(0, angle + math.pi, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(-10, 15)), 0, math.rad(rng:NextNumber(8, 22)))

		-- 3D Sculpted GroundSpikes MeshPart (`rbxassetid://967645205`)
		local spikePart, mesh = Core.meshPart(Core.Meshes.GroundSpikes, Vector3.new(w, h, w), cf, {
			color = color,
			material = Enum.Material.Neon,
			transparency = 0.1,
		})
		table.insert(parts, spikePart)

		table.insert(spikeData, {
			part = spikePart,
			mesh = mesh,
			cf = cf,
			targetSize = Vector3.new(w, h, w),
		})
	end

	-- Curved Anime Slash Arc sweeping across the spikes
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

	Core.runFor(dur, function(_, t)
		if t <= 0.12 then
			local grow = Core.smooth(t / 0.12)
			for _, s in ipairs(spikeData) do
				s.part.Size = s.targetSize * Vector3.new(1, grow, 1)
			end
		elseif t >= dur * 0.65 then
			local fade = (t - dur * 0.65) / (dur * 0.35)
			local shrink = 1 - fade * 0.4
			for _, s in ipairs(spikeData) do
				s.part.Size = s.targetSize * Vector3.new(shrink, shrink, shrink)
				s.part.Transparency = 0.1 + 0.9 * fade
			end
		end
	end, function()
		Core.destroyAll(parts)
	end)
end

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

	-- Supernova blast wave at start
	Core.supernovaSphere(center, Core.seq({ coreCol, accent, color }), R * 0.8, { duration = 1.0 })

	-- Floor Disc
	local floor = Core.part(Enum.PartType.Cylinder, Vector3.new(0.25, R * 2, R * 2), Core.groundCF(center + Vector3.new(0, 0.05, 0)), {
		color = color, material = Enum.Material.Neon, transparency = 0.65,
	})
	table.insert(visible, floor)

	-- Concentric Inner Rune Rings
	local innerRing = Core.part(Enum.PartType.Cylinder, Vector3.new(0.28, R * 1.2, R * 1.2), Core.groundCF(center + Vector3.new(0, 0.08, 0)), {
		color = accent, material = Enum.Material.Neon, transparency = 0.75,
	})
	table.insert(visible, innerRing)

	-- Perimeter Pillars with Beams
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

	-- Outer Forcefield Shell
	local shell = Core.part(Enum.PartType.Cylinder, Vector3.new(H, R * 2, R * 2), Core.groundCF(center + Vector3.new(0, H * 0.5, 0)), {
		color = color, material = Enum.Material.ForceField, transparency = 0.82,
	})
	table.insert(visible, shell)

	-- Floating Central 3D FancySphere Core
	local coreBall, coreMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 8, CFrame.new(center + Vector3.new(0, H * 0.65, 0)), {
		color = coreCol, material = Enum.Material.Neon, transparency = 0.15,
		spin = Vector3.new(1, 2, 1),
	})
	table.insert(visible, coreBall)

	local coreLight = Instance.new("PointLight")
	coreLight.Color = accent
	coreLight.Brightness = 6
	coreLight.Range = R * 1.2
	coreLight.Parent = coreBall
	table.insert(visible, coreLight)

	local fadeStart = life - fadeOut
	Core.runFor(life, function(_, t)
		coreBall.Size = Vector3.one * (8 + math.sin(t * 5) * 1.2)
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

function Core.afterimage(character, o)
	o = o or {}
	if not character then return end
	local ok, clone = pcall(function() return character:Clone() end)
	if not ok or not clone then return end
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
	if o.at then clone:PivotTo(o.at) end
	clone.Parent = folder
	Core.runFor(life, function(_, t)
		Core.setTransparency(parts, 0.5 + 0.5 * (t / life))
	end, function()
		clone:Destroy()
	end)
end

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
		if dir.Magnitude < 0.01 then dir = Vector3.yAxis end
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
		for _, f in ipairs(list) do f.part:Destroy() end
	end)
end

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
		for _, c in ipairs(list) do c.part:Destroy() end
	end)
end

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
-- Context & Character Helpers
---------------------------------------------------------------------------

function Core.root(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

function Core.getPart(character, names)
	for _, n in ipairs(names) do
		local p = character and character:FindFirstChild(n)
		if p then return p end
	end
	return Core.root(character)
end

function Core.behind(model, dist)
	local r = Core.root(model)
	if not r then return nil end
	return r.Position - r.CFrame.LookVector * (dist or 3)
end

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
