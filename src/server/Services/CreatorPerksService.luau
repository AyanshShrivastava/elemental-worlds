--!strict
--[[
    Elemental Worlds: Creator Perks Service
    Applies exclusive visual and gameplay perks to the owner (coolzgamer9 / UserId 6225357795).
    - Golden floating crown model above head
    - Animated rainbow body aura (PointLight + color cycle)
    - Holographic "CREATOR" name overhead tag
    - VIP gold ambient glow for VIP pass holders
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CreatorPerksService = {}

-- VIP aura colors cycling
local VIP_AURA_COLORS = {
    Color3.fromRGB(255, 215, 0),
    Color3.fromRGB(255, 165, 0),
    Color3.fromRGB(255, 100, 50),
    Color3.fromRGB(255, 215, 0),
}

local function CreateOverheadTag(character: Model, text: string, color: Color3)
    -- Remove any existing tag
    local existing = character:FindFirstChild("OverheadTagGui")
    if existing then existing:Destroy() end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local head = character:FindFirstChild("Head") :: BasePart?
    if not head then return end

    local billGui = Instance.new("BillboardGui")
    billGui.Name = "OverheadTagGui"
    billGui.Size = UDim2.new(0, 180, 0, 50)
    billGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billGui.AlwaysOnTop = false
    billGui.Parent = head

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
    bg.BackgroundTransparency = 0.15
    bg.Parent = billGui

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 8)
    bgCorner.Parent = bg

    local bgStroke = Instance.new("UIStroke")
    bgStroke.Color = color
    bgStroke.Thickness = 2
    bgStroke.Parent = bg

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 16
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.4
    label.Parent = bg

    -- Animate stroke color pulse
    task.spawn(function()
        while bg.Parent do
            local tween1 = TweenService:Create(bgStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 3.5 })
            local tween2 = TweenService:Create(bgStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Thickness = 1.5 })
            tween1:Play()
            tween1.Completed:Wait()
            tween2:Play()
            tween2.Completed:Wait()
        end
    end)
end

local function ApplyCrownModel(character: Model)
    local head = character:FindFirstChild("Head") :: BasePart?
    if not head then return end

    -- Remove existing crown
    local existing = character:FindFirstChild("CreatorCrown")
    if existing then existing:Destroy() end

    -- Build a simple crown from 5 wedge-like parts
    local crownModel = Instance.new("Model")
    crownModel.Name = "CreatorCrown"
    crownModel.Parent = character

    local baseRing = Instance.new("Part")
    baseRing.Name = "CrownBase"
    baseRing.Shape = Enum.PartType.Cylinder
    baseRing.Size = Vector3.new(0.3, 2.4, 2.4)
    baseRing.Color = Color3.fromRGB(255, 215, 0)
    baseRing.Material = Enum.Material.Neon
    baseRing.Anchored = false
    baseRing.CanCollide = false
    baseRing.CastShadow = false
    baseRing.Parent = crownModel

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 215, 0)
    light.Range = 14
    light.Brightness = 2.5
    light.Parent = baseRing

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = baseRing
    weld.Part1 = head
    weld.Parent = baseRing

    baseRing.CFrame = head.CFrame * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90))

    -- Animate glow
    task.spawn(function()
        local colors = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 240, 100) }
        local i = 1
        while baseRing.Parent do
            i = (i % #colors) + 1
            TweenService:Create(light, TweenInfo.new(1.5, Enum.EasingStyle.Sine), { Color = colors[i], Brightness = 3 }):Play()
            task.wait(1.5)
        end
    end)
end

local function ApplyRainbowAura(character: Model)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    -- Remove existing aura light
    local existing = rootPart:FindFirstChild("CreatorAuraLight")
    if existing then existing:Destroy() end

    local auraLight = Instance.new("PointLight")
    auraLight.Name = "CreatorAuraLight"
    auraLight.Color = Color3.fromRGB(255, 0, 255)
    auraLight.Range = 22
    auraLight.Brightness = 2
    auraLight.Parent = rootPart

    -- Cycle through rainbow colors
    task.spawn(function()
        local hue = 0
        while auraLight.Parent do
            hue = (hue + 0.008) % 1
            auraLight.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(0.04)
        end
    end)
end

local function ApplyVIPAura(character: Model)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then return end

    local existing = rootPart:FindFirstChild("VIPAuraLight")
    if existing then existing:Destroy() end

    local vipLight = Instance.new("PointLight")
    vipLight.Name = "VIPAuraLight"
    vipLight.Color = Color3.fromRGB(255, 215, 0)
    vipLight.Range = 16
    vipLight.Brightness = 1.5
    vipLight.Parent = rootPart

    task.spawn(function()
        while vipLight.Parent do
            TweenService:Create(vipLight, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Brightness = 3 }):Play()
            task.wait(1.5)
            TweenService:Create(vipLight, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Brightness = 1 }):Play()
            task.wait(1.5)
        end
    end)
end

function CreatorPerksService.ApplyCreatorVisuals(player: Player)
    local char = player.Character
    if not char then return end

    local isOwner = (player.UserId == GameConfig.OWNER_USER_ID)
    local profile = PlayerDataService.GetProfile(player)
    local hasVIP = profile and profile.GamePasses["VIPMaster"] or false

    if isOwner then
        -- Crown, rainbow aura, CREATOR tag
        task.spawn(ApplyCrownModel, char)
        task.spawn(ApplyRainbowAura, char)
        CreateOverheadTag(char, "[CREATOR] coolzgamer9", Color3.fromRGB(255, 215, 0))
    elseif hasVIP then
        -- VIP gold aura, VIP tag
        task.spawn(ApplyVIPAura, char)
        CreateOverheadTag(char, "[VIP] " .. player.Name, Color3.fromRGB(255, 200, 50))
    end
end

return table.freeze(CreatorPerksService)
