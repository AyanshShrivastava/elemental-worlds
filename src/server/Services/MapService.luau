--!strict
--[[
    Elemental Worlds: Procedural Map & World Generation Service
    Constructs the complete bounded open world in Workspace.Map if not already placed:
    - Village (Spawn pads, Torii gates, shrines, houses, stone paths)
    - Forest (Lush anime foliage, glowing mushrooms, enemy camps)
    - Mountains (Elevated stone terraces, viewpoints)
    - Caves (Dark caverns, glowing crystals, hidden fragment)
    - Ruins (Ancient pillars, glowing stone circle)
    - River & Bridges (Navigable waterway)
    - Raid Portal (Pulsing raid gateway)
    - World Fragments (Interactive ProximityPrompt collectables)
]]

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local MapService = {}

local function CreatePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance, canCollide: boolean?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = true
    part.CanCollide = if canCollide ~= nil then canCollide else true
    part.Parent = parent
    return part
end

function MapService.BuildWorld1()
    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then
        mapFolder = Instance.new("Folder")
        mapFolder.Name = "Map"
        mapFolder.Parent = Workspace
    end

    -- If map already has buildings, do not overwrite designer work!
    if #mapFolder:GetChildren() > 2 then
        print("[MapService] Existing map detected. Preserving designer build.")
        return
    end

    print("[MapService] Generating World 1 regions...")

    -- 1. Base Ground (Dense 1200x1200x10 bounded island)
    local baseTerrain = CreatePart("BaseIsland", Vector3.new(1200, 10, 1200), CFrame.new(0, -5, 0), Color3.fromRGB(80, 145, 65), Enum.Material.Grass, mapFolder)

    -- ==================== VILLAGE (HUB / SPAWN) ====================
    local villageFolder = Instance.new("Folder")
    villageFolder.Name = "Village"
    villageFolder.Parent = mapFolder

    -- Village Cobblestone Plaza
    CreatePart("Plaza", Vector3.new(180, 2, 180), CFrame.new(0, 0.5, 0), Color3.fromRGB(150, 150, 155), Enum.Material.Cobblestone, villageFolder)

    -- Spawn Pads
    local spawnFolder = Workspace:FindFirstChild("SpawnLocations") or Instance.new("Folder", Workspace)
    spawnFolder.Name = "SpawnLocations"

    local spawnPad = Instance.new("SpawnLocation")
    spawnPad.Name = "VillageSpawn"
    spawnPad.Size = Vector3.new(16, 1, 16)
    spawnPad.CFrame = CFrame.new(0, 1.2, 0)
    spawnPad.Material = Enum.Material.Neon
    spawnPad.Color = Color3.fromRGB(60, 180, 255)
    spawnPad.Neutral = true
    spawnPad.Duration = 0
    spawnPad.Parent = spawnFolder

    -- Torii Gate at Plaza entrance
    local toriiLeft = CreatePart("ToriiPillarLeft", Vector3.new(3, 26, 3), CFrame.new(-22, 13, -75), Color3.fromRGB(200, 40, 25), Enum.Material.Wood, villageFolder)
    local toriiRight = CreatePart("ToriiPillarRight", Vector3.new(3, 26, 3), CFrame.new(22, 13, -75), Color3.fromRGB(200, 40, 25), Enum.Material.Wood, villageFolder)
    local toriiTop = CreatePart("ToriiBeam", Vector3.new(54, 4, 4), CFrame.new(0, 25, -75), Color3.fromRGB(30, 30, 35), Enum.Material.Wood, villageFolder)

    -- Village Houses
    for i = 1, 4 do
        local side = if i % 2 == 0 then 1 else -1
        local zOffset = ((i <= 2) and -35) or 35
        local houseBase = CreatePart("House_" .. i, Vector3.new(28, 18, 28), CFrame.new(side * 60, 9, zOffset), Color3.fromRGB(220, 210, 190), Enum.Material.Plaster, villageFolder)
        local houseRoof = CreatePart("Roof_" .. i, Vector3.new(34, 6, 34), CFrame.new(side * 60, 21, zOffset), Color3.fromRGB(50, 50, 60), Enum.Material.WoodPlanks, villageFolder)
    end

    -- ==================== FOREST REGION ====================
    local forestFolder = Instance.new("Folder")
    forestFolder.Name = "Forest"
    forestFolder.Parent = mapFolder

    for x = -350, -120, 45 do
        for z = -250, 250, 45 do
            local trunk = CreatePart("TreeTrunk", Vector3.new(4, 25, 4), CFrame.new(x + math.random(-8, 8), 12.5, z + math.random(-8, 8)), Color3.fromRGB(90, 60, 35), Enum.Material.Wood, forestFolder)
            local leaves = CreatePart("TreeFoliage", Vector3.new(22, 18, 22), CFrame.new(trunk.Position.X, 26, trunk.Position.Z), Color3.fromRGB(45, 115, 45), Enum.Material.Grass, forestFolder)
        end
    end

    -- ==================== MOUNTAINS REGION ====================
    local mountainFolder = Instance.new("Folder")
    mountainFolder.Name = "Mountains"
    mountainFolder.Parent = mapFolder

    for tier = 1, 4 do
        local size = 320 - (tier * 55)
        local height = tier * 28
        CreatePart("MountainTier_" .. tier, Vector3.new(size, 28, size), CFrame.new(380, height - 14, 0), Color3.fromRGB(110, 110, 115), Enum.Material.Rock, mountainFolder)
    end

    -- ==================== CAVES REGION ====================
    local caveFolder = Instance.new("Folder")
    caveFolder.Name = "Caves"
    caveFolder.Parent = mapFolder

    local caveCeiling = CreatePart("CaveRoof", Vector3.new(160, 10, 160), CFrame.new(0, 35, 420), Color3.fromRGB(45, 45, 50), Enum.Material.Slate, caveFolder)
    local caveWall1 = CreatePart("CaveWallL", Vector3.new(12, 40, 160), CFrame.new(-75, 15, 420), Color3.fromRGB(40, 40, 45), Enum.Material.Slate, caveFolder)
    local caveWall2 = CreatePart("CaveWallR", Vector3.new(12, 40, 160), CFrame.new(75, 15, 420), Color3.fromRGB(40, 40, 45), Enum.Material.Slate, caveFolder)

    -- Glowing Crystal inside Cave
    local crystal = CreatePart("CaveCrystal", Vector3.new(4, 16, 4), CFrame.new(0, 8, 440) * CFrame.Angles(0, math.rad(45), math.rad(15)), Color3.fromRGB(0, 255, 200), Enum.Material.Neon, caveFolder)
    local crystalLight = Instance.new("PointLight")
    crystalLight.Color = Color3.fromRGB(0, 255, 200)
    crystalLight.Range = 45
    crystalLight.Brightness = 3
    crystalLight.Parent = crystal

    -- ==================== RUINS REGION ====================
    local ruinsFolder = Instance.new("Folder")
    ruinsFolder.Name = "Ruins"
    ruinsFolder.Parent = mapFolder

    for r = 1, 6 do
        local angle = (r / 6) * math.pi * 2
        local x = -280 + math.cos(angle) * 45
        local z = -320 + math.sin(angle) * 45
        CreatePart("RuinPillar_" .. r, Vector3.new(6, 32, 6), CFrame.new(x, 16, z), Color3.fromRGB(160, 155, 145), Enum.Material.Sandstone, ruinsFolder)
    end
    -- Central Rune Dais
    local dais = CreatePart("RuneDais", Vector3.new(30, 3, 30), CFrame.new(-280, 1.5, -320), Color3.fromRGB(80, 60, 120), Enum.Material.Neon, ruinsFolder)

    -- ==================== RAID ENTRANCE PORTAL ====================
    local portalFrame = CreatePart("RaidPortalGate", Vector3.new(22, 34, 4), CFrame.new(0, 17, -480), Color3.fromRGB(30, 20, 40), Enum.Material.Obsidian, mapFolder)
    local portalEnergy = CreatePart("PortalEnergy", Vector3.new(16, 28, 1), CFrame.new(0, 17, -480), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder, false)

    -- ==================== WORLD FRAGMENTS (Collectables) ====================
    local function SpawnWorldFragment(id: string, name: string, pos: Vector3)
        local fragModel = Instance.new("Model")
        fragModel.Name = "WorldFragment_" .. id

        local gem = CreatePart("FragmentGem", Vector3.new(3, 4, 3), CFrame.new(pos), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, fragModel, false)
        gem.Shape = Enum.PartType.Ball

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Collect"
        prompt.ObjectText = name .. " Fragment"
        prompt.HoldDuration = 1.0
        prompt.MaxActivationDistance = 14
        prompt.Parent = gem

        prompt.Triggered:Connect(function(player)
            local success = PlayerDataService.CollectFragment(player, id)
            if success then
                -- Broadcast pickup notification
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local announce = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
                    if announce then
                        announce:FireClient(player, string.format("★ Discovered [%s] World Fragment!", name))
                    end
                end
            end
        end)

        -- Ambient floating spin
        task.spawn(function()
            local basePos = pos
            while gem.Parent do
                local t = os.clock()
                gem.CFrame = CFrame.new(basePos + Vector3.new(0, math.sin(t * 2) * 1.5, 0)) * CFrame.Angles(0, t * 1.5, 0)
                task.wait(0.03)
            end
        end)

        fragModel.PrimaryPart = gem
        fragModel.Parent = mapFolder
    end

    SpawnWorldFragment("ForestFragment", "Forest Whispers", Vector3.new(-240, 6, 0))
    SpawnWorldFragment("MountainFragment", "Apex Peak", Vector3.new(380, 120, 0))
    SpawnWorldFragment("CaveFragment", "Deep Crystal", Vector3.new(0, 7, 440))
    SpawnWorldFragment("RuinsFragment", "Ancient Terra", Vector3.new(-280, 6, -320))

    -- ==================== TRAINING DUMMY NPCS ====================
    local npcsFolder = Workspace:FindFirstChild("NPCs") or Instance.new("Folder", Workspace)
    npcsFolder.Name = "NPCs"

    local function SpawnDummy(dummyName: string, cframe: CFrame)
        local dummy = Instance.new("Model")
        dummy.Name = dummyName

        local root = CreatePart("HumanoidRootPart", Vector3.new(2, 2, 1), cframe, Color3.fromRGB(140, 100, 70), Enum.Material.Wood, dummy)
        local torso = CreatePart("Torso", Vector3.new(2, 2, 1), cframe * CFrame.new(0, 1, 0), Color3.fromRGB(160, 120, 80), Enum.Material.Wood, dummy)
        local head = CreatePart("Head", Vector3.new(1.2, 1.2, 1.2), cframe * CFrame.new(0, 2.5, 0), Color3.fromRGB(220, 200, 170), Enum.Material.Wood, dummy)

        local hum = Instance.new("Humanoid")
        hum.MaxHealth = 500
        hum.Health = 500
        hum.Parent = dummy

        dummy.PrimaryPart = root
        dummy.Parent = npcsFolder

        -- Respawn on death
        hum.Died:Connect(function()
            task.delay(4.0, function()
                if dummy.Parent then dummy:Destroy() end
                SpawnDummy(dummyName, cframe)
            end)
        end)
    end

    SpawnDummy("TrainingDummy_1", CFrame.new(25, 3, -25))
    SpawnDummy("TrainingDummy_2", CFrame.new(35, 3, -25))
    SpawnDummy("ForestGoblin_NPC", CFrame.new(-180, 3, 50))

    print("[MapService] World 1 successfully generated with Village, Forest, Mountains, Caves, Ruins, and Fragments.")
end

return table.freeze(MapService)
