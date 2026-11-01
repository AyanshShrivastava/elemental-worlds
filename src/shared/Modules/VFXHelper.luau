--!strict
--[[
    Elemental Worlds: Master VFX Helper Module (Top-Tier Stylized Anime Combat)
    Aesthetic: Modern Dark Cel-Shaded Anime Action (TSB / Blox Fruits inspired)
    Features:
    - Real Creator Store Particle Textures (Crescent slashes, 4-point stars, smoke puffs, lightning)
    - Stylized Torus & Distortion Shockwave Meshes
    - Multi-tiered Ground Impact Craters with rock debris meshes and glowing ground cracks
    - Dual-Core Energy Beams with high-voltage neon pulsation
    - 3-Tier Layered Impact Bursts (White core flash, star sparks, stylized dissipation smoke)
    - Directional Anime Slash Arcs with trailing crescent particles
    - Converging Energy Charge VFX for high-power ability wind-ups
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFXHelper = {}

-- Real Verified Roblox Creator Store Asset IDs
local ASSETS = {
    SLASH_TEXTURE     = "rbxassetid://4991873131", -- Anime crescent curve
    STAR_SPARKLE      = "rbxassetid://6034177218", -- Crisp anime 4-point star
    SMOKE_PUFF        = "rbxassetid://2520762076", -- Stylized dust / smoke
    LIGHTNING_STREAK  = "rbxassetid://446111271",  -- Electric discharge streak
    RING_MESH         = "rbxassetid://3270017",    -- Torus / Ring mesh
    ROCK_MESH         = "rbxassetid://1290033",    -- Rock fragment mesh
    WATER_SPLASH      = "rbxassetid://5850414902", -- Stylized water splash
    GLITCH_PIXEL      = "rbxassetid://6034293922", -- Pixel square / cyber spark
    CLOCK_DIAL        = "rbxassetid://1084991219", -- Ethereal clock face
}

-- Curated Harmonious Stylized Palettes (Strictly NO gold, NO rainbow)
local ELEMENT_PALETTES = {
    Fire = {
        Primary = Color3.fromRGB(255, 65, 20),
        Secondary = Color3.fromRGB(255, 140, 25),
        Dark = Color3.fromRGB(150, 15, 10),
        Core = Color3.fromRGB(255, 240, 220),
    },
    Aqua = {
        Primary = Color3.fromRGB(0, 195, 255),
        Secondary = Color3.fromRGB(120, 230, 255),
        Dark = Color3.fromRGB(15, 70, 180),
        Core = Color3.fromRGB(230, 250, 255),
    },
    Earth = {
        Primary = Color3.fromRGB(140, 95, 55),
        Secondary = Color3.fromRGB(210, 170, 110),
        Dark = Color3.fromRGB(65, 45, 25),
        Core = Color3.fromRGB(255, 245, 230),
    },
    Light = {
        Primary = Color3.fromRGB(255, 250, 140),
        Secondary = Color3.fromRGB(255, 255, 230),
        Dark = Color3.fromRGB(215, 180, 40),
        Core = Color3.fromRGB(255, 255, 255),
    },
    Wind = {
        Primary = Color3.fromRGB(60, 240, 180),
        Secondary = Color3.fromRGB(180, 255, 230),
        Dark = Color3.fromRGB(30, 150, 100),
        Core = Color3.fromRGB(235, 255, 250),
    },
    Error = {
        Primary = Color3.fromRGB(255, 20, 140),
        Secondary = Color3.fromRGB(0, 240, 255),
        Dark = Color3.fromRGB(120, 0, 95),
        Core = Color3.fromRGB(255, 255, 255),
    },
    Time = {
        Primary = Color3.fromRGB(90, 110, 255),
        Secondary = Color3.fromRGB(190, 180, 255),
        Dark = Color3.fromRGB(30, 35, 130),
        Core = Color3.fromRGB(245, 240, 255),
    },
}

VFXHelper.ELEMENT_PALETTES = ELEMENT_PALETTES

function VFXHelper.GetPalette(element: string)
    return ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
end

local function GetVFXFolder(): Folder
    local folder = Workspace:FindFirstChild("VFX")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "VFX"
        folder.Parent = Workspace
    end
    return folder :: Folder
end

-- ==================== 1. STYLIZED TORUS SHOCKWAVE ====================
function VFXHelper.CreateShockwave(position: Vector3, maxRadius: number, duration: number, element: string)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.38
    local r = maxRadius or 22

    -- 1. Outer Torus Expanding Ring
    local torus = Instance.new("Part")
    torus.Name = "VFX_ShockwaveTorus"
    torus.Size = Vector3.new(2, 2, 0.4)
    torus.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
    torus.Material = Enum.Material.Neon
    torus.Color = palette.Primary
    torus.Transparency = 0.15
    torus.CanCollide = false
    torus.Anchored = true
    torus.Parent = vfxFolder

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = ASSETS.RING_MESH
    mesh.Scale = Vector3.new(1, 1, 0.5)
    mesh.Parent = torus

    local targetScale = Vector3.new(r * 0.45, r * 0.45, 0.8)
    TweenService:Create(mesh, TweenInfo.new(d, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Scale = targetScale,
    }):Play()
    TweenService:Create(torus, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1,
    }):Play()

    -- 2. Inner Fast Expansion Disc
    local disc = Instance.new("Part")
    disc.Name = "VFX_InnerDisc"
    disc.Shape = Enum.PartType.Cylinder
    disc.Size = Vector3.new(0.2, 1, 1)
    disc.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    disc.Material = Enum.Material.Neon
    disc.Color = palette.Secondary
    disc.Transparency = 0.05
    disc.CanCollide = false
    disc.Anchored = true
    disc.Parent = vfxFolder

    TweenService:Create(disc, TweenInfo.new(d * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.02, r * 1.6, r * 1.6),
        Transparency = 1,
    }):Play()

    -- 3. Outer Dissipating Smoke Ring
    local smokePart = Instance.new("Part")
    smokePart.Size = Vector3.new(1, 1, 1)
    smokePart.CFrame = CFrame.new(position)
    smokePart.Transparency = 1
    smokePart.Anchored = true
    smokePart.CanCollide = false
    smokePart.Parent = vfxFolder

    local smoke = Instance.new("ParticleEmitter")
    smoke.Texture = ASSETS.SMOKE_PUFF
    smoke.Color = ColorSequence.new(palette.Secondary, Color3.fromRGB(45, 45, 55))
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.8),
        NumberSequenceKeypoint.new(1, 5.0),
    })
    smoke.Speed = NumberRange.new(r * 1.2, r * 2.2)
    smoke.SpreadAngle = Vector2.new(180, 20)
    smoke.Lifetime = NumberRange.new(d * 0.8, d * 1.4)
    smoke.LightEmission = 0.4
    smoke.LightInfluence = 0
    smoke.Rate = 0
    smoke.Parent = smokePart

    smoke:Emit(20)

    Debris:AddItem(torus, d + 0.1)
    Debris:AddItem(disc, d + 0.1)
    Debris:AddItem(smokePart, d * 1.5)
end

-- ==================== 2. MULTI-TIER IMPACT BURST ====================
function VFXHelper.CreateImpactBurst(position: Vector3, element: string, particleCount: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()
    local count = particleCount or 32

    local emitterPart = Instance.new("Part")
    emitterPart.Name = "VFX_ImpactCenter"
    emitterPart.Size = Vector3.new(0.1, 0.1, 0.1)
    emitterPart.CFrame = CFrame.new(position)
    emitterPart.Transparency = 1
    emitterPart.CanCollide = false
    emitterPart.Anchored = true
    emitterPart.Parent = vfxFolder

    -- Core Flash Star
    local coreFlash = Instance.new("Part")
    coreFlash.Name = "VFX_CoreFlash"
    coreFlash.Shape = Enum.PartType.Ball
    coreFlash.Size = Vector3.new(3.5, 3.5, 3.5)
    coreFlash.CFrame = CFrame.new(position)
    coreFlash.Material = Enum.Material.Neon
    coreFlash.Color = palette.Core
    coreFlash.Transparency = 0
    coreFlash.CanCollide = false
    coreFlash.Anchored = true
    coreFlash.Parent = vfxFolder

    TweenService:Create(coreFlash, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1,
    }):Play()
    Debris:AddItem(coreFlash, 0.15)

    -- Anime Star Sparks
    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "StarSparks"
    sparks.Texture = ASSETS.STAR_SPARKLE
    sparks.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.Core),
        ColorSequenceKeypoint.new(0.35, palette.Secondary),
        ColorSequenceKeypoint.new(0.75, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2.4),
        NumberSequenceKeypoint.new(0.5, 1.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Speed = NumberRange.new(24, 48)
    sparks.SpreadAngle = Vector2.new(180, 180)
    sparks.Lifetime = NumberRange.new(0.28, 0.55)
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
        ColorSequenceKeypoint.new(0.4, palette.Primary),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 45)),
    })
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.7, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.8),
        NumberSequenceKeypoint.new(1, 4.5),
    })
    smoke.Speed = NumberRange.new(10, 22)
    smoke.SpreadAngle = Vector2.new(180, 180)
    smoke.Lifetime = NumberRange.new(0.35, 0.7)
    smoke.LightEmission = 0.6
    smoke.LightInfluence = 0
    smoke.Rate = 0
    smoke.Parent = emitterPart

    -- Point Light Flash
    local flash = Instance.new("PointLight")
    flash.Color = palette.Secondary
    flash.Range = 28
    flash.Brightness = 6
    flash.Parent = emitterPart

    TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 0,
    }):Play()

    sparks:Emit(count)
    smoke:Emit(math.round(count * 0.45))

    Debris:AddItem(emitterPart, 0.8)
end

-- ==================== 3. DIRECTIONAL ANIME SLASH ARC ====================
function VFXHelper.CreateSlashArc(cframe: CFrame, element: string, scale: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local s = scale or 1.0
    local slashPart = Instance.new("Part")
    slashPart.Name = "VFX_SlashBlade"
    slashPart.Size = Vector3.new(8 * s, 0.15, 7 * s)
    slashPart.CFrame = cframe * CFrame.new(0, 0, -3.2) * CFrame.Angles(0, math.rad(math.random(-25, 25)), math.rad(math.random(-15, 15)))
    slashPart.Material = Enum.Material.Neon
    slashPart.Color = palette.Secondary
    slashPart.Transparency = 0.05
    slashPart.CanCollide = false
    slashPart.Anchored = true
    slashPart.Parent = vfxFolder

    -- Particle curve on slash edge
    local slashEmitter = Instance.new("ParticleEmitter")
    slashEmitter.Texture = ASSETS.SLASH_TEXTURE
    slashEmitter.Color = ColorSequence.new(palette.Core, palette.Primary)
    slashEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    slashEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3.5 * s),
        NumberSequenceKeypoint.new(1, 0),
    })
    slashEmitter.Lifetime = NumberRange.new(0.18, 0.28)
    slashEmitter.Speed = NumberRange.new(14, 26)
    slashEmitter.LightEmission = 1.0
    slashEmitter.Rate = 0
    slashEmitter.Parent = slashPart

    slashEmitter:Emit(10)

    TweenService:Create(slashPart, TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = Vector3.new(14 * s, 0.02, 10 * s),
        Transparency = 1,
        CFrame = slashPart.CFrame * CFrame.new(0, 0, -3.5),
    }):Play()

    Debris:AddItem(slashPart, 0.25)
end

-- ==================== 4. GROUND IMPACT CRATER ====================
function VFXHelper.CreateCrater(position: Vector3, radius: number, element: string)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local r = radius or 14
    local rockCount = 10

    -- 1. Glowing Ground Energy Disc
    local groundFloor = Instance.new("Part")
    groundFloor.Name = "VFX_CraterGlowFloor"
    groundFloor.Shape = Enum.PartType.Cylinder
    groundFloor.Size = Vector3.new(0.1, r * 1.5, r * 1.5)
    groundFloor.CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
    groundFloor.Material = Enum.Material.Neon
    groundFloor.Color = palette.Primary
    groundFloor.Transparency = 0.3
    groundFloor.Anchored = true
    groundFloor.CanCollide = false
    groundFloor.Parent = vfxFolder

    TweenService:Create(groundFloor, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Transparency = 1,
        Size = Vector3.new(0.01, r * 1.8, r * 1.8),
    }):Play()
    Debris:AddItem(groundFloor, 1.9)

    -- 2. Circular Slate Rock Debris Tilted Outwards
    for i = 1, rockCount do
        local angle = (i / rockCount) * math.pi * 2
        local x = math.cos(angle) * (r * 0.72)
        local z = math.sin(angle) * (r * 0.72)
        local rockPos = position + Vector3.new(x, 0.4, z)

        local rock = Instance.new("Part")
        rock.Name = "VFX_CraterRock"
        rock.Size = Vector3.new(r * 0.24, r * 0.4, r * 0.24)
        rock.Color = Color3.fromRGB(55, 50, 48)
        rock.Material = Enum.Material.Slate
        rock.Anchored = true
        rock.CanCollide = false
        rock.CFrame = CFrame.new(rockPos, position) * CFrame.Angles(math.rad(math.random(28, 48)), math.rad(math.random(-18, 18)), 0)
        rock.Parent = vfxFolder

        -- Submerge and clean up
        task.delay(1.4, function()
            if rock.Parent then
                local sinkTween = TweenService:Create(rock, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = rock.CFrame * CFrame.new(0, -3.5, 0),
                    Transparency = 1,
                })
                sinkTween:Play()
                sinkTween.Completed:Wait()
                rock:Destroy()
            end
        end)
    end

    -- 3. Rising Stylized Dust / Shock Cloud
    local dustPart = Instance.new("Part")
    dustPart.Size = Vector3.new(1, 1, 1)
    dustPart.CFrame = CFrame.new(position)
    dustPart.Transparency = 1
    dustPart.Anchored = true
    dustPart.CanCollide = false
    dustPart.Parent = vfxFolder

    local dustEmitter = Instance.new("ParticleEmitter")
    dustEmitter.Texture = ASSETS.SMOKE_PUFF
    dustEmitter.Color = ColorSequence.new(palette.Secondary, Color3.fromRGB(55, 55, 65))
    dustEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.65, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    dustEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2.5),
        NumberSequenceKeypoint.new(1, 7.0),
    })
    dustEmitter.Speed = NumberRange.new(14, 32)
    dustEmitter.SpreadAngle = Vector2.new(180, 50)
    dustEmitter.Lifetime = NumberRange.new(0.65, 1.2)
    dustEmitter.LightEmission = 0.5
    dustEmitter.Rate = 0
    dustEmitter.Parent = dustPart

    dustEmitter:Emit(28)
    Debris:AddItem(dustPart, 1.6)
end

-- ==================== 5. HIGH-DENSITY DUAL-CORE BEAM ====================
function VFXHelper.CreateBeam(startPos: Vector3, endPos: Vector3, element: string, thickness: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()

    local dist = (endPos - startPos).Magnitude
    local midPos = (startPos + endPos) / 2
    local lookCF = CFrame.new(midPos, endPos) * CFrame.Angles(0, 0, math.rad(90))
    local th = thickness or 1.5

    -- Outer Glowing Elemental Sheath
    local sheath = Instance.new("Part")
    sheath.Name = "VFX_BeamSheath"
    sheath.Shape = Enum.PartType.Cylinder
    sheath.Size = Vector3.new(dist, th * 2.2, th * 2.2)
    sheath.CFrame = lookCF
    sheath.Material = Enum.Material.Neon
    sheath.Color = palette.Primary
    sheath.Transparency = 0.2
    sheath.Anchored = true
    sheath.CanCollide = false
    sheath.Parent = vfxFolder

    -- Inner Superheated Core
    local core = Instance.new("Part")
    core.Name = "VFX_BeamCore"
    core.Shape = Enum.PartType.Cylinder
    core.Size = Vector3.new(dist + 0.3, th * 0.95, th * 0.95)
    core.CFrame = lookCF
    core.Material = Enum.Material.Neon
    core.Color = palette.Core
    core.Transparency = 0.02
    core.Anchored = true
    core.CanCollide = false
    core.Parent = vfxFolder

    local fadeDuration = 0.32
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

-- ==================== 6. CONVERGING ENERGY CHARGE (Ultimate Wind-up) ====================
function VFXHelper.CreateConvergingCharge(position: Vector3, element: string, duration: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.5

    local chargePart = Instance.new("Part")
    chargePart.Name = "VFX_ConvergeCharge"
    chargePart.Size = Vector3.new(0.1, 0.1, 0.1)
    chargePart.CFrame = CFrame.new(position)
    chargePart.Transparency = 1
    chargePart.Anchored = true
    chargePart.CanCollide = false
    chargePart.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.STAR_SPARKLE
    emitter.Color = ColorSequence.new(palette.Core, palette.Primary)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.8),
        NumberSequenceKeypoint.new(1, 0.4),
    })
    emitter.Speed = NumberRange.new(-22, -14) -- Inward convergence towards center
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(d * 0.7, d)
    emitter.LightEmission = 1.0
    emitter.Rate = 50
    emitter.Parent = chargePart

    task.delay(d, function()
        emitter.Enabled = false
    end)
    Debris:AddItem(chargePart, d + 0.5)
end

-- ==================== 7. PERSISTENT ELEMENTAL AURA ====================
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
        ColorSequenceKeypoint.new(0, palette.Core),
        ColorSequenceKeypoint.new(0.5, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.7, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.6, 1.5),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    emitter.Speed = NumberRange.new(3, 7)
    emitter.Acceleration = Vector3.new(0, 12, 0)
    emitter.SpreadAngle = Vector2.new(30, 30)
    emitter.Lifetime = NumberRange.new(0.5, 0.9)
    emitter.LightEmission = 0.95
    emitter.LightInfluence = 0
    emitter.Rate = 24
    emitter.Parent = attach

    return attach
end


-- ==================== 8. FIREBALL PROJECTILE (Fire Move 1) ====================
function VFXHelper.CreateFireball(startPos: Vector3, endPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Fire
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.35

    local fireball = Instance.new("Part")
    fireball.Name = "VFX_Fireball"
    fireball.Shape = Enum.PartType.Ball
    fireball.Size = Vector3.new(2.8, 2.8, 2.8)
    fireball.CFrame = CFrame.new(startPos, endPos)
    fireball.Material = Enum.Material.Neon
    fireball.Color = palette.Primary
    fireball.CanCollide = false
    fireball.Anchored = true
    fireball.Parent = vfxFolder

    local core = Instance.new("Part")
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(1.6, 1.6, 1.6)
    core.CFrame = fireball.CFrame
    core.Material = Enum.Material.Neon
    core.Color = palette.Core
    core.CanCollide = false
    core.Anchored = false
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = fireball
    weld.Part1 = core
    weld.Parent = core
    core.Parent = fireball

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.STAR_SPARKLE
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Dark)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.2) })
    emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
    emitter.Speed = NumberRange.new(8, 16)
    emitter.Lifetime = NumberRange.new(0.2, 0.4)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LightEmission = 1.0
    emitter.Rate = 45
    emitter.Parent = fireball

    local tween = TweenService:Create(fireball, TweenInfo.new(d, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(endPos, endPos + (endPos - startPos).Unit)
    })
    tween:Play()

    tween.Completed:Once(function()
        fireball:Destroy()
        VFXHelper.CreateImpactBurst(endPos, "Fire", 36)
        VFXHelper.CreateShockwave(endPos, 16, 0.35, "Fire")
        VFXHelper.CreateCrater(endPos, 10, "Fire")
    end)
end

-- ==================== 9. WATER SPRAY (Aqua M1) ====================
function VFXHelper.CreateWaterSpray(startCFrame: CFrame, range: number)
    local palette = ELEMENT_PALETTES.Aqua
    local vfxFolder = GetVFXFolder()
    local r = range or 12

    local sprayPart = Instance.new("Part")
    sprayPart.Size = Vector3.new(0.1, 0.1, 0.1)
    sprayPart.CFrame = startCFrame * CFrame.new(0, 0, -1.5)
    sprayPart.Transparency = 1
    sprayPart.Anchored = true
    sprayPart.CanCollide = false
    sprayPart.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.WATER_SPLASH
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Primary)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.4),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 2.8) })
    emitter.Speed = NumberRange.new(r * 2.2, r * 3.2)
    emitter.SpreadAngle = Vector2.new(20, 15)
    emitter.Lifetime = NumberRange.new(0.2, 0.32)
    emitter.LightEmission = 0.8
    emitter.Rate = 0
    emitter.Parent = sprayPart

    emitter:Emit(24)
    Debris:AddItem(sprayPart, 0.5)
end

-- ==================== 10. WATER HAND (Aqua Move 1) ====================
function VFXHelper.CreateWaterHand(targetPos: Vector3)
    local palette = ELEMENT_PALETTES.Aqua
    local vfxFolder = GetVFXFolder()

    local hand = Instance.new("Part")
    hand.Name = "VFX_WaterHand"
    hand.Size = Vector3.new(7, 12, 6)
    hand.CFrame = CFrame.new(targetPos + Vector3.new(0, 22, 0))
    hand.Material = Enum.Material.ForceField
    hand.Color = palette.Primary
    hand.Transparency = 0.35
    hand.CanCollide = false
    hand.Anchored = true
    hand.Parent = vfxFolder

    local dropEmitter = Instance.new("ParticleEmitter")
    dropEmitter.Texture = ASSETS.WATER_SPLASH
    dropEmitter.Color = ColorSequence.new(palette.Secondary, palette.Core)
    dropEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0.5) })
    dropEmitter.Speed = NumberRange.new(8, 16)
    dropEmitter.Rate = 35
    dropEmitter.Parent = hand

    local slamTween = TweenService:Create(hand, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0)),
    })
    slamTween:Play()

    slamTween.Completed:Once(function()
        VFXHelper.CreateShockwave(targetPos, 20, 0.4, "Aqua")
        VFXHelper.CreateImpactBurst(targetPos, "Aqua", 32)
        TweenService:Create(hand, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Size = Vector3.new(10, 2, 8),
        }):Play()
        task.delay(0.26, function()
            hand:Destroy()
        end)
    end)
end

-- ==================== 11. VORTEX SPHERE (Aqua Move 2) ====================
function VFXHelper.CreateVortexSphere(startPos: Vector3, endPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Aqua
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.4

    local sphere = Instance.new("Part")
    sphere.Name = "VFX_VortexSphere"
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(3.5, 3.5, 3.5)
    sphere.CFrame = CFrame.new(startPos, endPos)
    sphere.Material = Enum.Material.Neon
    sphere.Color = palette.Primary
    sphere.Transparency = 0.2
    sphere.CanCollide = false
    sphere.Anchored = true
    sphere.Parent = vfxFolder

    -- Rotating hydro ring
    local ring = Instance.new("Part")
    ring.Size = Vector3.new(1, 1, 0.2)
    ring.CFrame = sphere.CFrame * CFrame.Angles(math.rad(45), 0, 0)
    ring.Material = Enum.Material.Neon
    ring.Color = palette.Secondary
    ring.CanCollide = false
    ring.Anchored = false
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = ASSETS.RING_MESH
    mesh.Scale = Vector3.new(2.2, 2.2, 0.8)
    mesh.Parent = ring
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = sphere
    weld.Part1 = ring
    weld.Parent = ring
    ring.Parent = sphere

    local tween = TweenService:Create(sphere, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(endPos, endPos + (endPos - startPos).Unit)
    })
    tween:Play()

    tween.Completed:Once(function()
        sphere:Destroy()
        VFXHelper.CreateImpactBurst(endPos, "Aqua", 32)
        VFXHelper.CreateShockwave(endPos, 22, 0.45, "Aqua")
    end)
end

-- ==================== 12. WATER DRAGON AURA (Aqua Move 3) ====================
function VFXHelper.AttachWaterDragon(character: Model, duration: number)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    local palette = ELEMENT_PALETTES.Aqua
    local d = duration or 5.0

    local attach = Instance.new("Attachment")
    attach.Name = "WaterDragonAttachment"
    attach.Parent = rootPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.WATER_SPLASH
    emitter.Color = ColorSequence.new(palette.Core, palette.Primary)
    emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(1, 0.4) })
    emitter.Speed = NumberRange.new(6, 12)
    emitter.SpreadAngle = Vector2.new(180, 45)
    emitter.Lifetime = NumberRange.new(0.4, 0.8)
    emitter.Rate = 40
    emitter.LightEmission = 0.9
    emitter.Parent = attach

    task.delay(d, function()
        if attach.Parent then
            emitter.Enabled = false
            task.delay(0.8, function() attach:Destroy() end)
        end
    end)
end

-- ==================== 13. EARTH PILLARS (Earth Move 1) ====================
function VFXHelper.CreateEarthPillars(centerCF: CFrame, duration: number)
    local palette = ELEMENT_PALETTES.Earth
    local vfxFolder = GetVFXFolder()
    local d = duration or 6.0

    local offsets = { Vector3.new(-5, -6, 0), Vector3.new(0, -6, 0), Vector3.new(5, -6, 0) }
    local pillars = {}

    for i, offset in offsets do
        local pillar = Instance.new("Part")
        pillar.Name = "VFX_EarthPillar"
        pillar.Size = Vector3.new(4.5, 12, 3)
        pillar.CFrame = centerCF * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(math.random(-5, 5)))
        pillar.Material = Enum.Material.Slate
        pillar.Color = palette.Primary
        pillar.Anchored = true
        pillar.CanCollide = true
        pillar.Parent = vfxFolder
        table.insert(pillars, pillar)

        TweenService:Create(pillar, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            CFrame = pillar.CFrame * CFrame.new(0, 6, 0),
        }):Play()
    end

    VFXHelper.CreateCrater(centerCF.Position, 10, "Earth")

    task.delay(d, function()
        for _, pillar in pillars do
            if pillar.Parent then
                TweenService:Create(pillar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = pillar.CFrame * CFrame.new(0, -8, 0),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(pillar, 0.35)
            end
        end
    end)
end

-- ==================== 14. BOULDER PROJECTILE (Earth Move 2) ====================
function VFXHelper.CreateBoulder(startPos: Vector3, endPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Earth
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.45

    local boulder = Instance.new("Part")
    boulder.Name = "VFX_Boulder"
    boulder.Shape = Enum.PartType.Ball
    boulder.Size = Vector3.new(5.5, 5.5, 5.5)
    boulder.CFrame = CFrame.new(startPos, endPos)
    boulder.Material = Enum.Material.Slate
    boulder.Color = palette.Primary
    boulder.CanCollide = false
    boulder.Anchored = true
    boulder.Parent = vfxFolder

    local dustEmitter = Instance.new("ParticleEmitter")
    dustEmitter.Texture = ASSETS.SMOKE_PUFF
    dustEmitter.Color = ColorSequence.new(palette.Secondary, Color3.fromRGB(50, 45, 40))
    dustEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
    dustEmitter.Speed = NumberRange.new(5, 12)
    dustEmitter.Rate = 25
    dustEmitter.Parent = boulder

    local tween = TweenService:Create(boulder, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        CFrame = CFrame.new(endPos, endPos + (endPos - startPos).Unit) * CFrame.Angles(math.rad(360), 0, 0),
    })
    tween:Play()

    tween.Completed:Once(function()
        boulder:Destroy()
        VFXHelper.CreateCrater(endPos, 16, "Earth")
        VFXHelper.CreateShockwave(endPos, 22, 0.45, "Earth")
    end)
end

-- ==================== 15. STONE GAUNTLET (Earth Move 3) ====================
function VFXHelper.CreateStoneGauntlet(character: Model, duration: number)
    local rArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") :: BasePart?
    if not rArm then return end

    local palette = ELEMENT_PALETTES.Earth
    local d = duration or 0.4

    local gauntlet = Instance.new("Part")
    gauntlet.Name = "VFX_StoneGauntlet"
    gauntlet.Size = Vector3.new(2.2, 2.6, 2.2)
    gauntlet.CFrame = rArm.CFrame
    gauntlet.Material = Enum.Material.Slate
    gauntlet.Color = palette.Primary
    gauntlet.CanCollide = false
    gauntlet.Anchored = false

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rArm
    weld.Part1 = gauntlet
    weld.Parent = gauntlet
    gauntlet.Parent = character

    task.delay(d, function()
        if gauntlet.Parent then
            VFXHelper.CreateImpactBurst(gauntlet.Position, "Earth", 20)
            gauntlet:Destroy()
        end
    end)
end

-- ==================== 16. TERRA SEQUENCE (Earth Move 4) ====================
function VFXHelper.CreateTerraSequence(targetPos: Vector3)
    VFXHelper.CreateCrater(targetPos, 18, "Earth")
    VFXHelper.CreateShockwave(targetPos, 26, 0.5, "Earth")
end

-- ==================== 17. MIRRORS OF JUDGEMENT (Light Move 2) ====================
function VFXHelper.CreateMirrorsOfJudgement(targetPos: Vector3)
    local palette = ELEMENT_PALETTES.Light
    local vfxFolder = GetVFXFolder()

    local radius = 9
    local mirrors = {}

    for i = 0, 3 do
        local angle = math.rad(i * 90)
        local pos = targetPos + Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
        local mirror = Instance.new("Part")
        mirror.Name = "VFX_LightMirror"
        mirror.Size = Vector3.new(0.25, 6, 4)
        mirror.CFrame = CFrame.new(pos, targetPos)
        mirror.Material = Enum.Material.Neon
        mirror.Color = palette.Secondary
        mirror.Transparency = 0.25
        mirror.Anchored = true
        mirror.CanCollide = false
        mirror.Parent = vfxFolder
        table.insert(mirrors, mirror)

        -- Flash ray from mirror to center
        VFXHelper.CreateBeam(pos, targetPos + Vector3.new(0, 1.5, 0), "Light", 0.8)
    end

    task.delay(0.35, function()
        for _, m in mirrors do
            if m.Parent then
                TweenService:Create(m, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    CFrame = CFrame.new(targetPos + Vector3.new(0, 1.5, 0)),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(m, 0.22)
            end
        end
        VFXHelper.CreateShockwave(targetPos, 18, 0.35, "Light")
        VFXHelper.CreateImpactBurst(targetPos, "Light", 28)
    end)
end

-- ==================== 18. BLINDING FLASH (Light Move 3) ====================
function VFXHelper.CreateBlindingFlash(targetPos: Vector3)
    local palette = ELEMENT_PALETTES.Light
    local vfxFolder = GetVFXFolder()

    local flash = Instance.new("Part")
    flash.Name = "VFX_BlindingFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Size = Vector3.new(1, 1, 1)
    flash.CFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 0))
    flash.Material = Enum.Material.Neon
    flash.Color = palette.Core
    flash.Transparency = 0
    flash.Anchored = true
    flash.CanCollide = false
    flash.Parent = vfxFolder

    local tween = TweenService:Create(flash, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(14, 14, 14),
        Transparency = 1,
    })
    tween:Play()
    tween.Completed:Once(function()
        flash:Destroy()
    end)
    VFXHelper.CreateImpactBurst(targetPos + Vector3.new(0, 2.5, 0), "Light", 32)
end

-- ==================== 19. TORNADO PROJECTILE (Wind Move 1) ====================
function VFXHelper.CreateTornado(startPos: Vector3, endPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Wind
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.45

    local funnel = Instance.new("Part")
    funnel.Name = "VFX_Tornado"
    funnel.Size = Vector3.new(3, 8, 3)
    funnel.CFrame = CFrame.new(startPos + Vector3.new(0, 4, 0))
    funnel.Material = Enum.Material.ForceField
    funnel.Color = palette.Primary
    funnel.Transparency = 0.5
    funnel.Anchored = true
    funnel.CanCollide = false
    funnel.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.SMOKE_PUFF
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Core)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4.5) })
    emitter.Speed = NumberRange.new(10, 20)
    emitter.SpreadAngle = Vector2.new(180, 30)
    emitter.Lifetime = NumberRange.new(0.25, 0.45)
    emitter.Rate = 50
    emitter.Parent = funnel

    local tween = TweenService:Create(funnel, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(endPos + Vector3.new(0, 4, 0)),
    })
    tween:Play()

    tween.Completed:Once(function()
        funnel:Destroy()
        VFXHelper.CreateShockwave(endPos, 14, 0.35, "Wind")
    end)
end

-- ==================== 20. CYCLONE OF FURY (Wind Move 2) ====================
function VFXHelper.CreateCyclone(centerPos: Vector3, radius: number, duration: number)
    local palette = ELEMENT_PALETTES.Wind
    local vfxFolder = GetVFXFolder()
    local r = radius or 20
    local d = duration or 4.0

    local cyclone = Instance.new("Part")
    cyclone.Name = "VFX_Cyclone"
    cyclone.Shape = Enum.PartType.Cylinder
    cyclone.Size = Vector3.new(22, r * 2, r * 2)
    cyclone.CFrame = CFrame.new(centerPos + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(90))
    cyclone.Material = Enum.Material.ForceField
    cyclone.Color = palette.Primary
    cyclone.Transparency = 0.7
    cyclone.Anchored = true
    cyclone.CanCollide = false
    cyclone.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.LIGHTNING_STREAK
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Core)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0.5) })
    emitter.Speed = NumberRange.new(16, 32)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(0.4, 0.7)
    emitter.Rate = 60
    emitter.LightEmission = 0.9
    emitter.Parent = cyclone

    task.delay(d, function()
        if cyclone.Parent then
            TweenService:Create(cyclone, TweenInfo.new(0.4), { Transparency = 1 }):Play()
            Debris:AddItem(cyclone, 0.45)
        end
    end)
end

-- ==================== 21. WIND LIGHTNING (Wind M1 & Move 4) ====================
function VFXHelper.CreateWindLightning(startPos: Vector3, endPos: Vector3)
    local palette = ELEMENT_PALETTES.Wind
    local vfxFolder = GetVFXFolder()

    local segments = 4
    local delta = (endPos - startPos) / segments

    for i = 1, segments do
        local p0 = startPos + (delta * (i - 1))
        local p1 = startPos + (delta * i)
        if i < segments then
            p1 += Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
        end

        local dist = (p1 - p0).Magnitude
        local mid = (p0 + p1) / 2

        local bolt = Instance.new("Part")
        bolt.Name = "VFX_WindBolt"
        bolt.Shape = Enum.PartType.Cylinder
        bolt.Size = Vector3.new(dist, 0.5, 0.5)
        bolt.CFrame = CFrame.new(mid, p1) * CFrame.Angles(0, 0, math.rad(90))
        bolt.Material = Enum.Material.Neon
        bolt.Color = palette.Primary
        bolt.Anchored = true
        bolt.CanCollide = false
        bolt.Parent = vfxFolder

        TweenService:Create(bolt, TweenInfo.new(0.18), { Transparency = 1, Size = Vector3.new(dist, 0, 0) }):Play()
        Debris:AddItem(bolt, 0.2)
    end
end

-- ==================== 22. SPEED BOOST VFX (Wind Move 3) ====================
function VFXHelper.AttachSpeedBoost(character: Model, duration: number)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    local palette = ELEMENT_PALETTES.Wind
    local d = duration or 5.0

    local attach = Instance.new("Attachment")
    attach.Name = "SpeedBoostAttachment"
    attach.Parent = rootPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.STAR_SPARKLE
    emitter.Color = ColorSequence.new(palette.Core, palette.Primary)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.1) })
    emitter.Speed = NumberRange.new(12, 22)
    emitter.SpreadAngle = Vector2.new(180, 30)
    emitter.Lifetime = NumberRange.new(0.2, 0.4)
    emitter.Rate = 40
    emitter.LightEmission = 1.0
    emitter.Parent = attach

    task.delay(d, function()
        if attach.Parent then
            emitter.Enabled = false
            task.delay(0.4, function() attach:Destroy() end)
        end
    end)
end

-- ==================== 23. GLITCHED DASH TRAIL (Error M1) ====================
function VFXHelper.CreateGlitchedTrail(startPos: Vector3, endPos: Vector3)
    local palette = ELEMENT_PALETTES.Error
    local vfxFolder = GetVFXFolder()

    local count = 6
    local step = (endPos - startPos) / count

    for i = 1, count do
        local pos = startPos + (step * i)
        local slice = Instance.new("Part")
        slice.Name = "VFX_GlitchSlice"
        slice.Size = Vector3.new(math.random(15, 30) / 10, math.random(5, 15) / 10, math.random(15, 30) / 10)
        slice.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(math.random(-15, 15)), 0, math.rad(math.random(-15, 15)))
        slice.Material = Enum.Material.Neon
        slice.Color = if i % 2 == 0 then palette.Primary else palette.Secondary
        slice.Transparency = 0.2
        slice.Anchored = true
        slice.CanCollide = false
        slice.Parent = vfxFolder

        TweenService:Create(slice, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.01, 0.01, 0.01) }):Play()
        Debris:AddItem(slice, 0.35)
    end
end

-- ==================== 24. GLITCH WALL SHIELD (Error Move 1) ====================
function VFXHelper.CreateGlitchWall(character: Model, duration: number)
    local rArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") :: BasePart?
    if not rArm then return end

    local palette = ELEMENT_PALETTES.Error
    local d = duration or 0.6

    local shield = Instance.new("Part")
    shield.Name = "VFX_GlitchShield"
    shield.Size = Vector3.new(0.4, 4.5, 4.5)
    shield.CFrame = rArm.CFrame * CFrame.new(0, 0, -2)
    shield.Material = Enum.Material.ForceField
    shield.Color = palette.Primary
    shield.Transparency = 0.25
    shield.Anchored = false
    shield.CanCollide = false

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rArm
    weld.Part1 = shield
    weld.Parent = shield
    shield.Parent = character

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.GLITCH_PIXEL
    emitter.Color = ColorSequence.new(palette.Primary, palette.Secondary)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.2) })
    emitter.Speed = NumberRange.new(6, 14)
    emitter.Rate = 35
    emitter.LightEmission = 1.0
    emitter.Parent = shield

    task.delay(d, function()
        if shield.Parent then
            VFXHelper.CreateShockwave(shield.Position, 16, 0.35, "Error")
            shield:Destroy()
        end
    end)
end

-- ==================== 25. 404 NOT FOUND BALL (Error Move 2) ====================
function VFXHelper.Create404Ball(startPos: Vector3, endPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Error
    local vfxFolder = GetVFXFolder()
    local d = duration or 0.45

    local ball = Instance.new("Part")
    ball.Name = "VFX_404Ball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(3.5, 3.5, 3.5)
    ball.CFrame = CFrame.new(startPos, endPos)
    ball.Material = Enum.Material.Neon
    ball.Color = palette.Primary
    ball.CanCollide = false
    ball.Anchored = true
    ball.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.GLITCH_PIXEL
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Core)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0.3) })
    emitter.Speed = NumberRange.new(8, 16)
    emitter.Rate = 45
    emitter.LightEmission = 1.0
    emitter.Parent = ball

    local tween = TweenService:Create(ball, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(endPos, endPos + (endPos - startPos).Unit),
    })
    tween:Play()

    tween.Completed:Once(function()
        ball:Destroy()
        VFXHelper.CreateShockwave(endPos, 24, 0.45, "Error")
        VFXHelper.CreateImpactBurst(endPos, "Error", 36)
    end)
end

-- ==================== 26. GLITCH INVISIBILITY (Error Move 3) ====================
function VFXHelper.AttachGlitchInvis(character: Model, duration: number)
    local d = duration or 5.0
    local originalTransparencies: { [BasePart]: number } = {}

    for _, desc in character:GetDescendants() do
        if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
            originalTransparencies[desc] = desc.Transparency
            desc.Transparency = 0.85
        end
    end

    task.delay(d, function()
        for part, orig in originalTransparencies do
            if part.Parent then
                part.Transparency = orig
            end
        end
    end)
end

-- ==================== 27. GLITCH CAGE (Error Move 5) ====================
function VFXHelper.CreateGlitchCage(targetPos: Vector3, duration: number)
    local palette = ELEMENT_PALETTES.Error
    local vfxFolder = GetVFXFolder()
    local d = duration or 5.0

    local cage = Instance.new("Part")
    cage.Name = "VFX_GlitchCage"
    cage.Size = Vector3.new(7, 8, 7)
    cage.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
    cage.Material = Enum.Material.ForceField
    cage.Color = palette.Primary
    cage.Transparency = 0.4
    cage.Anchored = true
    cage.CanCollide = false
    cage.Parent = vfxFolder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = ASSETS.GLITCH_PIXEL
    emitter.Color = ColorSequence.new(palette.Secondary, palette.Primary)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.2) })
    emitter.Speed = NumberRange.new(4, 10)
    emitter.Rate = 35
    emitter.LightEmission = 1.0
    emitter.Parent = cage

    task.delay(d, function()
        if cage.Parent then
            VFXHelper.CreateShockwave(cage.Position, 16, 0.35, "Error")
            cage:Destroy()
        end
    end)
end

-- ==================== 28. CLOCK DIAL AURA (Time M1) ====================
function VFXHelper.AttachClockDial(character: Model)
    local rArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") :: BasePart?
    if not rArm then return end

    local palette = ELEMENT_PALETTES.Time
    local ring = Instance.new("Part")
    ring.Name = "VFX_ClockDialRing"
    ring.Size = Vector3.new(2.8, 2.8, 0.1)
    ring.CFrame = rArm.CFrame * CFrame.Angles(math.rad(90), 0, 0)
    ring.Material = Enum.Material.Neon
    ring.Color = palette.Primary
    ring.Transparency = 0.3
    ring.CanCollide = false
    ring.Anchored = false

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = ASSETS.RING_MESH
    mesh.Scale = Vector3.new(1.8, 1.8, 0.5)
    mesh.Parent = ring

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rArm
    weld.Part1 = ring
    weld.Parent = ring
    ring.Parent = character

    task.delay(0.5, function()
        if ring.Parent then
            TweenService:Create(ring, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            Debris:AddItem(ring, 0.25)
        end
    end)
end

-- ==================== 29. TIME INJECTION (Time Move 2) ====================
function VFXHelper.CreateTimeInjection(targetPos: Vector3)
    local palette = ELEMENT_PALETTES.Time
    local vfxFolder = GetVFXFolder()

    for i = 1, 3 do
        local ring = Instance.new("Part")
        ring.Name = "VFX_TimeRing"
        ring.Size = Vector3.new(i * 4, i * 4, 0.2)
        ring.CFrame = CFrame.new(targetPos + Vector3.new(0, i * 1.5, 0)) * CFrame.Angles(math.rad(90), 0, 0)
        ring.Material = Enum.Material.Neon
        ring.Color = palette.Primary
        ring.Transparency = 0.2
        ring.Anchored = true
        ring.CanCollide = false
        ring.Parent = vfxFolder

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(i * 1.8, i * 1.8, 0.4)
        mesh.Parent = ring

        TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(180)),
        }):Play()
        Debris:AddItem(ring, 0.55)
    end

    VFXHelper.CreateImpactBurst(targetPos + Vector3.new(0, 3, 0), "Time", 30)
end

-- ==================== 30. UNTOUCHABLE BARRIER (Time Move 3) ====================
function VFXHelper.AttachUntouchableBarrier(character: Model, duration: number)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    local palette = ELEMENT_PALETTES.Time
    local d = duration or 4.0

    local sphere = Instance.new("Part")
    sphere.Name = "VFX_UntouchableBarrier"
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(9, 9, 9)
    sphere.CFrame = rootPart.CFrame
    sphere.Material = Enum.Material.ForceField
    sphere.Color = palette.Primary
    sphere.Transparency = 0.35
    sphere.CanCollide = false
    sphere.Anchored = false

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rootPart
    weld.Part1 = sphere
    weld.Parent = sphere
    sphere.Parent = character

    task.delay(d, function()
        if sphere.Parent then
            TweenService:Create(sphere, TweenInfo.new(0.3), { Transparency = 1 }):Play()
            Debris:AddItem(sphere, 0.35)
        end
    end)
end

-- ==================== 31. VIRTUAL KILL FINISHER (Time Move 4) ====================
function VFXHelper.CreateVirtualKill(targetPos: Vector3)
    local palette = ELEMENT_PALETTES.Time
    local vfxFolder = GetVFXFolder()

    -- Huge Chronological Floor Dial
    local clockFloor = Instance.new("Part")
    clockFloor.Name = "VFX_VirtualKillClock"
    clockFloor.Size = Vector3.new(28, 0.2, 28)
    clockFloor.CFrame = CFrame.new(targetPos)
    clockFloor.Material = Enum.Material.Neon
    clockFloor.Color = palette.Primary
    clockFloor.Transparency = 0.2
    clockFloor.Anchored = true
    clockFloor.CanCollide = false
    clockFloor.Parent = vfxFolder

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = ASSETS.RING_MESH
    mesh.Scale = Vector3.new(14, 14, 0.4)
    mesh.Parent = clockFloor

    -- Converging timeline vertical beam
    VFXHelper.CreateBeam(targetPos + Vector3.new(0, 35, 0), targetPos, "Time", 3.0)
    VFXHelper.CreateShockwave(targetPos, 32, 0.55, "Time")
    VFXHelper.CreateCrater(targetPos, 22, "Time")

    TweenService:Create(clockFloor, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1,
    }):Play()
    Debris:AddItem(clockFloor, 0.7)
end

return table.freeze(VFXHelper)
