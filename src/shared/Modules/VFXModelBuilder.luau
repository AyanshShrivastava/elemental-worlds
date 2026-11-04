--!strict
--[[
    Elemental Worlds: Master VFX Model Builder
    Constructs high-fidelity, polished anime-style reusable Model templates
    for all 36 abilities inside ReplicatedStorage.VFX.<Element>.<AssetName>.

    Design Standards:
    - Clean, cartoonish anime aesthetic (bold silhouettes, bright cores, smooth shapes)
    - Well-layered (cores, halos, attachments, particle emitters, lights)
    - Fully anchored, non-collidable, non-interactive (pure visual models)
    - Categorized into element subfolders
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFXModelBuilder = {}

-- Real Verified Roblox Creator Store Asset IDs for Textures and Meshes
local ASSETS = {
    SLASH_TEXTURE     = "rbxassetid://4991873131", -- Anime crescent curve
    STAR_SPARKLE      = "rbxassetid://6034177218", -- Crisp anime 4-point star
    SMOKE_PUFF        = "rbxassetid://2520762076", -- Stylized dust / smoke
    LIGHTNING_STREAK  = "rbxassetid://446111271",  -- Electric discharge streak
    RING_MESH         = "rbxassetid://3270017",    -- Torus / Ring mesh
    ROCK_MESH         = "rbxassetid://1290033",    -- Rock fragment mesh
}

local function EnsureFolder(parent: Instance, name: string): Folder
    local folder = parent:FindFirstChild(name) :: Folder?
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder :: Folder
end

local function CreateBasePart(name: string, size: Vector3, color: Color3, material: Enum.Material?, transparency: number?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.Neon
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    return part
end

local function AddPointLight(parent: Instance, color: Color3, brightness: number, range: number): PointLight
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Parent = parent
    return light
end

-- ==================== BUILDERS FOR ALL 36 ABILITIES ====================

-- ----------------- FIRE (5 Abilities) -----------------
local function BuildFireModels(folder: Folder)
    -- 1. Fire_M1_FlameDagger
    do
        local model = Instance.new("Model")
        model.Name = "Fire_M1_FlameDagger"
        
        local blade = CreateBasePart("Blade", Vector3.new(0.3, 2.4, 0.6), Color3.fromRGB(255, 120, 20), Enum.Material.Neon)
        local hilt = CreateBasePart("Hilt", Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(45, 20, 15), Enum.Material.SmoothPlastic)
        hilt.CFrame = blade.CFrame * CFrame.new(0, -1.5, 0)
        
        local coreGlow = CreateBasePart("CoreGlow", Vector3.new(0.15, 2.0, 0.35), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
        coreGlow.CFrame = blade.CFrame
        
        local flameEmitter = Instance.new("ParticleEmitter")
        flameEmitter.Name = "FlameTrail"
        flameEmitter.Texture = ASSETS.SLASH_TEXTURE
        flameEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 180)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 130, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 25, 10)),
        })
        flameEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.1),
        })
        flameEmitter.Lifetime = NumberRange.new(0.2, 0.35)
        flameEmitter.Rate = 25
        flameEmitter.Speed = NumberRange.new(2, 6)
        flameEmitter.LightEmission = 0.85
        flameEmitter.Parent = blade
        
        blade.Parent = model
        hilt.Parent = model
        coreGlow.Parent = model
        model.PrimaryPart = blade
        model.Parent = folder
    end

    -- 2. Fire_Move1_ScorchingFireball
    do
        local model = Instance.new("Model")
        model.Name = "Fire_Move1_ScorchingFireball"

        local core = CreateBasePart("Core", Vector3.new(3.0, 3.0, 3.0), Color3.fromRGB(255, 245, 210), Enum.Material.Neon)
        core.Shape = Enum.PartType.Ball

        local outerFlames = CreateBasePart("OuterFlames", Vector3.new(4.2, 4.2, 4.2), Color3.fromRGB(255, 95, 15), Enum.Material.Neon, 0.35)
        outerFlames.Shape = Enum.PartType.Ball
        outerFlames.CFrame = core.CFrame

        local emberEmitter = Instance.new("ParticleEmitter")
        emberEmitter.Name = "Embers"
        emberEmitter.Texture = ASSETS.STAR_SPARKLE
        emberEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 0))
        emberEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(1, 0),
        })
        emberEmitter.Lifetime = NumberRange.new(0.3, 0.6)
        emberEmitter.Rate = 45
        emberEmitter.Speed = NumberRange.new(4, 12)
        emberEmitter.SpreadAngle = Vector2.new(180, 180)
        emberEmitter.LightEmission = 1.0
        emberEmitter.Parent = core

        AddPointLight(core, Color3.fromRGB(255, 140, 30), 4, 18)

        core.Parent = model
        outerFlames.Parent = model
        model.PrimaryPart = core
        model.Parent = folder
    end

    -- 3. Fire_Move2_InfernalBeast
    do
        local model = Instance.new("Model")
        model.Name = "Fire_Move2_InfernalBeast"

        local body = CreateBasePart("BeastBody", Vector3.new(2.4, 2.0, 3.2), Color3.fromRGB(180, 40, 15), Enum.Material.Slate)
        local head = CreateBasePart("BeastHead", Vector3.new(1.8, 1.6, 1.8), Color3.fromRGB(220, 60, 20), Enum.Material.Neon)
        head.CFrame = body.CFrame * CFrame.new(0, 0.8, -2.0)

        local eyeL = CreateBasePart("EyeL", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 255, 150), Enum.Material.Neon)
        eyeL.CFrame = head.CFrame * CFrame.new(-0.5, 0.2, -0.9)
        local eyeR = CreateBasePart("EyeR", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 255, 150), Enum.Material.Neon)
        eyeR.CFrame = head.CFrame * CFrame.new(0.5, 0.2, -0.9)

        local aura = Instance.new("ParticleEmitter")
        aura.Name = "BeastFlames"
        aura.Texture = ASSETS.SLASH_TEXTURE
        aura.Color = ColorSequence.new(Color3.fromRGB(255, 180, 40), Color3.fromRGB(200, 30, 10))
        aura.Size = NumberSequence.new(1.2, 0.2)
        aura.Lifetime = NumberRange.new(0.4, 0.7)
        aura.Rate = 20
        aura.Speed = NumberRange.new(3, 8)
        aura.Parent = body

        body.Parent = model
        head.Parent = model
        eyeL.Parent = model
        eyeR.Parent = model
        model.PrimaryPart = body
        model.Parent = folder
    end

    -- 4. Fire_Move3_FlamesOfFury
    do
        local model = Instance.new("Model")
        model.Name = "Fire_Move3_FlamesOfFury"

        local root = CreateBasePart("OriginRing", Vector3.new(1, 1, 1), Color3.fromRGB(255, 120, 20), Enum.Material.Neon, 1)
        
        local ringMesh = Instance.new("SpecialMesh")
        ringMesh.MeshId = ASSETS.RING_MESH
        ringMesh.Scale = Vector3.new(5, 5, 0.6)
        ringMesh.Parent = root

        local beamCore = CreateBasePart("BeamCore", Vector3.new(1.4, 1.4, 12), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
        beamCore.CFrame = root.CFrame * CFrame.new(0, 0, -6)

        local beamOuter = CreateBasePart("BeamOuter", Vector3.new(2.4, 2.4, 12), Color3.fromRGB(255, 90, 15), Enum.Material.Neon, 0.4)
        beamOuter.CFrame = beamCore.CFrame

        root.Parent = model
        beamCore.Parent = model
        beamOuter.Parent = model
        model.PrimaryPart = root
        model.Parent = folder
    end

    -- 5. Fire_Move4_InfernalJudgement
    do
        local model = Instance.new("Model")
        model.Name = "Fire_Move4_InfernalJudgement"

        local center = CreateBasePart("DomainCenter", Vector3.new(1, 1, 1), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, 1)

        -- 35-stud domain perimeter boundary ring
        local perimeter = CreateBasePart("PerimeterRing", Vector3.new(1, 1, 1), Color3.fromRGB(255, 80, 10), Enum.Material.Neon)
        local ringMesh = Instance.new("SpecialMesh")
        ringMesh.MeshId = ASSETS.RING_MESH
        ringMesh.Scale = Vector3.new(35, 35, 1.2)
        ringMesh.Parent = perimeter
        perimeter.CFrame = center.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        -- 4 rising flame pillar markers at cardinal directions
        local pillarOffsets = {
            Vector3.new(16, 8, 0),
            Vector3.new(-16, 8, 0),
            Vector3.new(0, 8, 16),
            Vector3.new(0, 8, -16),
        }
        for idx, offset in ipairs(pillarOffsets) do
            local pillar = CreateBasePart("FlamePillar_" .. idx, Vector3.new(2.2, 16, 2.2), Color3.fromRGB(255, 120, 25), Enum.Material.Neon, 0.2)
            pillar.CFrame = center.CFrame * CFrame.new(offset)
            pillar.Parent = model
        end

        center.Parent = model
        perimeter.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end
end

-- ----------------- AQUA (5 Abilities) -----------------
local function BuildAquaModels(folder: Folder)
    -- 6. Aqua_M1_Water
    do
        local model = Instance.new("Model")
        model.Name = "Aqua_M1_Water"

        local coreStream = CreateBasePart("WaterStream", Vector3.new(0.6, 0.6, 6.0), Color3.fromRGB(80, 220, 255), Enum.Material.Neon, 0.2)
        local outerWater = CreateBasePart("OuterWater", Vector3.new(1.2, 1.2, 6.0), Color3.fromRGB(0, 150, 240), Enum.Material.Glass, 0.4)
        outerWater.CFrame = coreStream.CFrame

        local dropletEmitter = Instance.new("ParticleEmitter")
        dropletEmitter.Name = "Droplets"
        dropletEmitter.Texture = ASSETS.SMOKE_PUFF
        dropletEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 245, 255), Color3.fromRGB(0, 170, 255))
        dropletEmitter.Size = NumberSequence.new(0.5, 0.05)
        dropletEmitter.Lifetime = NumberRange.new(0.2, 0.4)
        dropletEmitter.Rate = 30
        dropletEmitter.Speed = NumberRange.new(5, 15)
        dropletEmitter.Parent = coreStream

        coreStream.Parent = model
        outerWater.Parent = model
        model.PrimaryPart = coreStream
        model.Parent = folder
    end

    -- 7. Aqua_Move1_WaterHand
    do
        local model = Instance.new("Model")
        model.Name = "Aqua_Move1_WaterHand"

        local palm = CreateBasePart("WaterPalm", Vector3.new(4.5, 1.8, 5.0), Color3.fromRGB(20, 180, 255), Enum.Material.Glass, 0.25)
        
        -- 4 Translucent water fingers
        for i = 1, 4 do
            local finger = CreateBasePart("Finger_" .. i, Vector3.new(0.9, 1.2, 3.2), Color3.fromRGB(60, 210, 255), Enum.Material.Glass, 0.25)
            finger.CFrame = palm.CFrame * CFrame.new((i - 2.5) * 1.1, 0, -3.2)
            finger.Parent = model
        end

        local splashEmitter = Instance.new("ParticleEmitter")
        splashEmitter.Name = "HandSplash"
        splashEmitter.Texture = ASSETS.SMOKE_PUFF
        splashEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 245, 255), Color3.fromRGB(40, 160, 255))
        splashEmitter.Size = NumberSequence.new(1.5, 0.1)
        splashEmitter.Lifetime = NumberRange.new(0.3, 0.6)
        splashEmitter.Rate = 25
        splashEmitter.Parent = palm

        palm.Parent = model
        model.PrimaryPart = palm
        model.Parent = folder
    end

    -- 8. Aqua_Move2_VortexOfDestruction
    do
        local model = Instance.new("Model")
        model.Name = "Aqua_Move2_VortexOfDestruction"

        local sphere = CreateBasePart("VortexSphere", Vector3.new(4.0, 4.0, 4.0), Color3.fromRGB(0, 185, 255), Enum.Material.Glass, 0.2)
        sphere.Shape = Enum.PartType.Ball

        local coreFlash = CreateBasePart("CoreFlash", Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(220, 250, 255), Enum.Material.Neon)
        coreFlash.Shape = Enum.PartType.Ball
        coreFlash.CFrame = sphere.CFrame

        local ring1 = CreateBasePart("VortexRing1", Vector3.new(1, 1, 1), Color3.fromRGB(80, 230, 255), Enum.Material.Neon)
        local mesh1 = Instance.new("SpecialMesh")
        mesh1.MeshId = ASSETS.RING_MESH
        mesh1.Scale = Vector3.new(5.5, 5.5, 0.8)
        mesh1.Parent = ring1
        ring1.CFrame = sphere.CFrame * CFrame.Angles(math.rad(45), math.rad(30), 0)

        sphere.Parent = model
        coreFlash.Parent = model
        ring1.Parent = model
        model.PrimaryPart = sphere
        model.Parent = folder
    end

    -- 9. Aqua_Move3_WaterDragon
    do
        local model = Instance.new("Model")
        model.Name = "Aqua_Move3_WaterDragon"

        local dragonHead = CreateBasePart("DragonHead", Vector3.new(3.0, 2.4, 4.0), Color3.fromRGB(30, 195, 255), Enum.Material.Glass, 0.2)
        local snout = CreateBasePart("DragonSnout", Vector3.new(2.2, 1.4, 2.8), Color3.fromRGB(10, 160, 240), Enum.Material.Glass, 0.25)
        snout.CFrame = dragonHead.CFrame * CFrame.new(0, -0.4, -2.8)

        local eyeL = CreateBasePart("EyeL", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
        eyeL.CFrame = dragonHead.CFrame * CFrame.new(-1.1, 0.6, -1.2)
        local eyeR = CreateBasePart("EyeR", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
        eyeR.CFrame = dragonHead.CFrame * CFrame.new(1.1, 0.6, -1.2)

        local bodySegment1 = CreateBasePart("BodySeg1", Vector3.new(2.8, 2.8, 4.0), Color3.fromRGB(20, 175, 245), Enum.Material.Glass, 0.3)
        bodySegment1.CFrame = dragonHead.CFrame * CFrame.new(0, 0, 3.8)

        local bodySegment2 = CreateBasePart("BodySeg2", Vector3.new(2.2, 2.2, 4.0), Color3.fromRGB(15, 155, 235), Enum.Material.Glass, 0.35)
        bodySegment2.CFrame = bodySegment1.CFrame * CFrame.new(0, 0, 3.8)

        dragonHead.Parent = model
        snout.Parent = model
        eyeL.Parent = model
        eyeR.Parent = model
        bodySegment1.Parent = model
        bodySegment2.Parent = model
        model.PrimaryPart = dragonHead
        model.Parent = folder
    end

    -- 10. Aqua_Move4_AquaLimitlessPunches
    do
        local model = Instance.new("Model")
        model.Name = "Aqua_Move4_AquaLimitlessPunches"

        local centerAnchor = CreateBasePart("PunchArrayCenter", Vector3.new(1, 1, 1), Color3.fromRGB(0, 200, 255), Enum.Material.Neon, 1)

        -- 6 water fist silhouettes in rapid staggered positions
        local fistOffsets = {
            CFrame.new(-1.8, 1.2, -3.0),
            CFrame.new(1.8, 0.8, -3.4),
            CFrame.new(-0.8, -1.0, -2.8),
            CFrame.new(1.2, -0.6, -3.2),
            CFrame.new(-2.2, -0.4, -3.6),
            CFrame.new(2.0, 1.6, -2.6),
        }

        for idx, offset in ipairs(fistOffsets) do
            local fist = CreateBasePart("WaterFist_" .. idx, Vector3.new(1.4, 1.4, 2.4), Color3.fromRGB(40, 210, 255), Enum.Material.Glass, 0.25)
            fist.CFrame = centerAnchor.CFrame * offset
            fist.Parent = model
        end

        centerAnchor.Parent = model
        model.PrimaryPart = centerAnchor
        model.Parent = folder
    end
end

-- ----------------- EARTH (5 Abilities) -----------------
local function BuildEarthModels(folder: Folder)
    -- 11. Earth_M1_EarthSword
    do
        local model = Instance.new("Model")
        model.Name = "Earth_M1_EarthSword"

        local blade = CreateBasePart("Blade", Vector3.new(0.4, 3.2, 0.9), Color3.fromRGB(115, 80, 50), Enum.Material.Slate)
        local edge = CreateBasePart("BladeEdge", Vector3.new(0.15, 3.2, 0.3), Color3.fromRGB(180, 145, 95), Enum.Material.Slate)
        edge.CFrame = blade.CFrame * CFrame.new(0, 0, -0.5)

        local hilt = CreateBasePart("Hilt", Vector3.new(0.5, 1.0, 0.5), Color3.fromRGB(60, 40, 25), Enum.Material.Wood)
        hilt.CFrame = blade.CFrame * CFrame.new(0, -2.0, 0)

        blade.Parent = model
        edge.Parent = model
        hilt.Parent = model
        model.PrimaryPart = blade
        model.Parent = folder
    end

    -- 12. Earth_Move1_EarthyWall
    do
        local model = Instance.new("Model")
        model.Name = "Earth_Move1_EarthyWall"

        local centerWall = CreateBasePart("CenterWall", Vector3.new(6.0, 8.5, 2.4), Color3.fromRGB(120, 85, 55), Enum.Material.Slate)
        local leftWall = CreateBasePart("LeftWall", Vector3.new(5.0, 7.5, 2.2), Color3.fromRGB(105, 75, 48), Enum.Material.Slate)
        leftWall.CFrame = centerWall.CFrame * CFrame.new(-5.2, -0.5, 0.4) * CFrame.Angles(0, math.rad(15), 0)

        local rightWall = CreateBasePart("RightWall", Vector3.new(5.0, 7.5, 2.2), Color3.fromRGB(105, 75, 48), Enum.Material.Slate)
        rightWall.CFrame = centerWall.CFrame * CFrame.new(5.2, -0.5, 0.4) * CFrame.Angles(0, math.rad(-15), 0)

        centerWall.Parent = model
        leftWall.Parent = model
        rightWall.Parent = model
        model.PrimaryPart = centerWall
        model.Parent = folder
    end

    -- 13. Earth_Move2_BoulderOfDestruction
    do
        local model = Instance.new("Model")
        model.Name = "Earth_Move2_BoulderOfDestruction"

        local boulder = CreateBasePart("BoulderCore", Vector3.new(5.5, 5.5, 5.5), Color3.fromRGB(110, 80, 50), Enum.Material.Slate)
        boulder.Shape = Enum.PartType.Ball

        -- Rock cluster detailing
        for i = 1, 3 do
            local rock = CreateBasePart("Debris_" .. i, Vector3.new(1.8, 1.8, 1.8), Color3.fromRGB(90, 65, 40), Enum.Material.Slate)
            local offsetAngle = (i / 3) * math.pi * 2
            rock.CFrame = boulder.CFrame * CFrame.new(math.cos(offsetAngle) * 3.4, math.sin(offsetAngle) * 2.5, 0)
            rock.Parent = model
        end

        boulder.Parent = model
        model.PrimaryPart = boulder
        model.Parent = folder
    end

    -- 14. Earth_Move3_AcceleratedEarthPunch
    do
        local model = Instance.new("Model")
        model.Name = "Earth_Move3_AcceleratedEarthPunch"

        local fistCasing = CreateBasePart("StoneGauntlet", Vector3.new(1.8, 2.2, 2.4), Color3.fromRGB(130, 95, 60), Enum.Material.Slate)
        local spike1 = CreateBasePart("KnuckleSpike1", Vector3.new(0.5, 0.5, 1.2), Color3.fromRGB(190, 150, 100), Enum.Material.Slate)
        spike1.CFrame = fistCasing.CFrame * CFrame.new(-0.5, 0.4, -1.5)
        local spike2 = CreateBasePart("KnuckleSpike2", Vector3.new(0.5, 0.5, 1.2), Color3.fromRGB(190, 150, 100), Enum.Material.Slate)
        spike2.CFrame = fistCasing.CFrame * CFrame.new(0.5, 0.4, -1.5)

        fistCasing.Parent = model
        spike1.Parent = model
        spike2.Parent = model
        model.PrimaryPart = fistCasing
        model.Parent = folder
    end

    -- 15. Earth_Move4_TheMasterOfTerra
    do
        local model = Instance.new("Model")
        model.Name = "Earth_Move4_TheMasterOfTerra"

        local origin = CreateBasePart("TerraOrigin", Vector3.new(1, 1, 1), Color3.fromRGB(120, 85, 55), Enum.Material.Slate, 1)

        -- Earth dagger
        local dagger = CreateBasePart("EarthDagger", Vector3.new(0.4, 3.8, 0.7), Color3.fromRGB(180, 135, 80), Enum.Material.Slate)
        dagger.CFrame = origin.CFrame * CFrame.new(0, 4, 0)

        -- 4 Rising Bedrock Monoliths
        local offsets = {
            Vector3.new(8, 6, 8),
            Vector3.new(-8, 6, 8),
            Vector3.new(8, 6, -8),
            Vector3.new(-8, 6, -8),
        }
        for idx, offset in ipairs(offsets) do
            local monolith = CreateBasePart("Monolith_" .. idx, Vector3.new(3.0, 12.0, 3.0), Color3.fromRGB(90, 65, 40), Enum.Material.Slate)
            monolith.CFrame = origin.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(idx * 5), math.rad(idx * 20), 0)
            monolith.Parent = model
        end

        origin.Parent = model
        dagger.Parent = model
        model.PrimaryPart = origin
        model.Parent = folder
    end
end

-- ----------------- LIGHT (5 Abilities) -----------------
local function BuildLightModels(folder: Folder)
    -- Palette: Pale lavender #C8A2F0, Bright white #E9D8FF, Deep violet #8B5BD6
    local colLavender = Color3.fromRGB(200, 162, 240)
    local colBright = Color3.fromRGB(233, 216, 255)
    local colViolet = Color3.fromRGB(139, 91, 214)

    -- 16. Light_M1_DimLightRay
    do
        local model = Instance.new("Model")
        model.Name = "Light_M1_DimLightRay"

        local core = CreateBasePart("RayCore", Vector3.new(0.4, 0.4, 8.0), colBright, Enum.Material.Neon)
        local glow = CreateBasePart("RayGlow", Vector3.new(0.8, 0.8, 8.0), colLavender, Enum.Material.Neon, 0.4)
        glow.CFrame = core.CFrame

        core.Parent = model
        glow.Parent = model
        model.PrimaryPart = core
        model.Parent = folder
    end

    -- 17. Light_Move1_AmplifiedLight
    do
        local model = Instance.new("Model")
        model.Name = "Light_Move1_AmplifiedLight"

        local core = CreateBasePart("BeamCore", Vector3.new(1.2, 1.2, 14.0), colBright, Enum.Material.Neon)
        local mantle = CreateBasePart("BeamMantle", Vector3.new(2.4, 2.4, 14.0), colLavender, Enum.Material.Neon, 0.3)
        mantle.CFrame = core.CFrame
        local outerViolet = CreateBasePart("BeamOuter", Vector3.new(3.6, 3.6, 14.0), colViolet, Enum.Material.Neon, 0.6)
        outerViolet.CFrame = core.CFrame

        core.Parent = model
        mantle.Parent = model
        outerViolet.Parent = model
        model.PrimaryPart = core
        model.Parent = folder
    end

    -- 18. Light_Move2_MirrorsOfJudgement
    do
        local model = Instance.new("Model")
        model.Name = "Light_Move2_MirrorsOfJudgement"

        local center = CreateBasePart("JudgementCenter", Vector3.new(1, 1, 1), colBright, Enum.Material.Neon, 1)

        -- 4 Floating Hexagonal Reflective Mirrors
        local mirrorAngles = { 0, 90, 180, 270 }
        for idx, deg in ipairs(mirrorAngles) do
            local rad = math.rad(deg)
            local mirror = CreateBasePart("Mirror_" .. idx, Vector3.new(3.8, 5.0, 0.3), colLavender, Enum.Material.Glass, 0.15)
            mirror.CFrame = center.CFrame * CFrame.new(math.cos(rad) * 9, 3, math.sin(rad) * 9) * CFrame.Angles(0, -rad + math.rad(90), 0)
            
            local frame = CreateBasePart("Frame_" .. idx, Vector3.new(4.2, 5.4, 0.4), colViolet, Enum.Material.Neon)
            frame.CFrame = mirror.CFrame

            mirror.Parent = model
            frame.Parent = model
        end

        center.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end

    -- 19. Light_Move3_BlindingAttack
    do
        local model = Instance.new("Model")
        model.Name = "Light_Move3_BlindingAttack"

        local orb = CreateBasePart("FlashOrb", Vector3.new(3.0, 3.0, 3.0), colBright, Enum.Material.Neon)
        orb.Shape = Enum.PartType.Ball

        -- Radial god-rays
        for i = 1, 6 do
            local ray = CreateBasePart("GodRay_" .. i, Vector3.new(0.4, 0.4, 6.0), colLavender, Enum.Material.Neon, 0.2)
            local angle = (i / 6) * math.pi * 2
            ray.CFrame = orb.CFrame * CFrame.Angles(math.sin(angle), math.cos(angle), 0) * CFrame.new(0, 0, -3.0)
            ray.Parent = model
        end

        orb.Parent = model
        model.PrimaryPart = orb
        model.Parent = folder
    end

    -- 20. Light_Move4_DivineLightAmplification
    do
        local model = Instance.new("Model")
        model.Name = "Light_Move4_DivineLightAmplification"

        local center = CreateBasePart("DivineCenter", Vector3.new(4.0, 4.0, 4.0), colBright, Enum.Material.Neon)
        center.Shape = Enum.PartType.Ball

        local outerSphere = CreateBasePart("OuterAura", Vector3.new(7.0, 7.0, 7.0), colViolet, Enum.Material.Neon, 0.5)
        outerSphere.Shape = Enum.PartType.Ball
        outerSphere.CFrame = center.CFrame

        local ring = CreateBasePart("ShockwaveRing", Vector3.new(1, 1, 1), colLavender, Enum.Material.Neon)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(16, 16, 1.2)
        mesh.Parent = ring
        ring.CFrame = center.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        center.Parent = model
        outerSphere.Parent = model
        ring.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end
end

-- ----------------- WIND (5 Abilities) -----------------
local function BuildWindModels(folder: Folder)
    local colMint = Color3.fromRGB(150, 255, 220)
    local colPaleCyan = Color3.fromRGB(180, 240, 255)
    local colWhite = Color3.fromRGB(245, 255, 250)

    -- 21. Wind_M1_CompressedWind
    do
        local model = Instance.new("Model")
        model.Name = "Wind_M1_CompressedWind"

        -- Zigzag bolt pieces
        local seg1 = CreateBasePart("BoltSeg1", Vector3.new(0.3, 0.3, 3.0), colWhite, Enum.Material.Neon)
        local seg2 = CreateBasePart("BoltSeg2", Vector3.new(0.3, 0.3, 3.0), colMint, Enum.Material.Neon)
        seg2.CFrame = seg1.CFrame * CFrame.new(0.6, 0, -2.6) * CFrame.Angles(0, math.rad(-25), 0)

        seg1.Parent = model
        seg2.Parent = model
        model.PrimaryPart = seg1
        model.Parent = folder
    end

    -- 22. Wind_Move1_AiryVortex
    do
        local model = Instance.new("Model")
        model.Name = "Wind_Move1_AiryVortex"

        local coneCore = CreateBasePart("VortexCore", Vector3.new(2.4, 5.0, 2.4), colMint, Enum.Material.Neon, 0.3)
        local outerRing = CreateBasePart("AirRing", Vector3.new(1, 1, 1), colPaleCyan, Enum.Material.Neon, 0.25)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(4.5, 4.5, 0.8)
        mesh.Parent = outerRing
        outerRing.CFrame = coneCore.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        coneCore.Parent = model
        outerRing.Parent = model
        model.PrimaryPart = coneCore
        model.Parent = folder
    end

    -- 23. Wind_Move2_TheCycloneOfFury
    do
        local model = Instance.new("Model")
        model.Name = "Wind_Move2_TheCycloneOfFury"

        local pillar = CreateBasePart("CyclonePillar", Vector3.new(8.0, 22.0, 8.0), colPaleCyan, Enum.Material.Glass, 0.4)
        
        -- Concentric rings stacked vertically
        for i = 1, 3 do
            local ring = CreateBasePart("CycloneRing_" .. i, Vector3.new(1, 1, 1), colMint, Enum.Material.Neon, 0.2)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshId = ASSETS.RING_MESH
            mesh.Scale = Vector3.new(10 + i * 4, 10 + i * 4, 1.0)
            mesh.Parent = ring
            ring.CFrame = pillar.CFrame * CFrame.new(0, (i - 2) * 6, 0) * CFrame.Angles(math.rad(90), 0, 0)
            ring.Parent = model
        end

        pillar.Parent = model
        model.PrimaryPart = pillar
        model.Parent = folder
    end

    -- 24. Wind_Move3_MaximumSpeed
    do
        local model = Instance.new("Model")
        model.Name = "Wind_Move3_MaximumSpeed"

        local anchor = CreateBasePart("SpeedAnchor", Vector3.new(1, 1, 1), colWhite, Enum.Material.Neon, 1)
        
        local vortexL = CreateBasePart("VortexLegL", Vector3.new(1.2, 1.8, 1.2), colMint, Enum.Material.Neon, 0.3)
        vortexL.CFrame = anchor.CFrame * CFrame.new(-0.8, -1.0, 0)
        local vortexR = CreateBasePart("VortexLegR", Vector3.new(1.2, 1.8, 1.2), colMint, Enum.Material.Neon, 0.3)
        vortexR.CFrame = anchor.CFrame * CFrame.new(0.8, -1.0, 0)

        anchor.Parent = model
        vortexL.Parent = model
        vortexR.Parent = model
        model.PrimaryPart = anchor
        model.Parent = folder
    end

    -- 25. Wind_Move4_WindDeathSpeed
    do
        local model = Instance.new("Model")
        model.Name = "Wind_Move4_WindDeathSpeed"

        local gliderPlate = CreateBasePart("RockGlider", Vector3.new(4.5, 0.6, 6.0), Color3.fromRGB(80, 80, 90), Enum.Material.Slate)
        local thrusterL = CreateBasePart("WindThrusterL", Vector3.new(0.8, 0.8, 3.0), colMint, Enum.Material.Neon, 0.2)
        thrusterL.CFrame = gliderPlate.CFrame * CFrame.new(-2.0, -0.4, 2.5)
        local thrusterR = CreateBasePart("WindThrusterR", Vector3.new(0.8, 0.8, 3.0), colMint, Enum.Material.Neon, 0.2)
        thrusterR.CFrame = gliderPlate.CFrame * CFrame.new(2.0, -0.4, 2.5)

        gliderPlate.Parent = model
        thrusterL.Parent = model
        thrusterR.Parent = model
        model.PrimaryPart = gliderPlate
        model.Parent = folder
    end
end

-- ----------------- ERROR (6 Abilities) -----------------
local function BuildErrorModels(folder: Folder)
    local colDarkPurple = Color3.fromRGB(45, 10, 80)
    local colNeonPurple = Color3.fromRGB(170, 0, 255)
    local colGlitchCyan = Color3.fromRGB(0, 240, 255)
    local colObsidian = Color3.fromRGB(15, 15, 25)

    -- 26. Error_M1_GlitchedDash
    do
        local model = Instance.new("Model")
        model.Name = "Error_M1_GlitchedDash"

        local core = CreateBasePart("GlitchCore", Vector3.new(1.8, 4.0, 1.2), colObsidian, Enum.Material.Neon, 0.3)
        
        -- Chromatic offset glitch slices
        local sliceR = CreateBasePart("GlitchSliceR", Vector3.new(1.9, 0.8, 1.3), colNeonPurple, Enum.Material.Neon, 0.4)
        sliceR.CFrame = core.CFrame * CFrame.new(0.3, 0.8, -0.2)
        local sliceB = CreateBasePart("GlitchSliceB", Vector3.new(1.9, 0.8, 1.3), colGlitchCyan, Enum.Material.Neon, 0.4)
        sliceB.CFrame = core.CFrame * CFrame.new(-0.3, -0.8, 0.2)

        core.Parent = model
        sliceR.Parent = model
        sliceB.Parent = model
        model.PrimaryPart = core
        model.Parent = folder
    end

    -- 27. Error_Move1_ChaoticDestruction
    do
        local model = Instance.new("Model")
        model.Name = "Error_Move1_ChaoticDestruction"

        local shield = CreateBasePart("GlitchShield", Vector3.new(3.8, 4.8, 0.4), colDarkPurple, Enum.Material.Glass, 0.2)
        local neonBorder = CreateBasePart("NeonBorder", Vector3.new(4.0, 5.0, 0.2), colNeonPurple, Enum.Material.Neon, 0.3)
        neonBorder.CFrame = shield.CFrame

        -- 3 floating pixel fragments
        for i = 1, 3 do
            local pixel = CreateBasePart("Pixel_" .. i, Vector3.new(0.6, 0.6, 0.2), colGlitchCyan, Enum.Material.Neon)
            pixel.CFrame = shield.CFrame * CFrame.new((i - 2) * 1.5, 2.2, 0)
            pixel.Parent = model
        end

        shield.Parent = model
        neonBorder.Parent = model
        model.PrimaryPart = shield
        model.Parent = folder
    end

    -- 28. Error_Move2_404NotFound
    do
        local model = Instance.new("Model")
        model.Name = "Error_Move2_404NotFound"

        local orb = CreateBasePart("GlitchOrb", Vector3.new(3.5, 3.5, 3.5), colDarkPurple, Enum.Material.Neon)
        orb.Shape = Enum.PartType.Ball

        local ring = CreateBasePart("ErrorRing", Vector3.new(1, 1, 1), colGlitchCyan, Enum.Material.Neon)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(5.0, 5.0, 0.6)
        mesh.Parent = ring
        ring.CFrame = orb.CFrame * CFrame.Angles(math.rad(60), math.rad(45), 0)

        orb.Parent = model
        ring.Parent = model
        model.PrimaryPart = orb
        model.Parent = folder
    end

    -- 29. Error_Move3_GotGlitched
    do
        local model = Instance.new("Model")
        model.Name = "Error_Move3_GotGlitched"

        local core = CreateBasePart("DissolutionCore", Vector3.new(1, 1, 1), colNeonPurple, Enum.Material.Neon, 1)

        -- 4 Spatial anomaly wireframe shards
        for i = 1, 4 do
            local shard = CreateBasePart("Shard_" .. i, Vector3.new(0.8, 1.4, 0.2), colGlitchCyan, Enum.Material.Neon, 0.25)
            local angle = (i / 4) * math.pi * 2
            shard.CFrame = core.CFrame * CFrame.new(math.cos(angle) * 2.2, (i - 2.5) * 1.0, math.sin(angle) * 2.2)
            shard.Parent = model
        end

        core.Parent = model
        model.PrimaryPart = core
        model.Parent = folder
    end

    -- 30. Error_Move4_SpatialDistortion
    do
        local model = Instance.new("Model")
        model.Name = "Error_Move4_SpatialDistortion"

        local portalFrame = CreateBasePart("PortalFrame", Vector3.new(6.0, 9.0, 0.8), colObsidian, Enum.Material.Slate)
        local eventHorizon = CreateBasePart("EventHorizon", Vector3.new(5.0, 8.0, 0.4), colNeonPurple, Enum.Material.Neon, 0.15)
        eventHorizon.CFrame = portalFrame.CFrame

        portalFrame.Parent = model
        eventHorizon.Parent = model
        model.PrimaryPart = portalFrame
        model.Parent = folder
    end

    -- 31. Error_Move5_Unparalleled
    do
        local model = Instance.new("Model")
        model.Name = "Error_Move5_Unparalleled"

        local center = CreateBasePart("CageCenter", Vector3.new(1, 1, 1), colNeonPurple, Enum.Material.Neon, 1)

        -- Octagonal glitch freeze cage bars
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local bar = CreateBasePart("CageBar_" .. i, Vector3.new(0.4, 9.0, 0.4), colNeonPurple, Enum.Material.Neon)
            bar.CFrame = center.CFrame * CFrame.new(math.cos(angle) * 6.5, 4.5, math.sin(angle) * 6.5)
            bar.Parent = model
        end

        center.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end
end

-- ----------------- TIME (5 Abilities) -----------------
local function BuildTimeModels(folder: Folder)
    local colDeepBlue = Color3.fromRGB(10, 40, 110)
    local colCyan = Color3.fromRGB(0, 220, 255)
    local colBrightWhite = Color3.fromRGB(240, 250, 255)

    -- 32. Time_M1_TimePunch
    do
        local model = Instance.new("Model")
        model.Name = "Time_M1_TimePunch"

        local fistCore = CreateBasePart("TimeFistCore", Vector3.new(1.6, 1.6, 2.0), colCyan, Enum.Material.Neon, 0.2)
        local dialRing = CreateBasePart("DialRing", Vector3.new(1, 1, 1), colBrightWhite, Enum.Material.Neon)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(2.8, 2.8, 0.4)
        mesh.Parent = dialRing
        dialRing.CFrame = fistCore.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        fistCore.Parent = model
        dialRing.Parent = model
        model.PrimaryPart = fistCore
        model.Parent = folder
    end

    -- 33. Time_Move1_GotThrowed
    do
        local model = Instance.new("Model")
        model.Name = "Time_Move1_GotThrowed"

        local center = CreateBasePart("StasisCenter", Vector3.new(1, 1, 1), colCyan, Enum.Material.Neon, 1)

        -- Target temporal stasis dial
        local dial = CreateBasePart("StasisDial", Vector3.new(1, 1, 1), colCyan, Enum.Material.Neon, 0.1)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = ASSETS.RING_MESH
        mesh.Scale = Vector3.new(6.0, 6.0, 0.6)
        mesh.Parent = dial
        dial.CFrame = center.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        -- 4 Cardinal hour tick marks
        for i = 1, 4 do
            local mark = CreateBasePart("TickMark_" .. i, Vector3.new(0.3, 0.2, 1.2), colBrightWhite, Enum.Material.Neon)
            local angle = (i / 4) * math.pi * 2
            mark.CFrame = dial.CFrame * CFrame.new(math.cos(angle) * 3.0, 0, math.sin(angle) * 3.0)
            mark.Parent = model
        end

        center.Parent = model
        dial.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end

    -- 34. Time_Move2_TimeInjection
    do
        local model = Instance.new("Model")
        model.Name = "Time_Move2_TimeInjection"

        local coreOrb = CreateBasePart("InjectionCore", Vector3.new(2.8, 2.8, 2.8), colBrightWhite, Enum.Material.Neon)
        coreOrb.Shape = Enum.PartType.Ball

        -- Concentric rotating dial toruses
        local dial1 = CreateBasePart("DialInner", Vector3.new(1, 1, 1), colCyan, Enum.Material.Neon)
        local mesh1 = Instance.new("SpecialMesh")
        mesh1.MeshId = ASSETS.RING_MESH
        mesh1.Scale = Vector3.new(4.2, 4.2, 0.5)
        mesh1.Parent = dial1
        dial1.CFrame = coreOrb.CFrame * CFrame.Angles(math.rad(45), 0, 0)

        local dial2 = CreateBasePart("DialOuter", Vector3.new(1, 1, 1), colDeepBlue, Enum.Material.Neon, 0.2)
        local mesh2 = Instance.new("SpecialMesh")
        mesh2.MeshId = ASSETS.RING_MESH
        mesh2.Scale = Vector3.new(6.2, 6.2, 0.5)
        mesh2.Parent = dial2
        dial2.CFrame = coreOrb.CFrame * CFrame.Angles(math.rad(-45), 0, 0)

        coreOrb.Parent = model
        dial1.Parent = model
        dial2.Parent = model
        model.PrimaryPart = coreOrb
        model.Parent = folder
    end

    -- 35. Time_Move3_Untouchable
    do
        local model = Instance.new("Model")
        model.Name = "Time_Move3_Untouchable"

        local shieldCore = CreateBasePart("TimeShield", Vector3.new(7.0, 7.0, 7.0), colCyan, Enum.Material.Glass, 0.5)
        shieldCore.Shape = Enum.PartType.Ball

        -- 2 Equator rings
        local ring1 = CreateBasePart("EquatorRing1", Vector3.new(1, 1, 1), colBrightWhite, Enum.Material.Neon, 0.2)
        local m1 = Instance.new("SpecialMesh")
        m1.MeshId = ASSETS.RING_MESH
        m1.Scale = Vector3.new(8.5, 8.5, 0.6)
        m1.Parent = ring1
        ring1.CFrame = shieldCore.CFrame * CFrame.Angles(math.rad(90), 0, 0)

        shieldCore.Parent = model
        ring1.Parent = model
        model.PrimaryPart = shieldCore
        model.Parent = folder
    end

    -- 36. Time_Move4_VirtualKill
    do
        local model = Instance.new("Model")
        model.Name = "Time_Move4_VirtualKill"

        local center = CreateBasePart("ChronosOrigin", Vector3.new(1, 1, 1), colCyan, Enum.Material.Neon, 1)

        -- Central chronos pillar
        local pillar = CreateBasePart("ChronosPillar", Vector3.new(2.4, 18.0, 2.4), colCyan, Enum.Material.Neon, 0.15)
        pillar.CFrame = center.CFrame * CFrame.new(0, 9, 0)

        -- Concentric closing rings
        for i = 1, 3 do
            local ring = CreateBasePart("CollapseRing_" .. i, Vector3.new(1, 1, 1), colBrightWhite, Enum.Material.Neon)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshId = ASSETS.RING_MESH
            mesh.Scale = Vector3.new(4 + i * 4, 4 + i * 4, 0.8)
            mesh.Parent = ring
            ring.CFrame = center.CFrame * CFrame.new(0, i * 4, 0) * CFrame.Angles(math.rad(90), 0, 0)
            ring.Parent = model
        end

        center.Parent = model
        pillar.Parent = model
        model.PrimaryPart = center
        model.Parent = folder
    end
end

-- ==================== MASTER GENERATE FUNCTION ====================
function VFXModelBuilder.BuildAll(targetVFXFolder: Folder?): { [string]: number }
    local vfxRoot = targetVFXFolder or EnsureFolder(ReplicatedStorage, "VFX")
    
    local fireFolder = EnsureFolder(vfxRoot, "Fire")
    local aquaFolder = EnsureFolder(vfxRoot, "Aqua")
    local earthFolder = EnsureFolder(vfxRoot, "Earth")
    local lightFolder = EnsureFolder(vfxRoot, "Light")
    local windFolder = EnsureFolder(vfxRoot, "Wind")
    local errorFolder = EnsureFolder(vfxRoot, "Error")
    local timeFolder = EnsureFolder(vfxRoot, "Time")

    BuildFireModels(fireFolder)
    BuildAquaModels(aquaFolder)
    BuildEarthModels(earthFolder)
    BuildLightModels(lightFolder)
    BuildWindModels(windFolder)
    BuildErrorModels(errorFolder)
    BuildTimeModels(timeFolder)

    local counts = {
        Fire = #fireFolder:GetChildren(),
        Aqua = #aquaFolder:GetChildren(),
        Earth = #earthFolder:GetChildren(),
        Light = #lightFolder:GetChildren(),
        Wind = #windFolder:GetChildren(),
        Error = #errorFolder:GetChildren(),
        Time = #timeFolder:GetChildren(),
    }

    local total = 0
    for _, count in pairs(counts) do
        total += count
    end
    counts["Total"] = total

    print(string.format("[VFXModelBuilder] Successfully built all %d ability VFX models in ReplicatedStorage.VFX!", total))
    return counts
end

return table.freeze(VFXModelBuilder)
