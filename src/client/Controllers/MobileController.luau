--!strict
--[[
    Elemental Worlds: Mobile Touch Controller
    Detects touch screens and dynamically generates right-side combat controls.
    Ensures clear mobile tap targets and safe-area margins.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local MobileController = {}

function MobileController.Init()
    -- Only enable if touch screen is detected
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
    rightContainer.Size = UDim2.new(0, 160, 0, 160)
    rightContainer.Position = UDim2.new(1, -180, 1, -190)
    rightContainer.BackgroundTransparency = 1
    rightContainer.Parent = mobileGui

    -- Big Primary M1 Button
    local m1Button = Instance.new("TextButton")
    m1Button.Name = "Mobile_M1"
    m1Button.Size = UDim2.new(0, 80, 0, 80)
    m1Button.Position = UDim2.new(0.5, -40, 0.5, -40)
    m1Button.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    m1Button.Text = "ATTACK\n(M1)"
    m1Button.Font = Enum.Font.GothamBold
    m1Button.TextSize = 13
    m1Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    m1Button.Parent = rightContainer

    local m1Corner = Instance.new("UICorner")
    m1Corner.CornerRadius = UDim.new(1, 0) -- Circular
    m1Corner.Parent = m1Button

    local m1Stroke = Instance.new("UIStroke")
    m1Stroke.Color = Color3.fromRGB(255, 255, 255)
    m1Stroke.Thickness = 2
    m1Stroke.Parent = m1Button

    m1Button.MouseButton1Click:Connect(function()
        combatController.Cast("M1")
    end)
end

return table.freeze(MobileController)
