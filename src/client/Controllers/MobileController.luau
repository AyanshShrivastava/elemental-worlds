--!strict
--[[
    Elemental Worlds: Mobile Touch Controller (Blox Fruits Modern Design)
    Detects touch screens and dynamically generates right-side combat controls:
    - Primary Attack (M1)
    - Anime Dash / Flash Step (Q)
    Safe-area margins and responsive tap targets.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local MobileController = {}

function MobileController.Init()
    if not UserInputService.TouchEnabled then
        return
    end

    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "ElementalWorlds_MobileControls"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = playerGui

    local combatController = require(script.Parent.CombatController)

    -- Container positioned on lower right
    local rightContainer = Instance.new("Frame")
    rightContainer.Name = "MobileCombatContainer"
    rightContainer.Size = UDim2.new(0, 180, 0, 180)
    rightContainer.Position = UDim2.new(1, -200, 1, -210)
    rightContainer.BackgroundTransparency = 1
    rightContainer.Parent = mobileGui

    -- Primary M1 Attack Button (Circular)
    local m1Button = Instance.new("TextButton")
    m1Button.Name = "Mobile_M1"
    m1Button.Size = UDim2.new(0, 80, 0, 80)
    m1Button.Position = UDim2.new(1, -85, 1, -85)
    m1Button.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
    m1Button.Text = "ATTACK"
    m1Button.Font = Enum.Font.GothamBlack
    m1Button.TextSize = 13
    m1Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    m1Button.AutoButtonColor = false
    m1Button.Parent = rightContainer

    local m1Corner = Instance.new("UICorner")
    m1Corner.CornerRadius = UDim.new(1, 0)
    m1Corner.Parent = m1Button

    local m1Stroke = Instance.new("UIStroke")
    m1Stroke.Color = Color3.fromRGB(115, 90, 245)
    m1Stroke.Thickness = 2.5
    m1Stroke.Parent = m1Button

    m1Button.MouseButton1Click:Connect(function()
        combatController.Cast("M1")
    end)

    -- Dash Button (Circular, Blox Fruits Flash Step)
    local dashButton = Instance.new("TextButton")
    dashButton.Name = "Mobile_Dash"
    dashButton.Size = UDim2.new(0, 56, 0, 56)
    dashButton.Position = UDim2.new(0, 15, 0.5, -28)
    dashButton.BackgroundColor3 = Color3.fromRGB(15, 20, 34)
    dashButton.Text = "DASH"
    dashButton.Font = Enum.Font.GothamBlack
    dashButton.TextSize = 11
    dashButton.TextColor3 = Color3.fromRGB(0, 180, 255)
    dashButton.AutoButtonColor = false
    dashButton.Parent = rightContainer

    local dashCorner = Instance.new("UICorner")
    dashCorner.CornerRadius = UDim.new(1, 0)
    dashCorner.Parent = dashButton

    local dashStroke = Instance.new("UIStroke")
    dashStroke.Color = Color3.fromRGB(0, 180, 255)
    dashStroke.Thickness = 2.0
    dashStroke.Parent = dashButton

    dashButton.MouseButton1Click:Connect(function()
        -- Simulate Q keypress for Anime Dash
        local UserInputServiceInternal = game:GetService("VirtualInputManager") or nil
        combatController.Cast("Dash")
    end)
end

return table.freeze(MobileController)
