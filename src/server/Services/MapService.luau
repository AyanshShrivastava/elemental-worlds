--!strict
--[[
    Elemental Worlds: Procedural Map & World Generation Service
    Constructs the complete bounded open world in Workspace.Map if not already placed.

    World 1 — Ember Highlands:
    - Village (Spawn pads, Torii gate, shrine, houses, stone paths)
    - Forest (Anime foliage, glowing mushrooms, enemy camps)
    - Mountains (Elevated stone terraces, summit viewpoint)
    - Caves (Dark cavern, glowing crystals, hidden fragment)
    - Ruins (Ancient pillars, glowing rune dais)
    - River & Bridges
    - Raid Entrance Portal (Pulsing obsidian gateway)
    - World Fragments (Interactive ProximityPrompt collectables — unlock World 2)
    - Training Dummies (Respawning NPCs)
    - World Name Signs
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RaidService = require(script.Parent.RaidService)

local MapService = {}

-- Configures high-end modern anime lighting (Blox Fruits style)
local function SetupAnimeLighting()
    Lighting.ClockTime = 14.5
    Lighting.GeographicLatitude = 40
    Lighting.Brightness = 2.2
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(80, 85, 100)
    Lighting.OutdoorAmbient = Color3.fromRGB(110, 120, 140)

    -- ColorCorrection for anime punch
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "AnimeColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = 0.02
    cc.Contrast = 0.12
    cc.Saturation = 0.16
    cc.TintColor = Color3.fromRGB(255, 252, 248)

    -- Bloom for elemental abilities
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "AnimeBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.55
    bloom.Size = 22
    bloom.Threshold = 1.1

    -- SunRays
    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Name = "AnimeSunRays"
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = 0.12
    sunRays.Spread = 0.8
end

-- World spawn positions
local WORLD_SPAWNS: { [string]: CFrame } = {
    World1 = CFrame.new(0, 4, 0),
    World2 = CFrame.new(0, 4, 0),
    World3 = CFrame.new(0, 4, 0),
}

function MapService.GetWorldSpawn(worldId: string): CFrame
    return WORLD_SPAWNS[worldId] or CFrame.new(0, 4, 0)
end

local function CreatePart(
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    parent: Instance,
    canCollide: boolean?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = true
    part.CanCollide = if canCollide ~= nil then canCollide else true
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function AddNeonLight(part: BasePart, color: Color3, range: number, brightness: number)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Parent = part
end

local function CreateWedge(
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    parent: Instance
): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Name = name
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Color = color
    wedge.Material = material
    wedge.Anchored = true
    wedge.CanCollide = true
    wedge.Parent = parent
    return wedge
end

local function CreateWorldSign(text: string, pos: Vector3, parent: Instance)
    local sign = Instance.new("Part")
    sign.Name = "WorldSign"
    sign.Size = Vector3.new(16, 5, 0.5)
    sign.CFrame = CFrame.new(pos)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(30, 25, 45)
    sign.Material = Enum.Material.Obsidian
    sign.Parent = parent

    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.Parent = sign

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextScaled = true
    lbl.TextColor3 = Color3.fromRGB(245, 248, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(15, 18, 30)
    lbl.TextStrokeTransparency = 0.2
    lbl.Parent = sg

    local signStroke = Instance.new("UIStroke")
    signStroke.Color = Color3.fromRGB(130, 95, 255)
    signStroke.Thickness = 2
    signStroke.Parent = sign
end

function MapService.BuildWorld1()
    SetupAnimeLighting()

    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then
        mapFolder = Instance.new("Folder")
        mapFolder.Name = "Map"
        mapFolder.Parent = Workspace
    end

    -- Preserve designer-placed work
    if #mapFolder:GetChildren() > 2 then
        print("[MapService] Existing map detected. Preserving designer build.")
        return
    end

    print("[MapService] Generating World 1 — Ember Highlands...")

    -- ==================== BASE TERRAIN ====================
    -- Main island
    CreatePart("BaseIsland", Vector3.new(1400, 12, 1400), CFrame.new(0, -6, 0),
        Color3.fromRGB(80, 145, 65), Enum.Material.Grass, mapFolder)

    -- Texture variation patches
    CreatePart("DirtPatch1", Vector3.new(120, 0.5, 80), CFrame.new(-200, 0.75, 200),
        Color3.fromRGB(110, 80, 50), Enum.Material.Ground, mapFolder)
    CreatePart("DirtPatch2", Vector3.new(100, 0.5, 120), CFrame.new(200, 0.75, -200),
        Color3.fromRGB(100, 75, 45), Enum.Material.Ground, mapFolder)

    -- ==================== VILLAGE (HUB / SPAWN) ====================
    local villageFolder = Instance.new("Folder")
    villageFolder.Name = "Village"
    villageFolder.Parent = mapFolder

    CreateWorldSign("EMBER HIGHLANDS — WORLD 1", Vector3.new(0, 15, -100), villageFolder)

    -- Main Cobblestone Plaza
    CreatePart("Plaza", Vector3.new(200, 2, 200), CFrame.new(0, 0.5, 0),
        Color3.fromRGB(150, 150, 155), Enum.Material.Cobblestone, villageFolder)

    -- Plaza edge trim
    for i = 0, 3 do
        local angle = (i / 4) * math.pi * 2
        local x = math.cos(angle) * 100
        local z = math.sin(angle) * 100
        CreatePart("PlazaTrim_" .. i, Vector3.new(200, 3, 4),
            CFrame.new(0, 1, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -100),
            Color3.fromRGB(80, 75, 90), Enum.Material.SmoothPlastic, villageFolder)
    end

    -- Spawn Location
    local spawnFolder = Workspace:FindFirstChild("SpawnLocations")
    if not spawnFolder then
        spawnFolder = Instance.new("Folder")
        spawnFolder.Name = "SpawnLocations"
        spawnFolder.Parent = Workspace
    end

    local spawnPad = Instance.new("SpawnLocation")
    spawnPad.Name = "VillageSpawn"
    spawnPad.Size = Vector3.new(20, 1, 20)
    spawnPad.CFrame = CFrame.new(0, 1.2, 0)
    spawnPad.Material = Enum.Material.Neon
    spawnPad.Color = Color3.fromRGB(60, 180, 255)
    spawnPad.Neutral = true
    spawnPad.Duration = 0
    spawnPad.AllowTeamChangeOnTouch = false
    spawnPad.Parent = spawnFolder
    AddNeonLight(spawnPad, Color3.fromRGB(60, 180, 255), 20, 1.5)

    -- Torii Gate
    CreatePart("ToriiPillarLeft", Vector3.new(4, 30, 4), CFrame.new(-26, 15, -85),
        Color3.fromRGB(200, 40, 25), Enum.Material.Wood, villageFolder)
    CreatePart("ToriiPillarRight", Vector3.new(4, 30, 4), CFrame.new(26, 15, -85),
        Color3.fromRGB(200, 40, 25), Enum.Material.Wood, villageFolder)
    CreatePart("ToriiBeamTop", Vector3.new(64, 5, 6), CFrame.new(0, 29, -85),
        Color3.fromRGB(25, 22, 30), Enum.Material.Wood, villageFolder)
    CreatePart("ToriiBeamMid", Vector3.new(56, 4, 5), CFrame.new(0, 22, -85),
        Color3.fromRGB(200, 40, 25), Enum.Material.Wood, villageFolder)

    -- Shrine at center
    CreatePart("ShrinePlatform", Vector3.new(24, 3, 24), CFrame.new(0, 1.5, 60),
        Color3.fromRGB(200, 195, 180), Enum.Material.Cobblestone, villageFolder)
    CreatePart("ShrineBody", Vector3.new(12, 16, 12), CFrame.new(0, 9.5, 60),
        Color3.fromRGB(220, 215, 200), Enum.Material.Plaster, villageFolder)
    CreatePart("ShrineRoof", Vector3.new(18, 6, 18), CFrame.new(0, 20, 60),
        Color3.fromRGB(40, 40, 55), Enum.Material.WoodPlanks, villageFolder)
    local shrineGlow = CreatePart("ShrineOrb", Vector3.new(2, 2, 2), CFrame.new(0, 18, 60),
        Color3.fromRGB(0, 200, 255), Enum.Material.Neon, villageFolder, false)
    shrineGlow.Shape = Enum.PartType.Ball
    AddNeonLight(shrineGlow, Color3.fromRGB(0, 200, 255), 20, 3)

    -- Village Houses (varied sizes)
    local houseConfigs = {
        { pos = Vector3.new(-70, 0, -30), size = Vector3.new(30, 20, 30), color = Color3.fromRGB(220, 210, 190) },
        { pos = Vector3.new(70, 0, -30), size = Vector3.new(26, 18, 26), color = Color3.fromRGB(210, 200, 175) },
        { pos = Vector3.new(-70, 0, 40), size = Vector3.new(28, 16, 28), color = Color3.fromRGB(230, 220, 200) },
        { pos = Vector3.new(70, 0, 40), size = Vector3.new(32, 22, 32), color = Color3.fromRGB(200, 195, 180) },
        { pos = Vector3.new(-50, 0, -70), size = Vector3.new(22, 15, 22), color = Color3.fromRGB(215, 205, 185) },
        { pos = Vector3.new(50, 0, -70), size = Vector3.new(24, 16, 24), color = Color3.fromRGB(225, 215, 195) },
    }
    for i, cfg in houseConfigs do
        local hh = cfg.size.Y / 2
        CreatePart("House_" .. i, cfg.size, CFrame.new(cfg.pos + Vector3.new(0, hh, 0)),
            cfg.color, Enum.Material.Plaster, villageFolder)
        CreatePart("Roof_" .. i, Vector3.new(cfg.size.X + 6, 7, cfg.size.Z + 6),
            CFrame.new(cfg.pos + Vector3.new(0, cfg.size.Y + 3.5, 0)),
            Color3.fromRGB(45, 40, 55), Enum.Material.WoodPlanks, villageFolder)
    end

    -- Stone Paths
    for z = -80, 80, 10 do
        CreatePart("PathStone_" .. z, Vector3.new(8, 0.4, 9), CFrame.new(0, 0.7, z),
            Color3.fromRGB(140, 138, 145), Enum.Material.Cobblestone, villageFolder)
    end

    -- ==================== FOREST REGION ====================
    local forestFolder = Instance.new("Folder")
    forestFolder.Name = "Forest"
    forestFolder.Parent = mapFolder

    -- Ground covering
    CreatePart("ForestGround", Vector3.new(300, 2, 500), CFrame.new(-270, 0.5, 0),
        Color3.fromRGB(55, 110, 45), Enum.Material.Grass, forestFolder)

    -- Trees (varied)
    local treeColors = { Color3.fromRGB(45, 115, 45), Color3.fromRGB(38, 100, 38), Color3.fromRGB(55, 130, 50) }
    for x = -380, -130, 42 do
        for z = -240, 240, 42 do
            local jx = math.random(-10, 10)
            local jz = math.random(-10, 10)
            local height = math.random(22, 35)
            local foliageSize = math.random(18, 28)
            local colorIdx = math.random(1, #treeColors)

            local trunk = CreatePart("TreeTrunk", Vector3.new(math.random(3, 6), height, math.random(3, 6)),
                CFrame.new(x + jx, height / 2, z + jz), Color3.fromRGB(90, 60, 35), Enum.Material.Wood, forestFolder)

            CreatePart("TreeFoliage", Vector3.new(foliageSize, foliageSize - 4, foliageSize),
                CFrame.new(trunk.Position + Vector3.new(0, height / 2 + 4, 0)),
                treeColors[colorIdx], Enum.Material.Grass, forestFolder, false)
        end
    end

    -- Glowing Mushrooms
    for i = 1, 12 do
        local mx = math.random(-350, -140)
        local mz = math.random(-200, 200)
        local mushColor = (i % 3 == 0) and Color3.fromRGB(255, 80, 200) or (i % 3 == 1) and Color3.fromRGB(80, 255, 180) or Color3.fromRGB(255, 200, 50)

        CreatePart("MushroomStem_" .. i, Vector3.new(2, math.random(3, 7), 2),
            CFrame.new(mx, 3, mz), Color3.fromRGB(200, 180, 160), Enum.Material.SmoothPlastic, forestFolder)
        local mushCap = CreatePart("MushroomCap_" .. i, Vector3.new(math.random(5, 9), 3, math.random(5, 9)),
            CFrame.new(mx, 7, mz), mushColor, Enum.Material.Neon, forestFolder, false)
        mushCap.Shape = Enum.PartType.Ball
        AddNeonLight(mushCap, mushColor, 12, 2)
    end

    -- Enemy Camp in Forest
    local campFolder = Instance.new("Folder")
    campFolder.Name = "EnemyCamp"
    campFolder.Parent = forestFolder
    CreatePart("CampFire_Base", Vector3.new(6, 1, 6), CFrame.new(-220, 0.8, 80),
        Color3.fromRGB(100, 80, 60), Enum.Material.SmoothPlastic, campFolder)
    local fireGlow = CreatePart("CampFire_Glow", Vector3.new(3, 4, 3), CFrame.new(-220, 3, 80),
        Color3.fromRGB(255, 120, 30), Enum.Material.Neon, campFolder, false)
    AddNeonLight(fireGlow, Color3.fromRGB(255, 100, 20), 18, 3.5)

    for i = 1, 4 do
        local angle = (i / 4) * math.pi * 2
        CreatePart("CampTent_" .. i, Vector3.new(12, 10, 10),
            CFrame.new(-220 + math.cos(angle) * 22, 5, 80 + math.sin(angle) * 22),
            Color3.fromRGB(90, 65, 40), Enum.Material.Fabric, campFolder)
    end

    -- ==================== MOUNTAINS REGION ====================
    local mountainFolder = Instance.new("Folder")
    mountainFolder.Name = "Mountains"
    mountainFolder.Parent = mapFolder

    local mountainTiers = {
        { size = Vector3.new(340, 24, 340), height = 12 },
        { size = Vector3.new(260, 28, 260), height = 38 },
        { size = Vector3.new(190, 32, 190), height = 66 },
        { size = Vector3.new(130, 36, 130), height = 96 },
        { size = Vector3.new(75, 30, 75), height = 124 },
    }
    for i, tier in mountainTiers do
        CreatePart("MountainTier_" .. i, tier.size,
            CFrame.new(420, tier.height - tier.size.Y / 2, 0),
            Color3.fromRGB(110 + i * 5, 110 + i * 5, 115 + i * 5), Enum.Material.Rock, mountainFolder)
    end

    -- Mountain snow cap
    CreatePart("SnowCap", Vector3.new(80, 10, 80), CFrame.new(420, 140, 0),
        Color3.fromRGB(240, 245, 255), Enum.Material.Ice, mountainFolder)

    -- Summit viewing platform
    CreatePart("SummitPlatform", Vector3.new(40, 3, 40), CFrame.new(420, 144, 0),
        Color3.fromRGB(180, 175, 190), Enum.Material.SmoothPlastic, mountainFolder)
    local summitGlow = CreatePart("SummitOrb", Vector3.new(3, 3, 3), CFrame.new(420, 148, 0),
        Color3.fromRGB(255, 255, 200), Enum.Material.Neon, mountainFolder, false)
    summitGlow.Shape = Enum.PartType.Ball
    AddNeonLight(summitGlow, Color3.fromRGB(255, 255, 200), 30, 2)

    -- Mountain path (stone steps)
    for step = 0, 9 do
        CreatePart("MtnStep_" .. step, Vector3.new(14, 2, 8),
            CFrame.new(310 + step * 15, step * 13.5, 0),
            Color3.fromRGB(120, 118, 125), Enum.Material.Cobblestone, mountainFolder)
    end

    -- ==================== CAVES REGION ====================
    local caveFolder = Instance.new("Folder")
    caveFolder.Name = "Caves"
    caveFolder.Parent = mapFolder

    CreatePart("CaveFloor", Vector3.new(180, 2, 200), CFrame.new(0, 0, 460),
        Color3.fromRGB(45, 42, 50), Enum.Material.Slate, caveFolder)
    CreatePart("CaveRoof", Vector3.new(180, 16, 200), CFrame.new(0, 44, 460),
        Color3.fromRGB(38, 35, 45), Enum.Material.Slate, caveFolder)
    CreatePart("CaveWallLeft", Vector3.new(16, 50, 200), CFrame.new(-82, 20, 460),
        Color3.fromRGB(40, 38, 48), Enum.Material.Slate, caveFolder)
    CreatePart("CaveWallRight", Vector3.new(16, 50, 200), CFrame.new(82, 20, 460),
        Color3.fromRGB(40, 38, 48), Enum.Material.Slate, caveFolder)

    -- Cave Entry Arch
    CreatePart("CaveArchLeft", Vector3.new(10, 40, 12), CFrame.new(-22, 20, 356),
        Color3.fromRGB(50, 48, 58), Enum.Material.Slate, caveFolder)
    CreatePart("CaveArchRight", Vector3.new(10, 40, 12), CFrame.new(22, 20, 356),
        Color3.fromRGB(50, 48, 58), Enum.Material.Slate, caveFolder)
    CreatePart("CaveArchTop", Vector3.new(54, 10, 12), CFrame.new(0, 37, 356),
        Color3.fromRGB(50, 48, 58), Enum.Material.Slate, caveFolder)

    -- Crystal clusters
    local crystalColors = {
        Color3.fromRGB(0, 255, 200),
        Color3.fromRGB(180, 50, 255),
        Color3.fromRGB(50, 180, 255),
        Color3.fromRGB(255, 50, 150),
    }
    for i = 1, 10 do
        local cx = math.random(-60, 60)
        local cz = math.random(380, 540)
        local cc = crystalColors[(i - 1) % #crystalColors + 1]
        local crystal = CreatePart("Crystal_" .. i,
            Vector3.new(math.random(2, 5), math.random(8, 18), math.random(2, 5)),
            CFrame.new(cx, math.random(5, 14), cz) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(math.random(-20, 20))),
            cc, Enum.Material.Neon, caveFolder, false)
        AddNeonLight(crystal, cc, math.random(15, 25), 2)
    end

    -- ==================== RUINS REGION ====================
    local ruinsFolder = Instance.new("Folder")
    ruinsFolder.Name = "Ruins"
    ruinsFolder.Parent = mapFolder

    -- Ground slab
    CreatePart("RuinsGround", Vector3.new(200, 2, 200), CFrame.new(-320, 0.5, -360),
        Color3.fromRGB(130, 125, 118), Enum.Material.Sandstone, ruinsFolder)

    -- 8 outer pillars in a circle
    for r = 1, 8 do
        local angle = (r / 8) * math.pi * 2
        local x = -320 + math.cos(angle) * 58
        local z = -360 + math.sin(angle) * 58
        local pillarH = math.random(28, 40)
        CreatePart("RuinPillar_" .. r, Vector3.new(7, pillarH, 7),
            CFrame.new(x, pillarH / 2, z),
            Color3.fromRGB(155, 148, 135), Enum.Material.Sandstone, ruinsFolder)
        -- Some crumbling tops
        if r % 2 == 0 then
            CreatePart("RuinCapstone_" .. r, Vector3.new(9, 4, 9), CFrame.new(x, pillarH + 2, z),
                Color3.fromRGB(145, 138, 125), Enum.Material.Sandstone, ruinsFolder)
        end
    end

    -- Inner ring of smaller pillars
    for r = 1, 4 do
        local angle = (r / 4) * math.pi * 2
        CreatePart("InnerPillar_" .. r, Vector3.new(4, 18, 4),
            CFrame.new(-320 + math.cos(angle) * 28, 9, -360 + math.sin(angle) * 28),
            Color3.fromRGB(140, 133, 120), Enum.Material.Sandstone, ruinsFolder)
    end

    -- Central Rune Dais
    CreatePart("RuneDais", Vector3.new(22, 2, 22), CFrame.new(-320, 1.5, -360),
        Color3.fromRGB(55, 40, 80), Enum.Material.SmoothPlastic, ruinsFolder)
    local runeGlow = CreatePart("RuneOrb", Vector3.new(4, 6, 4), CFrame.new(-320, 5, -360),
        Color3.fromRGB(180, 50, 255), Enum.Material.Neon, ruinsFolder, false)
    AddNeonLight(runeGlow, Color3.fromRGB(180, 50, 255), 35, 3.5)

    -- ==================== RIVER & BRIDGE ====================
    local riverFolder = Instance.new("Folder")
    riverFolder.Name = "River"
    riverFolder.Parent = mapFolder

    CreatePart("RiverChannel", Vector3.new(50, 2, 600), CFrame.new(-100, -1, 0),
        Color3.fromRGB(40, 100, 200), Enum.Material.Water, riverFolder, false)

    -- Bridge over river
    CreatePart("BridgeDeck", Vector3.new(54, 3, 22), CFrame.new(-100, 1, -20),
        Color3.fromRGB(120, 90, 60), Enum.Material.Wood, riverFolder)
    CreatePart("BridgeRailL", Vector3.new(54, 4, 2), CFrame.new(-100, 3.5, -30),
        Color3.fromRGB(100, 75, 50), Enum.Material.Wood, riverFolder)
    CreatePart("BridgeRailR", Vector3.new(54, 4, 2), CFrame.new(-100, 3.5, -10),
        Color3.fromRGB(100, 75, 50), Enum.Material.Wood, riverFolder)

    -- Lanterns on bridge
    for i = -2, 2 do
        local lantern = CreatePart("BridgeLantern_" .. i, Vector3.new(2, 3, 2),
            CFrame.new(-100 + i * 12, 6, -30),
            Color3.fromRGB(255, 180, 50), Enum.Material.Neon, riverFolder)
        AddNeonLight(lantern, Color3.fromRGB(255, 180, 50), 12, 2)
    end

    -- ==================== RAID ENTRANCE PORTAL ====================
    local portalFrame = CreatePart("RaidPortalGate", Vector3.new(26, 40, 5),
        CFrame.new(0, 20, -520), Color3.fromRGB(25, 18, 38), Enum.Material.Obsidian, mapFolder)

    local portalEnergy = CreatePart("PortalEnergy", Vector3.new(18, 32, 1),
        CFrame.new(0, 20, -520), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder, false)
    AddNeonLight(portalEnergy, Color3.fromRGB(180, 50, 255), 40, 4)

    local portalLabel = CreatePart("PortalSign", Vector3.new(22, 5, 1),
        CFrame.new(0, 42, -520), Color3.fromRGB(18, 14, 28), Enum.Material.SmoothPlastic, mapFolder)

    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 30
    sg.Parent = portalLabel

    local portLbl = Instance.new("TextLabel")
    portLbl.Size = UDim2.new(1, 0, 1, 0)
    portLbl.BackgroundTransparency = 1
    portLbl.Text = "RAID ENTRANCE"
    portLbl.Font = Enum.Font.GothamBlack
    portLbl.TextScaled = true
    portLbl.TextColor3 = Color3.fromRGB(255, 100, 255)
    portLbl.Parent = sg

    -- Animate portal pulse
    task.spawn(function()
        while portalEnergy.Parent do
            local t = TweenService:Create(portalEnergy, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = Color3.fromRGB(220, 80, 255),
            })
            t:Play()
            t.Completed:Wait()
            local t2 = TweenService:Create(portalEnergy, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = Color3.fromRGB(130, 30, 200),
            })
            t2:Play()
            t2.Completed:Wait()
        end
    end)

    -- Raid Portal Interaction Prompt
    local portalPrompt = Instance.new("ProximityPrompt")
    portalPrompt.ActionText = "Initiate Raid"
    portalPrompt.ObjectText = "Elemental Portal"
    portalPrompt.HoldDuration = 1.0
    portalPrompt.MaxActivationDistance = 18
    portalPrompt.RequiresLineOfSight = false
    portalPrompt.Parent = portalEnergy

    portalPrompt.Triggered:Connect(function(player)
        if not RaidService.IsActive() then
            RaidService.StartRaid(player)
        end
    end)

    -- ==================== WORLD FRAGMENTS (Collectables) ====================
    local function SpawnWorldFragment(id: string, name: string, pos: Vector3)
        local fragModel = Instance.new("Model")
        fragModel.Name = "WorldFragment_" .. id

        local gem = Instance.new("Part")
        gem.Name = "FragmentGem"
        gem.Size = Vector3.new(3.5, 5, 3.5)
        gem.Color = Color3.fromRGB(0, 220, 255)
        gem.Material = Enum.Material.Neon
        gem.Anchored = true
        gem.CanCollide = false
        gem.CFrame = CFrame.new(pos)
        gem.Parent = fragModel

        -- Inner glow orb
        local inner = Instance.new("Part")
        inner.Name = "InnerOrb"
        inner.Size = Vector3.new(2, 2, 2)
        inner.Shape = Enum.PartType.Ball
        inner.Color = Color3.fromRGB(180, 245, 255)
        inner.Material = Enum.Material.Neon
        inner.Anchored = true
        inner.CanCollide = false
        inner.CFrame = CFrame.new(pos)
        inner.Parent = fragModel

        AddNeonLight(gem, Color3.fromRGB(0, 220, 255), 25, 3)

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Collect Fragment"
        prompt.ObjectText = name
        prompt.HoldDuration = 1.5
        prompt.MaxActivationDistance = 14
        prompt.Parent = gem

        prompt.Triggered:Connect(function(player)
            local success = PlayerDataService.CollectFragment(player, id)
            if success then
                gem:Destroy()
                inner:Destroy()
                -- Fragment collected event fires on client
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local fragEvent = remotes:FindFirstChild("FragmentCollected") :: RemoteEvent?
                    if fragEvent then
                        fragEvent:FireClient(player, name)
                    end
                end
            end
        end)

        -- Floating spin animation
        task.spawn(function()
            local basePos = pos
            local baseY = basePos.Y
            while gem.Parent do
                local t = os.clock()
                local newCF = CFrame.new(basePos.X, baseY + math.sin(t * 2.2) * 1.8, basePos.Z)
                    * CFrame.Angles(0, t * 1.8, math.sin(t * 1.5) * 0.15)
                gem.CFrame = newCF
                inner.CFrame = newCF
                task.wait(0.03)
            end
        end)

        fragModel.PrimaryPart = gem
        fragModel.Parent = mapFolder
    end

    SpawnWorldFragment("ForestFragment", "Forest Whispers", Vector3.new(-240, 6, 0))
    SpawnWorldFragment("MountainFragment", "Apex Peak", Vector3.new(420, 148, 0))
    SpawnWorldFragment("CaveFragment", "Deep Crystal", Vector3.new(0, 8, 460))
    SpawnWorldFragment("RuinsFragment", "Ancient Terra", Vector3.new(-320, 6, -360))

    -- ==================== TRAINING DUMMY NPCS ====================
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then
        npcsFolder = Instance.new("Folder")
        npcsFolder.Name = "NPCs"
        npcsFolder.Parent = Workspace
    end

    local function SpawnDummy(dummyName: string, cframe: CFrame, maxHp: number)
        local dummy = Instance.new("Model")
        dummy.Name = dummyName

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Color = Color3.fromRGB(130, 90, 60)
        root.Material = Enum.Material.Wood
        root.Anchored = true
        root.CFrame = cframe
        root.Parent = dummy

        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2.5, 1.2)
        torso.Color = Color3.fromRGB(150, 110, 75)
        torso.Material = Enum.Material.Wood
        torso.Anchored = true
        torso.CFrame = cframe * CFrame.new(0, 2.25, 0)
        torso.Parent = dummy

        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(1.4, 1.4, 1.4)
        head.Color = Color3.fromRGB(210, 180, 150)
        head.Material = Enum.Material.Wood
        head.Anchored = true
        head.CFrame = cframe * CFrame.new(0, 4.5, 0)
        head.Parent = dummy

        -- Health bar above head
        local bg = Instance.new("BillboardGui")
        bg.Size = UDim2.new(0, 80, 0, 14)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = false
        bg.Parent = head

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(1, 0, 1, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        hpBg.Parent = bg

        local hpFill = Instance.new("Frame")
        hpFill.Name = "HPFill"
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(46, 214, 115)
        hpFill.Parent = hpBg

        local nameGui = Instance.new("TextLabel")
        nameGui.Size = UDim2.new(1, 0, 1, 0)
        nameGui.BackgroundTransparency = 1
        nameGui.Font = Enum.Font.GothamBold
        nameGui.TextSize = 9
        nameGui.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameGui.Text = dummyName
        nameGui.Parent = hpBg

        local hum = Instance.new("Humanoid")
        hum.MaxHealth = maxHp
        hum.Health = maxHp
        hum.Parent = dummy

        dummy.PrimaryPart = root
        dummy.Parent = npcsFolder

        -- Update health bar
        hum.HealthChanged:Connect(function(hp)
            local ratio = math.clamp(hp / maxHp, 0, 1)
            hpFill.Size = UDim2.new(ratio, 0, 1, 0)
            hpFill.BackgroundColor3 = (ratio > 0.5)
                and Color3.fromRGB(46, 214, 115)
                or (ratio > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 50, 50))
        end)

        -- Respawn on death
        hum.Died:Connect(function()
            task.delay(5.0, function()
                pcall(function() dummy:Destroy() end)
                SpawnDummy(dummyName, cframe, maxHp)
            end)
        end)
    end

    SpawnDummy("Training Dummy 1", CFrame.new(30, 2, -30), 500)
    SpawnDummy("Training Dummy 2", CFrame.new(44, 2, -30), 500)
    SpawnDummy("Training Dummy 3", CFrame.new(58, 2, -30), 500)
    SpawnDummy("Forest Goblin", CFrame.new(-175, 2, 55) * CFrame.Angles(0, math.rad(180), 0), 800)
    SpawnDummy("Forest Goblin Elder", CFrame.new(-200, 2, 30) * CFrame.Angles(0, math.rad(180), 0), 1500)
    SpawnDummy("Ruins Guardian", CFrame.new(-320, 2, -380) * CFrame.Angles(0, math.rad(45), 0), 2500)

    print("[MapService] World 1 — Ember Highlands generated successfully.")
end

return table.freeze(MapService)
