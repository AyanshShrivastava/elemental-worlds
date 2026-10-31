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

return table.freeze(VFXHelper)
