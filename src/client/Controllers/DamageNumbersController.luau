--!strict
--[[
    Elemental Worlds: 3D Floating Damage Numbers Controller
    Renders dynamic, bouncing damage text in world-space with element-specific color accents.
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageNumbersController = {}

local ELEMENT_TEXT_COLORS = {
    Fire = Color3.fromRGB(255, 100, 30),
    Aqua = Color3.fromRGB(40, 180, 255),
    Earth = Color3.fromRGB(200, 150, 70),
    Light = Color3.fromRGB(255, 240, 60),
    Wind = Color3.fromRGB(120, 255, 190),
    Error = Color3.fromRGB(255, 20, 140),
    Time = Color3.fromRGB(90, 160, 255),
}

function DamageNumbersController.SpawnDamageNumber(position: Vector3, damage: number, element: string, isCrit: boolean)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageNumberGui"
    billboard.Size = UDim2.new(0, 120, 0, 45)
    billboard.Adornee = nil
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0

    -- Slight random horizontal spread
    local spread = Vector3.new(math.random(-15, 15) / 10, math.random(5, 15) / 10, math.random(-15, 15) / 10)
    local startPos = position + Vector3.new(0, 2.5, 0) + spread

    -- Invisible anchor part
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
    label.Font = if isCrit then Enum.Font.GothamBlack else Enum.Font.GothamBold
    label.TextSize = if isCrit then 26 else 18
    label.TextColor3 = ELEMENT_TEXT_COLORS[element] or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    label.Text = (if isCrit then "CRIT " else "") .. tostring(math.round(damage))
    label.Parent = billboard

    -- Upward float and fade tween
    local floatDuration = 0.75
    local targetCFrame = anchor.CFrame * CFrame.new(0, 3.5, 0)

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
