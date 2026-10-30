--!strict
--[[
    Elemental Worlds: 3D Floating Damage Numbers Controller (Blox Fruits Modern Design)
    Renders dynamic, bouncing damage text in world-space with element-specific color accents
    and anime impact pop scale.
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageNumbersController = {}

local ELEMENT_TEXT_COLORS = {
    Fire  = Color3.fromRGB(255, 90, 40),
    Aqua  = Color3.fromRGB(0, 180, 255),
    Earth = Color3.fromRGB(180, 130, 75),
    Light = Color3.fromRGB(255, 235, 120),
    Wind  = Color3.fromRGB(80, 235, 160),
    Error = Color3.fromRGB(255, 30, 150),
    Time  = Color3.fromRGB(140, 95, 255),
}

function DamageNumbersController.SpawnDamageNumber(position: Vector3, damage: number, element: string, isCrit: boolean)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageNumberGui"
    billboard.Size = UDim2.new(0, 140, 0, 48)
    billboard.Adornee = nil
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0

    -- Random horizontal scatter
    local spread = Vector3.new(math.random(-15, 15) / 10, math.random(5, 12) / 10, math.random(-15, 15) / 10)
    local startPos = position + Vector3.new(0, 2.8, 0) + spread

    local anchor = Instance.new("Part")
    anchor.Name = "DamageAnchor"
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.CFrame = CFrame.new(startPos)
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.Anchored = true
    anchor.Parent = Workspace:FindFirstChild("VFX") or Workspace

    billboard.Adornee = anchor
    billboard.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextSize = if isCrit then 32 else 20
    label.TextColor3 = if isCrit then Color3.fromRGB(255, 80, 80) else (ELEMENT_TEXT_COLORS[element] or Color3.fromRGB(255, 255, 255))
    label.TextStrokeTransparency = 0.15
    label.TextStrokeColor3 = Color3.fromRGB(12, 16, 26)
    label.Text = (if isCrit then "CRIT! " else "") .. tostring(math.round(damage))
    label.Parent = billboard

    -- Initial pop animation
    label.TextSize = if isCrit then 40 else 24
    TweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = if isCrit then 28 else 18,
    }):Play()

    -- Upward float and fade tween
    local floatDuration = 0.8
    local targetCFrame = anchor.CFrame * CFrame.new(0, 3.8, 0)

    local moveTween = TweenService:Create(anchor, TweenInfo.new(floatDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = targetCFrame,
    })
    local fadeTween = TweenService:Create(label, TweenInfo.new(floatDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })

    moveTween:Play()
    fadeTween:Play()

    Debris:AddItem(anchor, floatDuration + 0.1)
end

return table.freeze(DamageNumbersController)
