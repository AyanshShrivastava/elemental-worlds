--!strict
--[[
    Elemental Worlds: Element Spin Gacha UI Controller
    Features:
    - Animated reel spinning with slow-down physics
    - Live rate display table
    - Secret element (Error, Time) celebration burst with camera shake
    - Spin ticket counter display
    - Auto-updates element on roll result
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
local resultRarityLabel: TextLabel? = nil
local resultCardStroke: UIStroke? = nil
local isSpinning = false

local ELEMENT_COLORS = {
    Fire  = Color3.fromRGB(255, 75, 20),
    Aqua  = Color3.fromRGB(20, 155, 255),
    Earth = Color3.fromRGB(155, 105, 55),
    Light = Color3.fromRGB(255, 230, 60),
    Wind  = Color3.fromRGB(90, 235, 165),
    Error = Color3.fromRGB(255, 0, 128),
    Time  = Color3.fromRGB(60, 125, 255),
}

local ELEMENT_RARITY = {
    Fire = "COMMON",
    Aqua = "COMMON",
    Earth = "COMMON",
    Light = "COMMON",
    Wind = "COMMON",
    Error = "SECRET",
    Time = "SECRET",
}

local RARITY_COLORS = {
    COMMON = Color3.fromRGB(180, 180, 200),
    SECRET = Color3.fromRGB(255, 215, 0),
}

local function MakeRounded(inst: GuiObject, r: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
end

local function MakeStroke(inst: GuiObject, color: Color3, thickness: number): UIStroke
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = inst
    return s
end

function SpinUIController.Init()
    spinGui = Instance.new("ScreenGui")
    spinGui.Name = "ElementalWorlds_SpinGacha"
    spinGui.ResetOnSpawn = false
    spinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    spinGui.Parent = playerGui

    -- HUD Toggle Button
    local spinToggleBtn = Instance.new("TextButton")
    spinToggleBtn.Name = "SpinHUDButton"
    spinToggleBtn.Size = UDim2.new(0, 130, 0, 40)
    spinToggleBtn.Position = UDim2.new(0, 14, 0.52, 0)
    spinToggleBtn.BackgroundColor3 = Color3.fromRGB(16, 28, 55)
    spinToggleBtn.Font = Enum.Font.GothamBlack
    spinToggleBtn.TextSize = 13
    spinToggleBtn.TextColor3 = Color3.fromRGB(80, 210, 255)
    spinToggleBtn.Text = "SPIN ELEMENT"
    spinToggleBtn.Parent = spinGui
    MakeRounded(spinToggleBtn, 10)
    MakeStroke(spinToggleBtn, Color3.fromRGB(60, 190, 255), 2)

    spinToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(spinToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(22, 40, 75) }):Play()
    end)
    spinToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(spinToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(16, 28, 55) }):Play()
    end)

    -- Spin Modal Window
    spinModal = Instance.new("Frame")
    spinModal.Name = "SpinModalWindow"
    spinModal.Size = UDim2.new(0, 520, 0, 460)
    spinModal.Position = UDim2.new(0.5, -260, 0.5, -230)
    spinModal.BackgroundColor3 = Color3.fromRGB(12, 14, 24)
    spinModal.BackgroundTransparency = 0.04
    spinModal.Visible = false
    spinModal.ZIndex = 15
    spinModal.Parent = spinGui
    MakeRounded(spinModal, 16)
    MakeStroke(spinModal, Color3.fromRGB(60, 160, 255), 2.5)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
    titleBar.ZIndex = 16
    titleBar.Parent = spinModal
    MakeRounded(titleBar, 16)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(80, 210, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL AWAKENING"
    titleLabel.ZIndex = 17
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -42, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.ZIndex = 17
    closeBtn.Parent = titleBar
    MakeRounded(closeBtn, 8)

    -- Gacha Card (center display)
    resultCard = Instance.new("Frame")
    resultCard.Name = "ResultCard"
    resultCard.Size = UDim2.new(0, 220, 0, 180)
    resultCard.Position = UDim2.new(0.5, -110, 0, 62)
    resultCard.BackgroundColor3 = Color3.fromRGB(255, 75, 20)
    resultCard.ZIndex = 16
    resultCard.Parent = spinModal
    MakeRounded(resultCard, 16)
    resultCardStroke = MakeStroke(resultCard, Color3.fromRGB(255, 255, 255), 3)

    -- Shimmer overlay on card
    local shimmer = Instance.new("Frame")
    shimmer.Size = UDim2.new(0.4, 0, 1, 0)
    shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shimmer.BackgroundTransparency = 0.85
    shimmer.ZIndex = 17
    shimmer.Parent = resultCard
    MakeRounded(shimmer, 16)

    resultElementName = Instance.new("TextLabel")
    resultElementName.Size = UDim2.new(1, 0, 0.55, 0)
    resultElementName.Position = UDim2.new(0, 0, 0.12, 0)
    resultElementName.BackgroundTransparency = 1
    resultElementName.Font = Enum.Font.GothamBlack
    resultElementName.TextSize = 28
    resultElementName.TextColor3 = Color3.fromRGB(255, 255, 255)
    resultElementName.TextStrokeTransparency = 0.2
    resultElementName.Text = "?"
    resultElementName.ZIndex = 18
    resultElementName.Parent = resultCard

    resultRarityLabel = Instance.new("TextLabel")
    resultRarityLabel.Size = UDim2.new(1, 0, 0.28, 0)
    resultRarityLabel.Position = UDim2.new(0, 0, 0.68, 0)
    resultRarityLabel.BackgroundTransparency = 1
    resultRarityLabel.Font = Enum.Font.GothamBold
    resultRarityLabel.TextSize = 13
    resultRarityLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    resultRarityLabel.Text = "SPIN TO DISCOVER"
    resultRarityLabel.ZIndex = 18
    resultRarityLabel.Parent = resultCard

    -- Rates Table
    local ratesFrame = Instance.new("Frame")
    ratesFrame.Size = UDim2.new(1, -30, 0, 90)
    ratesFrame.Position = UDim2.new(0, 15, 0, 256)
    ratesFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 34)
    ratesFrame.ZIndex = 16
    ratesFrame.Parent = spinModal
    MakeRounded(ratesFrame, 10)
    MakeStroke(ratesFrame, Color3.fromRGB(50, 48, 75), 1.5)

    local ratesHeader = Instance.new("TextLabel")
    ratesHeader.Size = UDim2.new(1, 0, 0, 22)
    ratesHeader.Position = UDim2.new(0, 0, 0, 6)
    ratesHeader.BackgroundTransparency = 1
    ratesHeader.Font = Enum.Font.GothamBold
    ratesHeader.TextSize = 12
    ratesHeader.TextColor3 = Color3.fromRGB(180, 178, 200)
    ratesHeader.Text = "DROP RATES"
    ratesHeader.ZIndex = 17
    ratesHeader.Parent = ratesFrame

    local ratesContent = Instance.new("TextLabel")
    ratesContent.Size = UDim2.new(1, -20, 0, 58)
    ratesContent.Position = UDim2.new(0, 10, 0, 28)
    ratesContent.BackgroundTransparency = 1
    ratesContent.Font = Enum.Font.GothamMedium
    ratesContent.TextSize = 11
    ratesContent.TextColor3 = Color3.fromRGB(160, 158, 180)
    ratesContent.TextXAlignment = Enum.TextXAlignment.Left
    ratesContent.TextWrapped = true
    ratesContent.Text = "Fire 19.96% | Aqua 19.96% | Earth 19.96% | Light 19.96% | Wind 19.96%\n[SECRET] Error 0.10% | Time 0.10%  (Lucky Spins pass doubles secret rates)"
    ratesContent.ZIndex = 17
    ratesContent.Parent = ratesFrame

    -- Roll Button
    local rollBtn = Instance.new("TextButton")
    rollBtn.Name = "PerformSpinButton"
    rollBtn.Size = UDim2.new(1, -30, 0, 50)
    rollBtn.Position = UDim2.new(0, 15, 1, -66)
    rollBtn.BackgroundColor3 = Color3.fromRGB(46, 200, 110)
    rollBtn.Font = Enum.Font.GothamBlack
    rollBtn.TextSize = 18
    rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rollBtn.Text = "ROLL ELEMENT  (1 Ticket)"
    rollBtn.ZIndex = 16
    rollBtn.Parent = spinModal
    MakeRounded(rollBtn, 12)

    rollBtn.MouseEnter:Connect(function()
        TweenService:Create(rollBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(58, 220, 130) }):Play()
    end)
    rollBtn.MouseLeave:Connect(function()
        TweenService:Create(rollBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(46, 200, 110) }):Play()
    end)

    -- Toggle modal
    local function ToggleSpin()
        if not spinModal then return end
        if spinModal.Visible then
            TweenService:Create(spinModal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            }):Play()
            task.delay(0.2, function()
                if spinModal then spinModal.Visible = false end
            end)
        else
            spinModal.Visible = true
            spinModal.Size = UDim2.new(0, 0, 0, 0)
            spinModal.Position = UDim2.new(0.5, 0, 0.5, 0)
            TweenService:Create(spinModal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 520, 0, 460),
                Position = UDim2.new(0.5, -260, 0.5, -230),
            }):Play()
        end
    end

    spinToggleBtn.MouseButton1Click:Connect(ToggleSpin)
    closeBtn.MouseButton1Click:Connect(ToggleSpin)

    -- Roll Sequence
    rollBtn.MouseButton1Click:Connect(function()
        if isSpinning then return end
        isSpinning = true
        rollBtn.Text = "SPINNING..."
        rollBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local rollRemote = remotes:FindFirstChild(GameConfig.REMOTES.ROLL_ELEMENT) :: RemoteEvent?
            if rollRemote then
                rollRemote:FireServer()
            end
        end

        -- Animated reel
        local elemNames = { "FIRE", "AQUA", "EARTH", "LIGHT", "WIND", "ERROR", "TIME" }
        local elemKeys = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
        task.spawn(function()
            for i = 1, 18 do
                local idx = math.random(1, #elemNames)
                if resultElementName then
                    resultElementName.Text = elemNames[idx]
                end
                if resultCard then
                    resultCard.BackgroundColor3 = ELEMENT_COLORS[elemKeys[idx]] or Color3.fromRGB(100, 100, 120)
                end
                task.wait(0.05 + i * 0.012)
            end
        end)
    end)
end

-- Called from ClientMain when ElementRolled event fires
function SpinUIController.ShowRollResult(rolledElement: string)
    task.wait(0.85)
    isSpinning = false

    local rollBtnRef = spinModal and spinModal:FindFirstChild("PerformSpinButton") :: TextButton?
    if rollBtnRef then
        rollBtnRef.Text = "ROLL ELEMENT  (1 Ticket)"
        rollBtnRef.BackgroundColor3 = Color3.fromRGB(46, 200, 110)
    end

    if not resultCard or not resultElementName or not resultRarityLabel then return end

    local color = ELEMENT_COLORS[rolledElement] or Color3.fromRGB(180, 180, 200)
    local rarity = ELEMENT_RARITY[rolledElement] or "COMMON"
    local rarityColor = RARITY_COLORS[rarity]

    resultElementName.Text = string.upper(rolledElement)
    resultRarityLabel.Text = rarity
    resultRarityLabel.TextColor3 = rarityColor

    TweenService:Create(resultCard, TweenInfo.new(0.08), { BackgroundColor3 = color }):Play()
    if resultCardStroke then
        TweenService:Create(resultCardStroke, TweenInfo.new(0.2), { Color = rarityColor }):Play()
    end

    -- Reveal bounce
    resultCard.Size = UDim2.new(0, 250, 0, 210)
    resultCard.Position = UDim2.new(0.5, -125, 0, 52)
    TweenService:Create(resultCard, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, 180),
        Position = UDim2.new(0.5, -110, 0, 62),
    }):Play()

    if rolledElement == "Error" or rolledElement == "Time" then
        -- Secret reveal celebration
        SoundController.PlaySound2D("Explosion", 1.0)
        CameraShakeController.Shake(0.8)

        -- Flash the card border gold
        task.spawn(function()
            for _ = 1, 4 do
                if resultCardStroke then
                    TweenService:Create(resultCardStroke, TweenInfo.new(0.18), { Thickness = 6 }):Play()
                    task.wait(0.2)
                    TweenService:Create(resultCardStroke, TweenInfo.new(0.18), { Thickness = 3 }):Play()
                    task.wait(0.2)
                end
            end
        end)
    else
        SoundController.PlaySound2D("Punch", 0.8)
    end
end

return table.freeze(SpinUIController)
