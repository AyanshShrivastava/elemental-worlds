--!strict
-- Error.luau — Top-Tier Error Element VFX (Secret Element)
-- Black Flash negative light emission (Light = -10), Axoie -100 singularity void,
-- Hollow Purple furrow physics, and 3D sculpted Glitch meshes.

local Core = require(script.Parent.Core)

local BLACK = Color3.fromRGB(8, 6, 12)
local DEEP_VIOLET = Color3.fromRGB(55, 10, 85)
local NEON_MAGENTA = Color3.fromRGB(255, 20, 140)
local CYAN_GLITCH = Color3.fromRGB(0, 255, 240)
local GLITCH = Core.seq({ BLACK, DEEP_VIOLET, NEON_MAGENTA, CYAN_GLITCH })
local VOID_SEQ = Core.seq({ Color3.fromRGB(0, 0, 0), DEEP_VIOLET, NEON_MAGENTA })

local Error = {}

-- M1: Glitched Black Flash Dash (LightEmission = -10 negative energy cut + GlitchBall)
function Error.M1(ctx)
	local char = ctx.character
	local r = Core.root(char)
	if not r then return end
	local dir = ctx.direction
	local start = r.Position
	local target = start + dir * 18

	-- Ghost afterimage with chromatic distortion
	Core.afterimage(char, { color = NEON_MAGENTA, life = 0.35 })

	-- 3D Sculpted GlitchBall Mesh (`rbxassetid://6553021063`)
	local glitchPart, mesh = Core.meshPart(Core.Meshes.GlitchBall, Vector3.one * 4, Core.lookCF(target, dir), {
		color = NEON_MAGENTA,
		material = Enum.Material.Neon,
		transparency = 0.2,
		spin = Vector3.new(12, 18, 6),
	})

	-- Black Flash Negative Emitters (LightEmission = -10)
	local anchor = Core.anchor(target)
	local att = Core.attach(anchor)
	local bf1 = Core.emitter(att, {
		texture = Core.PinnacleTextures.BlackFlash1,
		color = ColorSequence.new(BLACK),
		light = -10,
		rate = 0,
		lifetime = NumberRange.new(0.2, 0.4),
		speed = NumberRange.new(2, 6),
		size = NumberSequence.new(6, 12),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		zOffset = 18,
	})
	local bf2 = Core.emitter(att, {
		texture = Core.PinnacleTextures.BlackFlash2,
		color = ColorSequence.new(NEON_MAGENTA),
		light = -10,
		rate = 0,
		lifetime = NumberRange.new(0.15, 0.3),
		speed = NumberRange.new(1, 4),
		size = NumberSequence.new(5, 10),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		zOffset = 19,
	})

	bf1:Emit(4)
	bf2:Emit(4)

	-- Micro-cleave cut
	Core.dismantleCleave(Core.lookCF(target, dir), GLITCH, 10)

	Core.runFor(0.35, function(_, t)
		glitchPart.Transparency = 0.2 + 0.8 * (t / 0.35)
	end, function()
		glitchPart:Destroy()
		Core.cleanupLater({ anchor }, 0.5)
	end)
end

-- Move1: Chaotic Destruction / Null Zone (Axoie -100 Light Singularity Void)
function Error.Move1(ctx)
	local target = ctx.target
	local dir = ctx.direction

	-- Spawn the Axoie Negative Singularity (Light = -100 space absorption + GravityBallShockwave)
	local singularity = Core.negativeSingularity(target, 10, { duration = 1.2 })

	task.delay(0.6, function()
		-- Violent collapse cleave & ground fracture
		Core.dismantleCleave(Core.lookCF(target, dir), GLITCH, 14)
		Core.groundSlamCrater(target, GLITCH, 16, { duration = 2.0, rockCount = 22 })

		-- Negative Divergent Ring
		local ringAnchor = Core.anchor(target)
		local ring = Core.emitter(Core.attach(ringAnchor), {
			texture = Core.PinnacleTextures.DivergentRing,
			color = VOID_SEQ,
			light = -20,
			rate = 0,
			lifetime = NumberRange.new(0.25, 0.4),
			speed = NumberRange.new(0.1, 0.5),
			size = NumberSequence.new(3, 16),
			orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			zOffset = 12,
		})
		ring:Emit(2)
		Core.cleanupLater({ ringAnchor }, 0.6)
	end)
end

-- Move2: 404 Not Found / Byte Blast (Hollow Purple Void Sphere Furrow)
function Error.Move2(ctx)
	local origin = ctx.origin + ctx.direction * 3
	local target = ctx.target
	local dir = (target - origin).Unit
	local dist = (target - origin).Magnitude
	local dur = math.max(dist / 40, 0.4)

	-- Dual Colliding Charges (Cyan Glitch + Magenta Void)
	Core.converge(origin, 8, 25, 0.35, CYAN_GLITCH)
	Core.converge(origin, 8, 25, 0.35, NEON_MAGENTA)

	task.delay(0.3, function()
		-- 3D Sculpted FancySphere Void Core
		local voidBall, vMesh = Core.meshPart(Core.Meshes.FancySphere, Vector3.one * 6, Core.lookCF(origin, dir), {
			color = BLACK,
			material = Enum.Material.Neon,
			transparency = 0.05,
			spin = Vector3.new(10, 20, 10),
		})

		-- Negative Light Emission Void Aura (Light = -30)
		local att = Core.attach(voidBall)
		local voidE = Core.emitter(att, {
			texture = Core.PinnacleTextures.AxoieVoid30,
			color = VOID_SEQ,
			light = -30,
			rate = 50,
			lifetime = NumberRange.new(0.25, 0.45),
			speed = NumberRange.new(1, 4),
			size = NumberSequence.new(8, 1),
			zOffset = 18,
		})

		-- Black Flash Energy Lightning
		local bfLightning = Core.emitter(att, {
			texture = Core.PinnacleTextures.BlackFlash1,
			color = ColorSequence.new(NEON_MAGENTA),
			light = -10,
			rate = 35,
			lifetime = NumberRange.new(0.15, 0.25),
			speed = NumberRange.new(2, 6),
			size = NumberSequence.new(7, 1),
			orientation = Enum.ParticleOrientation.VelocityParallel,
			zOffset = 19,
		})

		-- Furrow trench across ground
		local furrowThread = task.spawn(function()
			while voidBall.Parent do
				task.wait(0.08)
				if not voidBall.Parent then break end
				Core.groundSlamCrater(voidBall.Position, GLITCH, 8, { duration = 1.0, rockCount = 6, useMesh = false })
			end
		end)

		Core.runFor(dur, function(_, t)
			local k = math.clamp(t / dur, 0, 1)
			voidBall.Position = origin:Lerp(target, k)
		end, function()
			task.cancel(furrowThread)
			voidE.Enabled = false
			bfLightning.Enabled = false
			voidBall:Destroy()

			-- Final Cataclysmic Annihilation Burst
			Core.supernovaSphere(target, GLITCH, 35, { duration = 1.2 })
			Core.groundSlamCrater(target, GLITCH, 20, { duration = 2.5, rockCount = 30 })
		end)
	end)
end

-- Move3: Got Glitched (Digital Fragmentation Dissolve + Handle)
function Error.Move3(ctx)
	local char = ctx.character
	local r = Core.root(char)
	local duration = ctx.duration or 5
	if not char or not r then return { End = function() end } end

	local hiddenParts = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(hiddenParts, { part = d, orig = d.Transparency })
			d.Transparency = 1
		end
	end

	-- Digital Dissolve Burst at origin
	Core.burst(r.Position, 30, {
		texture = Core.PinnacleTextures.BlackFlash2,
		color = GLITCH,
		speed = 22,
		life = 0.6,
		light = -5,
	})

	local isGlitched = true
	local handle = {}

	function handle:End()
		if not isGlitched then return end
		isGlitched = false
		for _, item in ipairs(hiddenParts) do
			if item.part.Parent then
				item.part.Transparency = item.orig
			end
		end
		Core.burst(r.Position, 25, {
			texture = Core.PinnacleTextures.PopStar,
			color = GLITCH,
			speed = 20,
			life = 0.4,
		})
	end

	task.delay(duration, function()
		if isGlitched then handle:End() end
	end)

	return handle
end

-- Move4: Spatial Distortion (Glitch Domain Arena with GlitchWind + Handle)
function Error.Move4(ctx)
	local center = ctx.arenaCFrame and ctx.arenaCFrame.Position or ctx.origin
	local duration = ctx.duration or 7
	local R = 45

	local domainModel = Instance.new("Model")
	domainModel.Name = "SpatialDistortionVFX"
	domainModel.Parent = Core.Folder

	-- 1. 3D Sculpted GlitchWind Mesh (`rbxassetid://6553151264`)
	local windPart, m = Core.meshPart(Core.Meshes.GlitchWind, Vector3.one * (R * 1.6), CFrame.new(center), {
		color = DEEP_VIOLET,
		material = Enum.Material.Neon,
		transparency = 0.4,
		spin = Vector3.new(4, 8, 4),
		parent = domainModel,
	})

	-- 2. Inverted Black Hole Singularities at Perimeter
	local pts = Core.circle(center, R * 0.75, 6, 2)
	for _, pt in ipairs(pts) do
		Core.negativeSingularity(pt, 5, { duration = duration })
	end

	-- 3. Inverted Flat Floor Ring (Light = -20)
	local floorAnchor = Core.anchor(center + Vector3.new(0, 0.1, 0))
	local floorRing = Core.emitter(Core.attach(floorAnchor), {
		texture = Core.PinnacleTextures.DivergentRing,
		color = VOID_SEQ,
		light = -20,
		rate = 0,
		lifetime = NumberRange.new(duration, duration),
		size = NumberSequence.new(R * 2.2),
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		direction = Enum.NormalId.Top,
	})
	floorRing:Emit(1)
	floorAnchor.Parent = domainModel

	local isDomainActive = true
	local handle = {}

	function handle:End()
		if not isDomainActive then return end
		isDomainActive = false
		Core.supernovaSphere(center, GLITCH, R * 0.9, { duration = 0.8 })
		task.delay(0.4, function()
			domainModel:Destroy()
		end)
	end

	task.delay(duration, function()
		if isDomainActive then handle:End() end
	end)

	return handle
end

-- Move5: Unparalleled (Reality Rupture on Targets)
function Error.Move5(ctx)
	local targets = ctx.targets or { ctx.targetCharacter }
	local duration = ctx.duration or 5

	for _, tgt in ipairs(targets) do
		if tgt then
			local r = Core.root(tgt)
			if r then
				local p = r.Position
				-- Negative Singularity on target
				Core.negativeSingularity(p, 6, { duration = duration })

				-- Black Flash Lightning Cage
				local anchor = Core.anchor(p)
				local att = Core.attach(anchor)
				local cage = Core.emitter(att, {
					texture = Core.PinnacleTextures.BlackFlash1,
					color = ColorSequence.new(NEON_MAGENTA),
					light = -10,
					rate = 25,
					lifetime = NumberRange.new(0.2, 0.4),
					speed = NumberRange.new(2, 6),
					size = NumberSequence.new(5, 8),
					orientation = Enum.ParticleOrientation.VelocityParallel,
				})

				task.delay(duration, function()
					cage.Enabled = false
					Core.dismantleCleave(Core.lookCF(p, Vector3.new(0, 1, 0)), GLITCH, 12)
					Core.groundSlamCrater(p, GLITCH, 12, { duration = 1.5, rockCount = 14 })
					Core.cleanupLater({ anchor }, 0.5)
				end)
			end
		end
	end
end

-- Error Meter Display above character head
function Error.Meter(character, pct)
	local head = character and character:FindFirstChild("Head")
	if not head then return end
	local bb = head:FindFirstChild("ErrorMeterBB")
	if not bb then
		local b = Instance.new("BillboardGui")
		b.Name = "ErrorMeterBB"
		b.Size = UDim2.new(0, 130, 0, 16)
		b.StudsOffset = Vector3.new(0, 2.5, 0)
		b.AlwaysOnTop = true
		b.Parent = head

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(15, 8, 22)
		bg.BorderSizePixel = 0
		bg.Parent = b

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = NEON_MAGENTA
		fill.BorderSizePixel = 0
		fill.Parent = bg
	else
		local fill = bb:FindFirstChild("Fill", true) :: Frame?
		if fill then
			fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
		end
	end
end

return Error
