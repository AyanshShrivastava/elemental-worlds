--!strict
--[[
    Elemental Worlds: Enterprise Raid Progression & Boss Battle Service
    Orchestrates dynamic, multi-wave elemental boss raids (Blox Fruits style).
    
    Features:
    - 3 Scaled Waves:
        Wave 1: Corrupted Elementals (Mob swarm)
        Wave 2: Highland Wardens (Elite mini-bosses)
        Wave 3: Infernal Colossus (Titan Boss with 8,000 HP & dynamic boss bar)
    - Global raid progress announcements
    - Auto-rewards: +3 Levels, +20 Charges, +2 Spin Tickets on Boss Defeat
    - Clean cleanup of all raid instances after victory or failure
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local RaidService = {}

local isRaidActive = false
local currentWave = 0
local activeRaidEnemies: { Model } = {}
local raidParticipants: { [Player]: boolean } = {}
local raidFolder: Folder? = nil

-- Global notification helper
local function BroadcastAnnouncement(message: string)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local announceEvent = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
        if announceEvent then
            announceEvent:FireAllClients(message)
        end
    end
end

-- Creates an elite raid combatant with overhead health bar
local function SpawnRaidMob(name: string, cframe: CFrame, maxHp: number, color: Color3, sizeScale: number): Model
    local mob = Instance.new("Model")
    mob.Name = name

    local scale = sizeScale or 1.0

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2 * scale, 2 * scale, 1 * scale)
    root.Color = color
    root.Material = Enum.Material.SmoothPlastic
    root.Anchored = false
    root.CFrame = cframe
    root.Parent = mob

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2 * scale, 2.5 * scale, 1.2 * scale)
    torso.Color = color
    torso.Material = Enum.Material.Neon
    torso.Anchored = false
    torso.CFrame = cframe * CFrame.new(0, 2.25 * scale, 0)
    torso.Parent = mob

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = torso
    weld.Parent = root

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.4 * scale)
    head.Color = Color3.fromRGB(240, 240, 255)
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = false
    head.CFrame = cframe * CFrame.new(0, 4.5 * scale, 0)
    head.Parent = mob

    local headWeld = Instance.new("WeldConstraint")
    headWeld.Part0 = torso
    headWeld.Part1 = head
    headWeld.Parent = torso

    -- Modern Blox Fruits style overhead health bar
    local bg = Instance.new("BillboardGui")
    bg.Name = "BossHealthGui"
    bg.Size = UDim2.new(0, 140 * scale, 0, 22 * scale)
    bg.StudsOffset = Vector3.new(0, 3.5 * scale, 0)
    bg.AlwaysOnTop = true
    bg.Parent = head

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 1, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    barBg.BackgroundTransparency = 0.1
    barBg.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = barBg

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.8
    stroke.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(235, 60, 75)
    barFill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = barFill

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 11 * scale
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Text = name .. " [" .. tostring(maxHp) .. " HP]"
    titleLbl.Parent = barBg

    local hum = Instance.new("Humanoid")
    hum.MaxHealth = maxHp
    hum.Health = maxHp
    hum.WalkSpeed = 16
    hum.Parent = mob

    hum.HealthChanged:Connect(function(hp)
        local ratio = math.clamp(hp / maxHp, 0, 1)
        barFill.Size = UDim2.new(ratio, 0, 1, 0)
        titleLbl.Text = string.format("%s [%d/%d]", name, math.round(hp), maxHp)
    end)

    mob.PrimaryPart = root

    local parentFolder = raidFolder or Workspace
    mob.Parent = parentFolder

    -- Basic AI chase nearest participant
    task.spawn(function()
        while mob.Parent and hum.Health > 0 do
            local nearestRoot: BasePart? = nil
            local minDist = 150
            for player in raidParticipants do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local pRoot = player.Character.HumanoidRootPart :: BasePart
                    local d = (pRoot.Position - root.Position).Magnitude
                    if d < minDist then
                        minDist = d
                        nearestRoot = pRoot
                    end
                end
            end

            if nearestRoot then
                hum:MoveTo(nearestRoot.Position)
            end
            task.wait(1.5)
        end
    end)

    return mob
end

-- Advances to the next wave or finishes the raid
local function NextWave()
    if not isRaidActive then return end
    currentWave += 1

    table.clear(activeRaidEnemies)

    if currentWave == 1 then
        BroadcastAnnouncement("[RAID WAVE 1/3] Corrupted Elementals have spawned!")
        local spawnCenter = Vector3.new(0, 4, -480)
        for i = 1, 4 do
            local angle = (i / 4) * math.pi * 2
            local pos = spawnCenter + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
            local mob = SpawnRaidMob("Corrupted Sentinel " .. i, CFrame.new(pos), 800, Color3.fromRGB(150, 60, 255), 1.0)
            table.insert(activeRaidEnemies, mob)

            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function()
                    for idx, e in activeRaidEnemies do
                        if e == mob then
                            table.remove(activeRaidEnemies, idx)
                            break
                        end
                    end
                    if #activeRaidEnemies == 0 then
                        task.delay(2.0, NextWave)
                    end
                end)
            end
        end
    elseif currentWave == 2 then
        BroadcastAnnouncement("[RAID WAVE 2/3] Highland Wardens approaching!")
        local spawnCenter = Vector3.new(0, 4, -480)
        for i = 1, 2 do
            local offset = if i == 1 then Vector3.new(-18, 0, 0) else Vector3.new(18, 0, 0)
            local mob = SpawnRaidMob("Highland Warden " .. i, CFrame.new(spawnCenter + offset), 2200, Color3.fromRGB(0, 180, 255), 1.3)
            table.insert(activeRaidEnemies, mob)

            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function()
                    for idx, e in activeRaidEnemies do
                        if e == mob then
                            table.remove(activeRaidEnemies, idx)
                            break
                        end
                    end
                    if #activeRaidEnemies == 0 then
                        task.delay(2.5, NextWave)
                    end
                end)
            end
        end
    elseif currentWave == 3 then
        BroadcastAnnouncement("[RAID FINAL BOSS] INFERNAL TITAN has awakened! Defeat the Colossus!")
        local boss = SpawnRaidMob("INFERNAL TITAN", CFrame.new(0, 6, -480), 8000, Color3.fromRGB(255, 60, 40), 2.2)
        table.insert(activeRaidEnemies, boss)

        local hum = boss:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                RaidService.EndRaid(true)
            end)
        end
    end
end

-- Starts a full raid session
function RaidService.StartRaid(initiator: Player?): boolean
    if isRaidActive then
        return false -- Already active
    end

    isRaidActive = true
    currentWave = 0
    table.clear(raidParticipants)

    -- Register nearby players as participants
    local portalPos = Vector3.new(0, 20, -520)
    for _, player in Players:GetPlayers() do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - portalPos).Magnitude
            if dist <= 120 or player == initiator then
                raidParticipants[player] = true
            end
        end
    end

    -- Setup raid folder
    raidFolder = Instance.new("Folder")
    raidFolder.Name = "ActiveRaidFolder"
    raidFolder.Parent = Workspace

    BroadcastAnnouncement(string.format("[RAID] Elemental Raid initiated by [%s]! Defend the Highlands!", initiator and initiator.Name or "Server"))

    task.delay(2.0, NextWave)
    return true
end

-- Ends raid session and distributes rewards
function RaidService.EndRaid(victory: boolean)
    if not isRaidActive then return end
    isRaidActive = false

    if victory then
        BroadcastAnnouncement("[RAID VICTORY] The Infernal Titan has fallen! Rewards awarded to all heroes!")
        for player in raidParticipants do
            if player.Parent then
                PlayerDataService.AddLevel(player, GameConfig.RAID_LEVEL_REWARD)
                PlayerDataService.AddCharges(player, GameConfig.RAID_CHARGES_REWARD)
                PlayerDataService.AddSpinTickets(player, 2)
            end
        end
    else
        BroadcastAnnouncement("[RAID DEFEAT] The Raid has concluded.")
    end

    task.delay(3.0, function()
        if raidFolder then
            pcall(function() raidFolder:Destroy() end)
            raidFolder = nil
        end
        table.clear(activeRaidEnemies)
        table.clear(raidParticipants)
    end)
end

function RaidService.IsActive(): boolean
    return isRaidActive
end

function RaidService.CompleteRaid(player: Player)
    PlayerDataService.AddLevel(player, GameConfig.RAID_LEVEL_REWARD)
    PlayerDataService.AddCharges(player, GameConfig.RAID_CHARGES_REWARD)
    PlayerDataService.AddSpinTickets(player, 2)
    BroadcastAnnouncement(string.format("[%s] completed an Elemental Raid! +%d Levels, +%d Charges, +2 Spins!",
        player.Name, GameConfig.RAID_LEVEL_REWARD, GameConfig.RAID_CHARGES_REWARD))
end

return table.freeze(RaidService)
