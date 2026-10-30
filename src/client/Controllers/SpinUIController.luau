--!strict
--[[
    Elemental Worlds: Element Spin Gacha UI Controller
    Features an anime-styled spin reel with dynamic sound effects, rate table preview,
    and celebratory reveals when Secret Elements (Error & Time) are rolled.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local SpinUIController = {}

local spinGui: ScreenGui? = nil
local spinModal: Frame? = nil
local resultCard: Frame? = nil
local resultElementName: TextLabel? = nil
local isSpinning = false

local ELEMENT_COLORS = {
    Fire = Color3.fromRGB(255, 80, 20),
    Aqua = Color3.fromRGB(30, 160, 255),
    Earth = Color3.fromRGB(160, 110, 60),
    Light = Color3.fromRGB(255, 230, 70),
    Wind = Color3.fromRGB(100, 240, 170),
    Error = Color3.fromRGB(255, 0, 128),
    Time = Color3.fromRGB(70, 130, 255),
}

function SpinUIController.Init()
    spinGui = Instance.new("ScreenGui")
    spinGui.Name = "ElementalWorlds_SpinGacha"
    spinGui.ResetOnSpawn = false
    spinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    spinGui.Parent = playerGui

    -- Floating Spin Button on HUD
    local spinToggleBtn = Instance.new("TextButton")
    spinToggleBtn.Name = "SpinHUDButton"
    spinToggleBtn.Size = UDim2.new(0, 100, 0, 36)
    spinToggleBtn.Position = UDim2.new(0, 15, 0.52, 0)
    spinToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 35, 60)
    spinToggleBtn.Font = Enum.Font.GothamBlack
    spinToggleBtn.TextSize = 13
    spinToggleBtn.TextColor3 = Color3.fromRGB(100, 220, 255)
    spinToggleBtn.Text = "🌀 SPIN"
    spinToggleBtn.Parent = spinGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = spinToggleBtn

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Color3.fromRGB(80, 200, 255)
    toggleStroke.Thickness = 1.5
    toggleStroke.Parent = spinToggleBtn

    -- Spin Modal Window
    spinModal = Instance.new("Frame")
    spinModal.Name = "SpinModalWindow"
    spinModal.Size = UDim2.new(0, 480, 0, 360)
    spinModal.Position = UDim2.new(0.5, -240, 0.5, -180)
    spinModal.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
    spinModal.Visible = false
    spinModal.Parent = spinGui

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 12)
    modalCorner.Parent = spinModal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(60, 160, 255)
    modalStroke.Thickness = 2
    modalStroke.Parent = spinModal

    -- Header
    local modalTitle = Instance.new("TextLabel")
    modalTitle.Size = UDim2.new(1, -60, 0, 36)
    modalTitle.Position = UDim2.new(0, 20, 0, 10)
    modalTitle.BackgroundTransparency = 1
    modalTitle.Font = Enum.Font.GothamBlack
    modalTitle.TextSize = 18
    modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    modalTitle.TextXAlignment = Enum.TextXAlignment.Left
    modalTitle.Text = "ELEMENTAL AWAKENING (SPIN)"
    modalTitle.Parent = spinModal

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0, 12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Parent = spinModal

    local cClose = Instance.new("UICorner")
    cClose.CornerRadius = UDim.new(0, 6)
    cClose.Parent = closeBtn

    -- Center Gacha Card Display
    resultCard = Instance.new("Frame")
    resultCard.Name = "ResultCard"
    resultCard.Size = UDim2.new(0, 200, 0, 160)
    resultCard.Position = UDim2.new(0.5, -100, 0, 60)
    resultCard.BackgroundColor3 = Color3.fromRGB(255, 80, 20)
    resultCard.Parent = spinModal

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = resultCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Thickness = 3
    cardStroke.Parent = resultCard

    resultElementName = Instance.new("TextLabel")
    resultElementName.Size = UDim2.new(1, 0, 1, 0)
    resultElementName.BackgroundTransparency = 1
    resultElementName.Font = Enum.Font.GothamBlack
    resultElementName.TextSize = 24
    resultElementName.TextColor3 = Color3.fromRGB(255, 255, 255)
    resultElementName.TextStrokeTransparency = 0.3
    resultElementName.Text = "READY"
    resultElementName.Parent = resultCard

    -- Rates Preview Text
    local ratesLabel = Instance.new("TextLabel")
    ratesLabel.Size = UDim2.new(1, -40, 0, 36)
    ratesLabel.Position = UDim2.new(0, 20, 0, 235)
    ratesLabel.BackgroundTransparency = 1
    ratesLabel.Font = Enum.Font.GothamMedium
    ratesLabel.TextSize = 10
    ratesLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
    ratesLabel.TextWrapped = true
    ratesLabel.Text = "Rates: Fire (19.96%) | Aqua (19.96%) | Earth (19.96%) | Light (19.96%) | Wind (19.96%)\n★ SECRET: Error (0.10%) | Time (0.10%)"
    ratesLabel.Parent = spinModal

    -- Spin Action Button
    local rollBtn = Instance.new("TextButton")
    rollBtn.Name = "PerformSpinButton"
    rollBtn.Size = UDim2.new(0, 220, 0, 45)
    rollBtn.Position = UDim2.new(0.5, -110, 1, -65)
    rollBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    rollBtn.Font = Enum.Font.GothamBlack
    rollBtn.TextSize = 16
    rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rollBtn.Text = "ROLL ELEMENT"
    rollBtn.Parent = spinModal

    local rollCorner = Instance.new("UICorner")
    rollCorner.CornerRadius = UDim.new(0, 8)
    rollCorner.Parent = rollBtn

    -- Toggle visibility
    spinToggleBtn.MouseButton1Click:Connect(function()
        spinModal.Visible = not spinModal.Visible
    end)
    closeBtn.MouseButton1Click:Connect(function()
        spinModal.Visible = false
    end)

    -- Roll sequence animation
    rollBtn.MouseButton1Click:Connect(function()
        if isSpinning then return end
        isSpinning = true

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then isSpinning = false return end

        local rollRemote = remotes:FindFirstChild(GameConfig.REMOTES.ROLL_ELEMENT) :: RemoteEvent?
        if rollRemote then
            rollRemote:FireServer()
        end

        -- Reel visual effect
        SoundController.PlaySound2D("MagicCast", 0.7)
        local elements = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
        task.spawn(function()
            for i = 1, 15 do
                local pick = elements[math.random(1, #elements)]
                resultElementName.Text = string.upper(pick)
                resultCard.BackgroundColor3 = ELEMENT_COLORS[pick] or Color3.fromRGB(255, 255, 255)
                SoundController.PlaySound2D("Punch", 0.3)
                task.wait(0.06 + (i * 0.015))
            end
        end)
    end)

    -- Listen for server roll result
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if remotes then
        local rolledEvent = remotes:WaitForChild(GameConfig.REMOTES.ELEMENT_ROLLED, 5) :: RemoteEvent?
        if rolledEvent then
            rolledEvent.OnClientEvent:Connect(function(rolledElement: string)
                task.wait(0.7) -- Let reel finish
                isSpinning = false

                resultElementName.Text = string.upper(rolledElement)
                local color = ELEMENT_COLORS[rolledElement] or Color3.fromRGB(255, 255, 255)
                resultCard.BackgroundColor3 = color

                -- Scale bounce reveal
                resultCard.Size = UDim2.new(0, 230, 0, 185)
                TweenService:Create(resultCard, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 200, 0, 160)
                }):Play()

                if rolledElement == "Error" or rolledElement == "Time" then
                    -- Secret reveal celebration
                    SoundController.PlaySound2D("Explosion", 1.0)
                    CameraShakeController.Shake(0.6)
                else
                    SoundController.PlaySound2D("Punch", 0.8)
                end
            end)
        end
    end
end

return table.freeze(SpinUIController)
