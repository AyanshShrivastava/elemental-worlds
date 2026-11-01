--!strict
--[[
    Elemental Worlds: Element Spin Gacha UI Controller (Blox Fruits Modern Design)
    Features:
    - Blox Fruits Fruit Dealer aesthetic: deep dark navy cards with electric purple/cyan outlines
    - Rapid card shuffle animation with smooth ease-out deceleration
    - Void purple celebration effect for secret elements (Error, Time)
    - Live rates table with clean pill badges
    - Spin ticket counter with real-time server sync
    - NO gold or rainbow cycling
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SharedLoader = require(script.Parent.Parent.SharedLoader)
local GameConfig = SharedLoader.GameConfig
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)

local localPlayer = Players.LocalPlayer

local function GetPlayerGui(): PlayerGui?
    if not localPlayer then
        localPlayer = Players.LocalPlayer
    end
    if not localPlayer then return nil end
    return (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)) :: PlayerGui?
end

local SpinUIController = {}

local spinGui: ScreenGui? = nil
local spinModal: Frame? = nil
local resultCard: Frame? = nil
local resultElementName: TextLabel? = nil
local resultRarityLabel: TextLabel? = nil
local resultCardStroke: UIStroke? = nil
local ticketCountLabel: TextLabel? = nil
local isSpinning = false

local ELEMENT_COLORS = {
    Fire  = Color3.fromRGB(255, 75, 30),
    Aqua  = Color3.fromRGB(0, 160, 255),
    Earth = Color3.fromRGB(150, 110, 65),
    Light = Color3.fromRGB(240, 220, 90),
    Wind  = Color3.fromRGB(60, 215, 150),
    Error = Color3.fromRGB(255, 20, 140),
    Time  = Color3.fromRGB(130, 80, 255),
}

local ELEMENT_RARITY = {
    Fire  = "COMMON",
    Aqua  = "COMMON",
    Earth = "COMMON",
    Light = "COMMON",
    Wind  = "COMMON",
    Error = "MYTHIC",
    Time  = "MYTHIC",
}

-- Modern Blox Fruits style rarity colors (No gold!)
local RARITY_COLORS = {
    COMMON = Color3.fromRGB(140, 150, 175),
    MYTHIC = Color3.fromRGB(160, 70, 255), -- Void Amethyst
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
    local playerGui = GetPlayerGui()
    if not playerGui then return end

    spinGui = Instance.new("ScreenGui")
    spinGui.Name = "ElementalWorlds_SpinGacha"
    spinGui.ResetOnSpawn = false
    spinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    spinGui.Parent = playerGui

    -- HUD Toggle Button (Left Side Stack)
    local spinToggleBtn = Instance.new("TextButton")
    spinToggleBtn.Name = "SpinHUDButton"
    spinToggleBtn.Size = UDim2.new(0, 130, 0, 38)
    spinToggleBtn.Position = UDim2.new(0, 20, 0.46, 0)
    spinToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
    spinToggleBtn.Font = Enum.Font.GothamBlack
    spinToggleBtn.TextSize = 12
    spinToggleBtn.TextColor3 = Color3.fromRGB(140, 110, 255)
    spinToggleBtn.Text = "SPIN ELEMENT"
    spinToggleBtn.AutoButtonColor = false
    spinToggleBtn.Parent = spinGui
    MakeRounded(spinToggleBtn, 8)
    MakeStroke(spinToggleBtn, Color3.fromRGB(115, 90, 245), 1.8)

    spinToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(spinToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 30, 48) }):Play()
        SoundController.PlayUI("hover")
    end)
    spinToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(spinToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(15, 20, 32) }):Play()
    end)

    -- Spin Modal Window (Blox Fruits Fruit Dealer Style)
    spinModal = Instance.new("Frame")
    spinModal.Name = "SpinModalWindow"
    spinModal.Size = UDim2.new(0, 520, 0, 460)
    spinModal.Position = UDim2.new(0.5, -260, 0.5, -230)
    spinModal.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
    spinModal.BackgroundTransparency = 0.05
    spinModal.Visible = false
    spinModal.ZIndex = 20
    spinModal.Parent = spinGui
    MakeRounded(spinModal, 12)
    MakeStroke(spinModal, Color3.fromRGB(115, 90, 245), 2.0)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    titleBar.ZIndex = 21
    titleBar.Parent = spinModal
    MakeRounded(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENT GACHA"
    titleLabel.ZIndex = 22
    titleLabel.Parent = titleBar

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.ZIndex = 22
    closeBtn.Parent = titleBar
    MakeRounded(closeBtn, 6)

    -- Result Display Card
    resultCard = Instance.new("Frame")
    resultCard.Name = "ResultCard"
    resultCard.Size = UDim2.new(0, 220, 0, 150)
    resultCard.Position = UDim2.new(0.5, -110, 0, 70)
    resultCard.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
    resultCard.ZIndex = 21
    resultCard.Parent = spinModal
    MakeRounded(resultCard, 10)
    resultCardStroke = MakeStroke(resultCard, Color3.fromRGB(60, 75, 105), 2.0)

    -- Rarity Pill Badge
    resultRarityLabel = Instance.new("TextLabel")
    resultRarityLabel.Name = "RarityBadge"
    resultRarityLabel.Size = UDim2.new(0, 110, 0, 22)
    resultRarityLabel.Position = UDim2.new(0.5, -55, 0, 18)
    resultRarityLabel.BackgroundColor3 = Color3.fromRGB(26, 34, 52)
    resultRarityLabel.Font = Enum.Font.GothamBlack
    resultRarityLabel.TextSize = 11
    resultRarityLabel.TextColor3 = RARITY_COLORS.COMMON
    resultRarityLabel.Text = "COMMON"
    resultRarityLabel.ZIndex = 22
    resultRarityLabel.Parent = resultCard
    MakeRounded(resultRarityLabel, 4)

    -- Element Name
    resultElementName = Instance.new("TextLabel")
    resultElementName.Name = "ElementName"
    resultElementName.Size = UDim2.new(1, -20, 0, 48)
    resultElementName.Position = UDim2.new(0, 10, 0, 55)
    resultElementName.BackgroundTransparency = 1
    resultElementName.Font = Enum.Font.GothamBlack
    resultElementName.TextSize = 26
    resultElementName.TextColor3 = Color3.fromRGB(255, 255, 255)
    resultElementName.Text = "FIRE"
    resultElementName.ZIndex = 22
    resultElementName.Parent = resultCard

    -- Subtitle prompt
    local subPrompt = Instance.new("TextLabel")
    subPrompt.Size = UDim2.new(1, 0, 0, 20)
    subPrompt.Position = UDim2.new(0, 0, 1, -28)
    subPrompt.BackgroundTransparency = 1
    subPrompt.Font = Enum.Font.GothamMedium
    subPrompt.TextSize = 11
    subPrompt.TextColor3 = Color3.fromRGB(130, 140, 165)
    subPrompt.Text = "READY TO AWAKEN"
    subPrompt.ZIndex = 22
    subPrompt.Parent = resultCard

    -- Ticket Balance & Information
    ticketCountLabel = Instance.new("TextLabel")
    ticketCountLabel.Size = UDim2.new(1, -40, 0, 24)
    ticketCountLabel.Position = UDim2.new(0, 20, 0, 235)
    ticketCountLabel.BackgroundTransparency = 1
    ticketCountLabel.Font = Enum.Font.GothamBold
    ticketCountLabel.TextSize = 13
    ticketCountLabel.TextColor3 = Color3.fromRGB(140, 110, 255)
    ticketCountLabel.Text = "Available Spin Tickets: 1"
    ticketCountLabel.ZIndex = 21
    ticketCountLabel.Parent = spinModal

    -- Spin Action Button (Modern Solid Purple Button)
    local spinActionBtn = Instance.new("TextButton")
    spinActionBtn.Name = "SpinActionButton"
    spinActionBtn.Size = UDim2.new(0, 260, 0, 44)
    spinActionBtn.Position = UDim2.new(0.5, -130, 0, 270)
    spinActionBtn.BackgroundColor3 = Color3.fromRGB(115, 90, 245)
    spinActionBtn.Font = Enum.Font.GothamBlack
    spinActionBtn.TextSize = 14
    spinActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spinActionBtn.Text = "ROLL ELEMENT (1 TICKET)"
    spinActionBtn.AutoButtonColor = false
    spinActionBtn.ZIndex = 21
    spinActionBtn.Parent = spinModal
    MakeRounded(spinActionBtn, 8)

    spinActionBtn.MouseEnter:Connect(function()
        TweenService:Create(spinActionBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(135, 110, 255) }):Play()
    end)
    spinActionBtn.MouseLeave:Connect(function()
        TweenService:Create(spinActionBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(115, 90, 245) }):Play()
    end)

    -- Rates Table Container
    local ratesFrame = Instance.new("Frame")
    ratesFrame.Size = UDim2.new(1, -40, 0, 115)
    ratesFrame.Position = UDim2.new(0, 20, 0, 328)
    ratesFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
    ratesFrame.ZIndex = 21
    ratesFrame.Parent = spinModal
    MakeRounded(ratesFrame, 8)
    MakeStroke(ratesFrame, Color3.fromRGB(35, 45, 68), 1.2)

    local ratesTitle = Instance.new("TextLabel")
    ratesTitle.Size = UDim2.new(1, -20, 0, 22)
    ratesTitle.Position = UDim2.new(0, 10, 0, 6)
    ratesTitle.BackgroundTransparency = 1
    ratesTitle.Font = Enum.Font.GothamBold
    ratesTitle.TextSize = 11
    ratesTitle.TextColor3 = Color3.fromRGB(140, 150, 175)
    ratesTitle.TextXAlignment = Enum.TextXAlignment.Left
    ratesTitle.Text = "DROP RATES"
    ratesTitle.ZIndex = 22
    ratesTitle.Parent = ratesFrame

    local ratesContent = Instance.new("TextLabel")
    ratesContent.Size = UDim2.new(1, -20, 0, 75)
    ratesContent.Position = UDim2.new(0, 10, 0, 30)
    ratesContent.BackgroundTransparency = 1
    ratesContent.Font = Enum.Font.GothamMedium
    ratesContent.TextSize = 11
    ratesContent.TextColor3 = Color3.fromRGB(190, 200, 225)
    ratesContent.TextXAlignment = Enum.TextXAlignment.Left
    ratesContent.TextYAlignment = Enum.TextYAlignment.Top
    ratesContent.Text = "Fire, Aqua, Earth, Light, Wind: 19.96% each\nMythic Secrets: Error (0.10%) | Time (0.10%)\nFirst 5,000 players to claim receive guaranteed Mythic allocation!"
    ratesContent.ZIndex = 22
    ratesContent.Parent = ratesFrame

    -- Toggle & Close Logic
    local function ToggleModal()
        spinModal.Visible = not spinModal.Visible
        if spinModal.Visible then
            SoundController.PlayUI("open")
            spinModal.Position = UDim2.new(0.5, -260, 0.5, -210)
            TweenService:Create(spinModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -260, 0.5, -230),
            }):Play()
        else
            SoundController.PlayUI("close")
        end
    end

    spinToggleBtn.MouseButton1Click:Connect(ToggleModal)
    closeBtn.MouseButton1Click:Connect(ToggleModal)

    -- Spin Action
    spinActionBtn.MouseButton1Click:Connect(function()
        if isSpinning then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local rollEvent = remotes:FindFirstChild(GameConfig.REMOTES.ROLL_ELEMENT) :: RemoteEvent?
        if rollEvent then
            rollEvent:FireServer()
        end
    end)
end

-- Displays the roll result with accelerating/decelerating shuffle animation
function SpinUIController.ShowRollResult(rolledElement: string)
    if not resultCard or not resultElementName or not resultRarityLabel or not resultCardStroke then
        return
    end

    isSpinning = true
    SoundController.PlayUI("spin_start")

    -- Shuffle through elements
    local candidates = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
    local totalTicks = 18
    local tickDelay = 0.04

    task.spawn(function()
        for i = 1, totalTicks do
            local randomElem = candidates[math.random(1, #candidates)]
            resultElementName.Text = string.upper(randomElem)
            resultElementName.TextColor3 = ELEMENT_COLORS[randomElem] or Color3.fromRGB(255, 255, 255)
            SoundController.PlayUI("hover")
            task.wait(tickDelay)
            tickDelay = tickDelay * 1.15 -- Smooth deceleration
        end

        -- Land on the final result
        resultElementName.Text = string.upper(rolledElement)
        local elemColor = ELEMENT_COLORS[rolledElement] or Color3.fromRGB(255, 255, 255)
        resultElementName.TextColor3 = elemColor

        local rarity = ELEMENT_RARITY[rolledElement] or "COMMON"
        resultRarityLabel.Text = rarity
        local rarityColor = RARITY_COLORS[rarity] or RARITY_COLORS.COMMON
        resultRarityLabel.TextColor3 = rarityColor

        -- Border animation
        TweenService:Create(resultCardStroke, TweenInfo.new(0.3), { Color = elemColor }):Play()

        -- Mythic Secret Celebration (Error or Time)
        if rarity == "MYTHIC" then
            SoundController.PlaySound2D("MagicCast", 1.0)
            CameraShakeController.Shake(0.6)

            -- Electric violet pulse
            for _ = 1, 3 do
                TweenService:Create(resultCardStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(200, 80, 255), Thickness = 4.0 }):Play()
                task.wait(0.16)
                TweenService:Create(resultCardStroke, TweenInfo.new(0.15), { Color = elemColor, Thickness = 2.0 }):Play()
                task.wait(0.16)
            end
        else
            SoundController.PlayUI("success")
        end

        isSpinning = false
    end)
end

function SpinUIController.UpdateTickets(count: number)
    if ticketCountLabel then
        ticketCountLabel.Text = string.format("Available Spin Tickets: %d", count)
    end
end

return table.freeze(SpinUIController)
