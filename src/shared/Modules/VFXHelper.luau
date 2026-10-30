--!strict
--[[
    Elemental Worlds: Master VFX Helper Module
    Creates rich procedural visual effects: Elemental Auras, Expanding Shockwaves,
    Particle Emitters with curated ColorSequences, Ground Craters, and Beams.
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFXHelper = {}

-- Curated ColorSequences for each Element
local ELEMENT_PALETTES = {
    Fire = {
        Primary = Color3.fromRGB(255, 80, 20),
        Secondary = Color3.fromRGB(255, 200, 30),
        Dark = Color3.fromRGB(180, 20, 0),
    },
    Aqua = {
        Primary = Color3.fromRGB(30, 160, 255),
        Secondary = Color3.fromRGB(150, 230, 255),
        Dark = Color3.fromRGB(10, 80, 180),
    },
    Earth = {
        Primary = Color3.fromRGB(140, 95, 50),
        Secondary = Color3.fromRGB(200, 160, 100),
        Dark = Color3.fromRGB(80, 50, 20),
    },
    Light = {
        Primary = Color3.fromRGB(255, 240, 100),
        Secondary = Color3.fromRGB(255, 255, 255),
        Dark = Color3.fromRGB(230, 180, 30),
    },
    Wind = {
        Primary = Color3.fromRGB(120, 255, 180),
        Secondary = Color3.fromRGB(200, 255, 230),
        Dark = Color3.fromRGB(50, 180, 120),
    },
    Error = {
        Primary = Color3.fromRGB(255, 0, 128),
        Secondary = Color3.fromRGB(0, 255, 255),
        Dark = Color3.fromRGB(100, 0, 80),
    },
    Time = {
        Primary = Color3.fromRGB(60, 130, 255),
        Secondary = Color3.fromRGB(210, 230, 255),
        Dark = Color3.fromRGB(20, 40, 140),
    },
}

-- Creates a dynamic expanding shockwave ring
function VFXHelper.CreateShockwave(position: Vector3, maxRadius: number, duration: number, element: string)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire

    local ring = Instance.new("Part")
    ring.Name = "VFX_Shockwave"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.5, 2, 2)
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Material = Enum.Material.Neon
    ring.Color = palette.Primary
    ring.Transparency = 0.2
    ring.CanCollide = false
    ring.Anchored = true
    ring.Parent = Workspace:FindFirstChild("VFX") or Workspace

    local targetSize = Vector3.new(0.1, maxRadius * 2, maxRadius * 2)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local tween = TweenService:Create(ring, tweenInfo, {
        Size = targetSize,
        Transparency = 1,
    })
    tween:Play()

    Debris:AddItem(ring, duration + 0.1)
end

-- Spawns an explosion of elemental particles at position
function VFXHelper.CreateImpactBurst(position: Vector3, element: string, particleCount: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire

    local emitterPart = Instance.new("Part")
    emitterPart.Name = "VFX_ImpactPart"
    emitterPart.Size = Vector3.new(1, 1, 1)
    emitterPart.CFrame = CFrame.new(position)
    emitterPart.Transparency = 1
    emitterPart.CanCollide = false
    emitterPart.Anchored = true
    emitterPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    -- Radial Spark Emitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Sparks"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.Secondary),
        ColorSequenceKeypoint.new(0.6, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.2),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Speed = NumberRange.new(18, 38)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(0.35, 0.7)
    emitter.LightEmission = 1.0
    emitter.LightInfluence = 0
    emitter.Rate = 0
    emitter.Parent = emitterPart

    -- Point Light flash
    local flash = Instance.new("PointLight")
    flash.Color = palette.Primary
    flash.Range = 22
    flash.Brightness = 4
    flash.Parent = emitterPart

    local flashTween = TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 0,
    })
    flashTween:Play()

    emitter:Emit(particleCount or 35)
    Debris:AddItem(emitterPart, 1.0)
end

-- Attaches a persistent anime elemental aura around a character's root
function VFXHelper.AttachElementalAura(character: Model, element: string): Attachment?
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return nil end

    -- Remove any existing aura
    local existing = rootPart:FindFirstChild("ElementalAuraAttachment")
    if existing then existing:Destroy() end

    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire
    local attach = Instance.new("Attachment")
    attach.Name = "ElementalAuraAttachment"
    attach.Parent = rootPart

    -- Aura Flames / energy wisps
    local auraEmitter = Instance.new("ParticleEmitter")
    auraEmitter.Name = "AuraEnergy"
    auraEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.Secondary),
        ColorSequenceKeypoint.new(0.5, palette.Primary),
        ColorSequenceKeypoint.new(1, palette.Dark),
    })
    auraEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    auraEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(0.5, 2.5),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    auraEmitter.Speed = NumberRange.new(2, 5)
    auraEmitter.Acceleration = Vector3.new(0, 8, 0)
    auraEmitter.SpreadAngle = Vector2.new(35, 35)
    auraEmitter.Lifetime = NumberRange.new(0.6, 1.0)
    auraEmitter.LightEmission = 0.85
    auraEmitter.LightInfluence = 0
    auraEmitter.Rate = 25
    auraEmitter.Parent = attach

    return attach
end

-- Creates an anime slash arc in front of the caster
function VFXHelper.CreateSlashArc(cframe: CFrame, element: string, scale: number)
    local palette = ELEMENT_PALETTES[element] or ELEMENT_PALETTES.Fire

    local slashPart = Instance.new("Part")
    slashPart.Name = "VFX_SlashArc"
    slashPart.Size = Vector3.new(6 * scale, 0.2, 5 * scale)
    slashPart.CFrame = cframe * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(math.random(-25, 25)), 0)
    slashPart.Material = Enum.Material.Neon
    slashPart.Color = palette.Secondary
    slashPart.Transparency = 0.1
    slashPart.CanCollide = false
    slashPart.Anchored = true
    slashPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    local tween = TweenService:Create(slashPart, TweenInfo.new(0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = Vector3.new(10 * scale, 0.1, 8 * scale),
        Transparency = 1,
        CFrame = slashPart.CFrame * CFrame.new(0, 0, -2),
    })
    tween:Play()
    Debris:AddItem(slashPart, 0.25)
end

return table.freeze(VFXHelper)
