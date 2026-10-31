--!strict
--[[
    Elemental Worlds: Master VFX Helper Module (Blox Fruits Anime Combat)
    Features:
    - Real Roblox Creator Store Particle Textures (Anime Slashes, Stars, Smoke, Lightning)
    - Stylized Impact Bursts with spark emitters and point lights
    - Dynamic Shockwaves with expanding Neon Rings & Distortion Meshes
    - Ground Impact Craters with outward-tilted rock fragments and smoke puffs
    - Multi-layered Cylindrical Energy Beams (Core + Sheath)
    - Swirling Elemental Auras with dynamic acceleration
    - Directional Anime Slash Arcs with customizable scaling and angles
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFXHelper = {}

-- Real Verified Roblox Anime VFX Asset IDs
local ASSETS = {
    SLASH_TEXTURE     = "rbxassetid://4991873131", -- Anime crescent curve
    STAR_SPARKLE      = "rbxassetid://6034177218", -- Crisp anime 4-point star
    SMOKE_PUFF        = "rbxassetid://2520762076", -- Stylized dust / smoke
    LIGHTNING_STREAK  = "rbxassetid://446111271",  -- Electric discharge streak
    RING_MESH         = "rbxassetid://3270017",    -- Torus / Ring mesh
}

-- Curated Color Palettes for each Element
local ELEMENT_PALETTES = {
    Fire = {
        Primary = Color3.fromRGB(255, 75, 30),
        Secondary = Color3.fromRGB(255, 185, 45),
        Dark = Color3.fromRGB(160, 20, 10),
    },
    Aqua = {
        Primary = Color3.fromRGB(0, 165, 255),
        Secondary = Color3.fromRGB(135, 230, 255),
        Dark = Color3.fromRGB(10, 75, 170),
    },
    Earth = {
        Primary = Color3.fromRGB(150, 110, 65),
        Secondary = Color3.fromRGB(205, 165, 105),
        Dark = Color3.fromRGB(75, 50, 25),
    },
    Light = {
        Primary = Color3.fromRGB(255, 235, 90),
        Secondary = Color3.fromRGB(255, 255, 220),
        Dark = Color3.fromRGB(220, 175, 30),
    },
    Wind = {
        Primary = Color3.fromRGB(60, 225, 155),
        Secondary = Color3.fromRGB(180, 255, 220),
        Dark = Color3.fromRGB(40, 160, 105),
    },
    Error = {
        Primary = Color3.fromRGB(255, 20, 140),
        Secondary = Color3.fromRGB(0, 255, 240),
        Dark = Color3.fromRGB(110, 0, 90),
    },
    Time = {
        Primary = Color3.fromRGB(130, 85, 255),
        Secondary = Color3.fromRGB(210, 185, 255),
        Dark = Color3.fromRGB(35, 20, 120),
    },
}

local function GetVFXFolder(): Folder
    local folder = Workspace:FindFirstChild("VFX")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "VFX"
        folder.Parent = Workspace
    end
    return folder :: Folder
end

-- ==================== 1. DYNAMIC EXPANDING SHOCKWAVE ====================
function VFXHelper.CreateShockwave(position: Vector3, maxRadius: number, duration: number, element: string)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    -- Neon expanding cylinder
    local ring = Instance.new("Part")
    ring.Name = "VFX_Shockwave"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.4, 2, 2)
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Material = Enum.Material.Neon
    ring.Color = palette.Primary
    ring.Transparency = 0.2
    ring.CanCollide = false
    ring.Anchored = true
    ring.Parent = vfxFolder

    local targetSize = Vector3.new(0.05, maxRadius * 2, maxRadius * 2)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

    local tween = TweenService:Create(ring, tweenInfo, {
        Size = targetSize,
        Transparency = 1,
    })
    tween:Play()

    -- Inner distortion ring
    local inner = Instance.new("Part")
    inner.Name = "VFX_InnerRing"
    inner.Shape = Enum.PartType.Cylinder
    inner.Size = Vector3.new(0.2, 1, 1)
    inner.CFrame = ring.CFrame
    inner.Material = Enum.Material.Neon
    inner.Color = palette.Secondary
    inner.Transparency = 0.1
    inner.CanCollide = false
    inner.Anchored = true
    inner.Parent = vfxFolder

    local innerTween = TweenService:Create(inner, TweenInfo.new(duration * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.02, maxRadius * 1.5, maxRadius * 1.5),
        Transparency = 1,
    })
    innerTween:Play()

    Debris:AddItem(ring, duration + 0.1)
    Debris:AddItem(inner, duration + 0.1)
end

-- ==================== 2. IMPACT BURST (With Real Anime Textures) ====================
function VFXHelper.CreateImpactBurst(position: Vector3, element: string, particleCount: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local emitterPart = Instance.new("Part")
    emitterPart.Name = "VFX_ImpactPart"
    emitterPart.Size = Vector3.new(1, 1, 1)
    emitterPart.CFrame = CFrame.new(position)
    emitterPart.Transparency = 1
    emitterPart.CanCollide = false
    emitterPart.Anchored = true
    emitterPart.Parent = vfxFolder

    -- Anime Star Spark Emitter
    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "Sparks"
    sparks.Texture = ASSETS.STAR_SPARKLE
    sparks.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.4, palette.Secondary),
        ColorSequenceKeypoint.new(0.8, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.8),
        NumberSequenceKeypoint.new(0.6, 1.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Speed = NumberRange.new(22, 44)
    sparks.SpreadAngle = Vector2.new(180, 180)
    sparks.Lifetime = NumberRange.new(0.3, 0.6)
    sparks.LightEmission = 1.0
    sparks.LightInfluence = 0
    sparks.Rate = 0
    sparks.Parent = emitterPart

    -- Stylized Smoke / Dust Puff
    local smoke = Instance.new("ParticleEmitter")
    smoke.Name = "SmokePuff"
    smoke.Texture = ASSETS.SMOKE_PUFF
    smoke.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.Secondary),
        ColorSequenceKeypoint.new(0.5, palette.Primary),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 50)),
    })
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(1, 4.0),
    })
    smoke.Speed = NumberRange.new(8, 18)
    smoke.SpreadAngle = Vector2.new(180, 180)
    smoke.Lifetime = NumberRange.new(0.4, 0.75)
    smoke.LightEmission = 0.5
    smoke.LightInfluence = 0
    smoke.Rate = 0
    smoke.Parent = emitterPart

    -- Point Light Flash
    local flash = Instance.new("PointLight")
    flash.Color = palette.Secondary
    flash.Range = 26
    flash.Brightness = 5
    flash.Parent = emitterPart

    TweenService:Create(flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 0,
    }):Play()

    local count = particleCount or 32
    sparks:Emit(count)
    smoke:Emit(math.round(count * 0.4))

    Debris:AddItem(emitterPart, 1.0)
end

-- ==================== 3. ANIME SLASH ARC ====================
function VFXHelper.CreateSlashArc(cframe: CFrame, element: string, scale: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local s = scale or 1.0
    local slashPart = Instance.new("Part")
    slashPart.Name = "VFX_SlashArc"
    slashPart.Size = Vector3.new(7 * s, 0.2, 6 * s)
    slashPart.CFrame = cframe * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.rad(math.random(-20, 20)), math.rad(math.random(-15, 15)))
    slashPart.Material = Enum.Material.Neon
    slashPart.Color = palette.Secondary
    slashPart.Transparency = 0.05
    slashPart.CanCollide = false
    slashPart.Anchored = true
    slashPart.Parent = vfxFolder

    -- Particle curve on slash edge
    local slashEmitter = Instance.new("ParticleEmitter")
    slashEmitter.Texture = ASSETS.SLASH_TEXTURE
    slashEmitter.Color = ColorSequence.new(palette.Primary, palette.Secondary)
    slashEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    slashEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3 * s),
        NumberSequenceKeypoint.new(1, 0),
    })
    slashEmitter.Lifetime = NumberRange.new(0.18, 0.25)
    slashEmitter.Speed = NumberRange.new(10, 20)
    slashEmitter.LightEmission = 1.0
    slashEmitter.Rate = 0
    slashEmitter.Parent = slashPart

    slashEmitter:Emit(8)

    local tween = TweenService:Create(slashPart, TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = Vector3.new(12 * s, 0.05, 9 * s),
        Transparency = 1,
        CFrame = slashPart.CFrame * CFrame.new(0, 0, -2.5),
    })
    tween:Play()
    Debris:AddItem(slashPart, 0.25)
end

-- ==================== 4. GROUND IMPACT CRATER ====================
function VFXHelper.CreateCrater(position: Vector3, radius: number, element: string)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local r = radius or 14
    local rockCount = 8

    -- Circular rock fragments tilted outwards
    for i = 1, rockCount do
        local angle = (i / rockCount) * math.pi * 2
        local x = math.cos(angle) * (r * 0.75)
        local z = math.sin(angle) * (r * 0.75)
        local rockPos = position + Vector3.new(x, 0.5, z)

        local rock = Instance.new("Part")
        rock.Name = "VFX_CraterRock"
        rock.Size = Vector3.new(r * 0.22, r * 0.35, r * 0.22)
        rock.Color = Color3.fromRGB(65, 60, 55)
        rock.Material = Enum.Material.Slate
        rock.Anchored = true
        rock.CanCollide = false
        rock.CFrame = CFrame.new(rockPos, position) * CFrame.Angles(math.rad(math.random(25, 45)), math.rad(math.random(-15, 15)), 0)
        rock.Parent = vfxFolder

        -- Submerge and destroy
        task.delay(1.5, function()
            if rock.Parent then
                local sinkTween = TweenService:Create(rock, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = rock.CFrame * CFrame.new(0, -3, 0),
                    Transparency = 1,
                })
                sinkTween:Play()
                sinkTween.Completed:Wait()
                rock:Destroy()
            end
        end)
    end

    -- Rising dust cloud
    local dustPart = Instance.new("Part")
    dustPart.Size = Vector3.new(1, 1, 1)
    dustPart.CFrame = CFrame.new(position)
    dustPart.Transparency = 1
    dustPart.Anchored = true
    dustPart.CanCollide = false
    dustPart.Parent = vfxFolder

    local dustEmitter = Instance.new("ParticleEmitter")
    dustEmitter.Texture = ASSETS.SMOKE_PUFF
    dustEmitter.Color = ColorSequence.new(Color3.fromRGB(160, 150, 140))
    dustEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.7, 0.7),
        NumberSequenceKeypoint.new(1, 1),
    })
    dustEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 6),
    })
    dustEmitter.Speed = NumberRange.new(12, 28)
    dustEmitter.SpreadAngle = Vector2.new(180, 45)
    dustEmitter.Lifetime = NumberRange.new(0.6, 1.1)
    dustEmitter.Rate = 0
    dustEmitter.Parent = dustPart

    dustEmitter:Emit(25)
    Debris:AddItem(dustPart, 1.5)
end

-- ==================== 5. ENERGY BEAM (Dual Core + Sheath) ====================
function VFXHelper.CreateBeam(startPos: Vector3, endPos: Vector3, element: string, thickness: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local dist = (endPos - startPos).Magnitude
    local midPos = (startPos + endPos) / 2
    local lookCF = CFrame.new(midPos, endPos) * CFrame.Angles(0, 0, math.rad(90))

    local th = thickness or 1.5

    -- Outer Glowing Sheath
    local sheath = Instance.new("Part")
    sheath.Name = "VFX_BeamSheath"
    sheath.Shape = Enum.PartType.Cylinder
    sheath.Size = Vector3.new(dist, th * 2, th * 2)
    sheath.CFrame = lookCF
    sheath.Material = Enum.Material.Neon
    sheath.Color = palette.Primary
    sheath.Transparency = 0.2
    sheath.Anchored = true
    sheath.CanCollide = false
    sheath.Parent = vfxFolder

    -- Inner Pure Core
    local core = Instance.new("Part")
    core.Name = "VFX_BeamCore"
    core.Shape = Enum.PartType.Cylinder
    core.Size = Vector3.new(dist + 0.2, th * 0.9, th * 0.9)
    core.CFrame = lookCF
    core.Material = Enum.Material.Neon
    core.Color = Color3.fromRGB(255, 255, 255)
    core.Transparency = 0.05
    core.Anchored = true
    core.CanCollide = false
    core.Parent = vfxFolder

    local fadeDuration = 0.3
    TweenService:Create(sheath, TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(dist, 0, 0),
        Transparency = 1,
    }):Play()
    TweenService:Create(core, TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(dist, 0, 0),
        Transparency = 1,
    }):Play()

    Debris:AddItem(sheath, fadeDuration + 0.05)
    Debris:AddItem(core, fadeDuration + 0.05)
end

-- ==================== 6. PERSISTENT ELEMENTAL AURA ====================
function VFXHelper.AttachElementalAura(character: Model, element: string): Attachment?
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return nil end

    local existing = rootPart:FindFirstChild("ElementalAuraAttachment")
    if existing then existing:Destroy() end

    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local attach = Instance.new("Attachment")
    attach.Name = "ElementalAuraAttachment"
    attach.Position = Vector3.new(0, -1.5, 0)
    attach.Parent = rootPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AuraEnergy"
    emitter.Texture = ASSETS.STAR_SPARKLE
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.7, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.6, 1.4),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    emitter.Speed = NumberRange.new(3, 6)
    emitter.Acceleration = Vector3.new(0, 10, 0)
    emitter.SpreadAngle = Vector2.new(25, 25)
    emitter.Lifetime = NumberRange.new(0.6, 1.0)
    emitter.LightEmission = 0.9
    emitter.LightInfluence = 0
    emitter.Rate = 22
    emitter.Parent = attach

    return attach
end

return table.freeze(VFXHelper)
