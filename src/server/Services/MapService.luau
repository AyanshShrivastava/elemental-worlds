--!strict
--[[
    Elemental Worlds: Map & Environment Service
    Configures Anime Lighting, validates Workspace named folder hierarchy,
    and sets up functional gameplay interactive objects (World Fragments,
    Raid Entrance Portal, and Combat Training Dummies) without placing crude procedural geometry.

    Follows the Game Designer specification:
    - Designer builds the map and assets in:
      Workspace.Map.Village, Workspace.Map.Forest, Workspace.Map.Cave, Workspace.Map.Ruins
    - Scripts provide clean folders, interactive hooks, and target dummies.
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

    -- ColorCorrection for anime vibrancy
    local cc = Lighting:FindFirstChild("AnimeColorCorrection") :: ColorCorrectionEffect?
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
    local bloom = Lighting:FindFirstChild("AnimeBloom") :: BloomEffect?
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "AnimeBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.55
    bloom.Size = 22
    bloom.Threshold = 1.1

    -- SunRays for anime atmosphere
    local sunRays = Lighting:FindFirstChild("AnimeSunRays") :: SunRaysEffect?
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

local function EnsureFolder(parent: Instance, name: string): Folder
    local folder = parent:FindFirstChild(name) :: Folder?
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder :: Folder
end

-- Spawns an interactive collectable World Fragment with spinning neon visual and ProximityPrompt
local function SpawnWorldFragment(id: string, name: string, pos: Vector3, parentFolder: Instance)
    local existing = parentFolder:FindFirstChild("WorldFragment_" .. id)
    if existing then return end

    local fragModel = Instance.new("Model")
    fragModel.Name = "WorldFragment_" .. id

    local gem = Instance.new("Part")
    gem.Name = "FragmentGem"
    gem.Size = Vector3.new(3, 4.5, 3)
    gem.Color = Color3.fromRGB(0, 220, 255)
    gem.Material = Enum.Material.Neon
    gem.Anchored = true
    gem.CanCollide = false
    gem.CFrame = CFrame.new(pos)
    gem.Parent = fragModel

    local inner = Instance.new("Part")
    inner.Name = "InnerOrb"
    inner.Size = Vector3.new(1.8, 1.8, 1.8)
    inner.Shape = Enum.PartType.Ball
    inner.Color = Color3.fromRGB(180, 245, 255)
    inner.Material = Enum.Material.Neon
    inner.Anchored = true
    inner.CanCollide = false
    inner.CFrame = CFrame.new(pos)
    inner.Parent = fragModel

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 220, 255)
    light.Range = 20
    light.Brightness = 2.5
    light.Parent = gem

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Collect Fragment"
    prompt.ObjectText = name
    prompt.HoldDuration = 1.0
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = gem

    prompt.Triggered:Connect(function(player)
        local success = PlayerDataService.CollectFragment(player, id)
        if success then
            gem:Destroy()
            inner:Destroy()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local fragEvent = remotes:FindFirstChild(GameConfig.REMOTES.FRAGMENT_COLLECTED) :: RemoteEvent?
                if fragEvent then
                    fragEvent:FireClient(player, name)
                end
            end
        end
    end)

    -- Idle levitation and rotation animation
    task.spawn(function()
        local baseY = pos.Y
        while gem.Parent do
            local t = os.clock()
            local newCF = CFrame.new(pos.X, baseY + math.sin(t * 2.2) * 1.2, pos.Z)
                * CFrame.Angles(0, t * 1.5, math.sin(t * 1.2) * 0.1)
            gem.CFrame = newCF
            inner.CFrame = newCF
            task.wait(0.03)
        end
    end)

    fragModel.PrimaryPart = gem
    fragModel.Parent = parentFolder
end

-- Spawns a functional Raid Entrance portal gateway prompt in Workspace.Map.Ruins
local function SetupRaidPortal(ruinsFolder: Folder)
    local existing = ruinsFolder:FindFirstChild("RaidEntrancePortal")
    if existing then return end

    local portalModel = Instance.new("Model")
    portalModel.Name = "RaidEntrancePortal"

    local frameLeft = Instance.new("Part")
    frameLeft.Name = "PillarLeft"
    frameLeft.Size = Vector3.new(3, 24, 3)
    frameLeft.CFrame = CFrame.new(-12, 12, -180)
    frameLeft.Color = Color3.fromRGB(25, 20, 35)
    frameLeft.Material = Enum.Material.Obsidian
    frameLeft.Anchored = true
    frameLeft.Parent = portalModel

    local frameRight = Instance.new("Part")
    frameRight.Name = "PillarRight"
    frameRight.Size = Vector3.new(3, 24, 3)
    frameRight.CFrame = CFrame.new(12, 12, -180)
    frameRight.Color = Color3.fromRGB(25, 20, 35)
    frameRight.Material = Enum.Material.Obsidian
    frameRight.Anchored = true
    frameRight.Parent = portalModel

    local frameTop = Instance.new("Part")
    frameTop.Name = "PillarTop"
    frameTop.Size = Vector3.new(27, 3, 3)
    frameTop.CFrame = CFrame.new(0, 24, -180)
    frameTop.Color = Color3.fromRGB(25, 20, 35)
    frameTop.Material = Enum.Material.Obsidian
    frameTop.Anchored = true
    frameTop.Parent = portalModel

    local portalEnergy = Instance.new("Part")
    portalEnergy.Name = "PortalEnergy"
    portalEnergy.Size = Vector3.new(21, 21, 1)
    portalEnergy.CFrame = CFrame.new(0, 12, -180)
    portalEnergy.Color = Color3.fromRGB(150, 40, 220)
    portalEnergy.Material = Enum.Material.Neon
    portalEnergy.Transparency = 0.25
    portalEnergy.Anchored = true
    portalEnergy.CanCollide = false
    portalEnergy.Parent = portalModel

    local pLight = Instance.new("PointLight")
    pLight.Color = Color3.fromRGB(180, 50, 255)
    pLight.Range = 24
    pLight.Brightness = 3
    pLight.Parent = portalEnergy

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Initiate Raid"
    prompt.ObjectText = "Elemental Portal"
    prompt.HoldDuration = 1.0
    prompt.MaxActivationDistance = 18
    prompt.RequiresLineOfSight = false
    prompt.Parent = portalEnergy

    prompt.Triggered:Connect(function(player)
        if not RaidService.IsActive() then
            RaidService.StartRaid(player)
        end
    end)

    portalModel.PrimaryPart = portalEnergy
    portalModel.Parent = ruinsFolder
end

-- Spawns training target dummy NPCs for combat testing
local function SetupTrainingDummies(npcsFolder: Folder)
    local function SpawnDummy(dummyName: string, cframe: CFrame, maxHp: number)
        local existing = npcsFolder:FindFirstChild(dummyName)
        if existing then return end

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

        -- Billboard health bar
        local bg = Instance.new("BillboardGui")
        bg.Size = UDim2.new(0, 90, 0, 16)
        bg.StudsOffset = Vector3.new(0, 3.2, 0)
        bg.AlwaysOnTop = false
        bg.Parent = head

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(1, 0, 1, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
        hpBg.Parent = bg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = hpBg

        local hpFill = Instance.new("Frame")
        hpFill.Name = "HPFill"
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(46, 214, 115)
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = hpFill

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = dummyName
        nameLabel.Parent = hpBg

        local hum = Instance.new("Humanoid")
        hum.MaxHealth = maxHp
        hum.Health = maxHp
        hum.Parent = dummy

        dummy.PrimaryPart = root
        dummy.Parent = npcsFolder

        hum.HealthChanged:Connect(function(hp)
            local ratio = math.clamp(hp / maxHp, 0, 1)
            hpFill.Size = UDim2.new(ratio, 0, 1, 0)
            hpFill.BackgroundColor3 = (ratio > 0.5)
                and Color3.fromRGB(46, 214, 115)
                or (ratio > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 50, 50))
        end)

        hum.Died:Connect(function()
            task.delay(4.0, function()
                pcall(function() dummy:Destroy() end)
                SpawnDummy(dummyName, cframe, maxHp)
            end)
        end)
    end

    SpawnDummy("Training Dummy 1", CFrame.new(25, 2, -25), 500)
    SpawnDummy("Training Dummy 2", CFrame.new(40, 2, -25), 500)
    SpawnDummy("Training Dummy 3", CFrame.new(55, 2, -25), 500)
    SpawnDummy("Target Dummy (Boss)", CFrame.new(70, 2, -25), 2500)
end

function MapService.BuildWorld1()
    SetupAnimeLighting()

    -- Ensure clean spec folder hierarchy exists
    local mapFolder = EnsureFolder(Workspace, "Map")
    local villageFolder = EnsureFolder(mapFolder, "Village")
    local forestFolder = EnsureFolder(mapFolder, "Forest")
    local caveFolder = EnsureFolder(mapFolder, "Cave")
    local ruinsFolder = EnsureFolder(mapFolder, "Ruins")

    local npcsFolder = EnsureFolder(Workspace, "NPCs")
    local vfxFolder = EnsureFolder(Workspace, "VFX")
    local spawnsFolder = EnsureFolder(Workspace, "SpawnLocations")

    -- Set up functional interactive items (Fragments, Raid Portal, Combat Dummies)
    SpawnWorldFragment("ForestFragment", "Forest Whispers", Vector3.new(-80, 4, 60), forestFolder)
    SpawnWorldFragment("VillageFragment", "Village Solace", Vector3.new(40, 4, 40), villageFolder)
    SpawnWorldFragment("CaveFragment", "Deep Crystal", Vector3.new(0, 4, 120), caveFolder)
    SpawnWorldFragment("RuinsFragment", "Ancient Terra", Vector3.new(-60, 4, -120), ruinsFolder)

    SetupRaidPortal(ruinsFolder)
    SetupTrainingDummies(npcsFolder)

    print("[MapService] Clean environment initialized — Folders, Anime Lighting, Fragments, and Combat Dummies ready.")
end

return table.freeze(MapService)
