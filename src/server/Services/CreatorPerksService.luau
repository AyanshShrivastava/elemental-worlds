--!strict
--[[
    Elemental Worlds: Creator Exclusive Perks & Visual Recognition
    Authenticates coolzgamer9 (UserId 6225357795).
    Spawns an exclusive Creator Crown, animated overhead title, and Creator Godly Aura.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConfig = require(script.Parent.Parent.Shared.Config.GameConfig)

local CreatorPerksService = {}

function CreatorPerksService.ApplyCreatorVisuals(player: Player)
    if player.UserId ~= GameConfig.OWNER_USER_ID then
        return
    end

    local character = player.Character
    if not character then return end

    local head = character:WaitForChild("Head", 5) :: BasePart?
    local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
    if not head or not root then return end

    -- Remove existing perks if present
    local existingTitle = head:FindFirstChild("CreatorOverheadTitle")
    if existingTitle then existingTitle:Destroy() end

    -- 1. Exclusive Overhead Title BillboardGui
    local titleGui = Instance.new("BillboardGui")
    titleGui.Name = "CreatorOverheadTitle"
    titleGui.Size = UDim2.new(0, 220, 0, 50)
    titleGui.StudsOffset = Vector3.new(0, 3.2, 0)
    titleGui.AlwaysOnTop = true
    titleGui.Adornee = head
    titleGui.Parent = head

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.Size = UDim2.new(1, 0, 0, 18)
    badgeLabel.Position = UDim2.new(0, 0, 0, 0)
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Font = Enum.Font.GothamBlack
    badgeLabel.TextSize = 13
    badgeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    badgeLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
    badgeLabel.TextStrokeTransparency = 0.2
    badgeLabel.Text = "👑 CREATOR & DESIGNER 👑"
    badgeLabel.Parent = titleGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 24)
    nameLabel.Position = UDim2.new(0, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(150, 0, 255)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.Text = "coolzgamer9"
    nameLabel.Parent = titleGui

    -- 2. Floating Golden Crown
    local crown = Instance.new("Part")
    crown.Name = "CreatorCrown"
    crown.Size = Vector3.new(2.2, 0.8, 2.2)
    crown.Color = Color3.fromRGB(255, 215, 0)
    crown.Material = Enum.Material.Neon
    crown.CanCollide = false
    crown.Anchored = false
    crown.Parent = character

    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = crown
    weld.C0 = CFrame.new(0, 1.8, 0)
    weld.Parent = crown

    -- Golden particle sparklers
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "CrownSparkles"
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 235, 100), Color3.fromRGB(255, 180, 0))
    emitter.Size = NumberSequence.new(0.4, 0.1)
    emitter.Speed = NumberRange.new(1, 3)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(0.5, 0.9)
    emitter.LightEmission = 1.0
    emitter.Rate = 15
    emitter.Parent = crown

    print("[CreatorPerksService] Bestowed Creator Crown & Title on coolzgamer9.")
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        CreatorPerksService.ApplyCreatorVisuals(player)
    end)
    if player.Character then
        CreatorPerksService.ApplyCreatorVisuals(player)
    end
end)

return table.freeze(CreatorPerksService)
