--!strict
--[[
    Elemental Worlds: Creator Perks Service (Blox Fruits Modern Design)
    Applies modern, high-end prestige visuals to the owner (coolzgamer9 / UserId 6225357795)
    and VIP gamepass holders.
    
    Aesthetic rules:
    - NO rainbow color cycling
    - NO tacky gold models or spinning cylinders
    - Modern dark obsidian-navy badges with electric indigo/cyan glow
    - Minimalist ambient body auras and particle trails
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CreatorPerksService = {}

-- Modern Blox Fruits style color tokens
local CREATOR_ACCENT = Color3.fromRGB(130, 95, 255)   -- Electric Astral Purple
local VIP_ACCENT = Color3.fromRGB(0, 170, 255)        -- Electric Royal Azure
local BADGE_BG = Color3.fromRGB(10, 14, 22)           -- Obsidian Navy
local TEXT_COLOR = Color3.fromRGB(245, 248, 255)       -- Crisp White

-- Creates a sleek, modern overhead title badge (Blox Fruits style)
local function CreateOverheadBadge(character: Model, prefix: string, playerName: string, accentColor: Color3)
    local head = character:FindFirstChild("Head") :: BasePart?
    if not head then return end

    -- Clean up any existing badge
    local existing = head:FindFirstChild("OverheadBadgeGui")
    if existing then existing:Destroy() end

    local billGui = Instance.new("BillboardGui")
    billGui.Name = "OverheadBadgeGui"
    billGui.Size = UDim2.new(0, 210, 0, 36)
    billGui.StudsOffset = Vector3.new(0, 2.8, 0)
    billGui.AlwaysOnTop = false
    billGui.MaxDistance = 80
    billGui.Parent = head

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = BADGE_BG
    container.BackgroundTransparency = 0.12
    container.Parent = billGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.8
    stroke.Transparency = 0.1
    stroke.Parent = container

    -- Title tag (e.g. [ CREATOR ] or [ VIP ])
    local tagLabel = Instance.new("TextLabel")
    tagLabel.Name = "Tag"
    tagLabel.Size = UDim2.new(0, 90, 1, 0)
    tagLabel.Position = UDim2.new(0, 8, 0, 0)
    tagLabel.BackgroundTransparency = 1
    tagLabel.Font = Enum.Font.GothamBlack
    tagLabel.TextSize = 12
    tagLabel.TextColor3 = accentColor
    tagLabel.TextXAlignment = Enum.TextXAlignment.Left
    tagLabel.Text = prefix
    tagLabel.Parent = container

    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, -100, 1, 0)
    nameLabel.Position = UDim2.new(0, 95, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = TEXT_COLOR
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = playerName
    nameLabel.Parent = container

    -- Subtle breathing stroke animation
    task.spawn(function()
        while container.Parent do
            local t1 = TweenService:Create(stroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 2.4, Transparency = 0 })
            local t2 = TweenService:Create(stroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 1.5, Transparency = 0.3 })
            t1:Play()
            t1.Completed:Wait()
            t2:Play()
            t2.Completed:Wait()
        end
    end)
end

-- Attaches a sleek modern ambient aura (PointLight + gentle energy particles)
local function AttachModernAura(character: Model, color: Color3, isCreator: boolean)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    -- Remove any old lights
    local oldLight = rootPart:FindFirstChild("ModernAuraLight")
    if oldLight then oldLight:Destroy() end
    local oldAttach = rootPart:FindFirstChild("ModernAuraAttach")
    if oldAttach then oldAttach:Destroy() end

    -- Ambient PointLight
    local light = Instance.new("PointLight")
    light.Name = "ModernAuraLight"
    light.Color = color
    light.Range = if isCreator then 16 else 12
    light.Brightness = if isCreator then 1.5 else 1.0
    light.Parent = rootPart

    -- Subtle particle attachment
    local attach = Instance.new("Attachment")
    attach.Name = "ModernAuraAttach"
    attach.Position = Vector3.new(0, -1.5, 0)
    attach.Parent = rootPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PrestigeParticles"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.4, color),
        ColorSequenceKeypoint.new(1, color),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.8, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Rate = if isCreator then 12 else 6
    emitter.Speed = NumberRange.new(2, 4)
    emitter.SpreadAngle = Vector2.new(20, 20)
    emitter.Lifetime = NumberRange.new(0.8, 1.4)
    emitter.LightEmission = 0.9
    emitter.LightInfluence = 0
    emitter.VelocitySpread = 20
    emitter.Parent = attach
end

function CreatorPerksService.ApplyCreatorVisuals(player: Player)
    local char = player.Character
    if not char then return end

    local isOwner = (player.UserId == GameConfig.OWNER_USER_ID)
    local profile = PlayerDataService.GetProfile(player)
    local hasVIP = profile and profile.GamePasses["VIPMaster"] or false

    if isOwner then
        -- Creator aura (subtle ambient lighting only, no overhead card)
        AttachModernAura(char, CREATOR_ACCENT, true)
    elseif hasVIP then
        -- VIP aura
        AttachModernAura(char, VIP_ACCENT, false)
    end
end

return table.freeze(CreatorPerksService)
