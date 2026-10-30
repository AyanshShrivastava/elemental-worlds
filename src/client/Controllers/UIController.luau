--!strict
--[[
    Elemental Worlds: Client UI Controller
    Renders top status bar (Level, Health, Charges), Element/Error Meter,
    Ability Hotbar with countdown cooldown overlays, mobile touch targets, and announcements.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UIController = {}

-- UI State References
local screenGui: ScreenGui? = nil
local healthBarFill: Frame? = nil
local healthLabel: TextLabel? = nil
local levelLabel: TextLabel? = nil
local chargesLabel: TextLabel? = nil
local elementLabel: TextLabel? = nil
local errorMeterFrame: Frame? = nil
local errorMeterFill: Frame? = nil
local announcementBanner: TextLabel? = nil
local blindOverlay: Frame? = nil

local abilityButtons: { [string]: { Button: TextButton, CooldownOverlay: Frame, CooldownText: TextLabel, NameLabel: TextLabel } } = {}

-- Color palette by element
local ElementColors: { [string]: Color3 } = {
    Fire = Color3.fromRGB(255, 75, 40),
    Aqua = Color3.fromRGB(40, 160, 255),
    Earth = Color3.fromRGB(160, 110, 60),
    Light = Color3.fromRGB(255, 230, 80),
    Wind = Color3.fromRGB(130, 240, 180),
    Error = Color3.fromRGB(255, 20, 120),
    Time = Color3.fromRGB(70, 120, 255),
}

function UIController.CreateHUD()
    if screenGui then return end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ElementalWorlds_HUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ==================== 1. TOP STATUS BAR ====================
    local topFrame = Instance.new("Frame")
    topFrame.Name = "TopStatusFrame"
    topFrame.Size = UDim2.new(0, 320, 0, 75)
    topFrame.Position = UDim2.new(0.5, -160, 0, 15)
    topFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    topFrame.BackgroundTransparency = 0.25
    topFrame.BorderSizePixel = 0
    topFrame.Parent = screenGui

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 10)
    topCorner.Parent = topFrame

    local topStroke = Instance.new("UIStroke")
    topStroke.Color = Color3.fromRGB(80, 80, 100)
    topStroke.Thickness = 1.5
    topStroke.Parent = topFrame

    -- Level Display
    levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.5, 0, 0, 24)
    levelLabel.Position = UDim2.new(0, 10, 0, 6)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextSize = 15
    levelLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Text = "Lv. 1"
    levelLabel.Parent = topFrame

    -- Charges Display
    chargesLabel = Instance.new("TextLabel")
    chargesLabel.Name = "ChargesLabel"
    chargesLabel.Size = UDim2.new(0.5, -10, 0, 24)
    chargesLabel.Position = UDim2.new(0.5, 0, 0, 6)
    chargesLabel.BackgroundTransparency = 1
    chargesLabel.Font = Enum.Font.GothamBold
    chargesLabel.TextSize = 14
    chargesLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
    chargesLabel.TextXAlignment = Enum.TextXAlignment.Right
    chargesLabel.Text = "Charges: 0 / 10,000"
    chargesLabel.Parent = topFrame

    -- Health Bar Background
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBackground"
    healthBg.Size = UDim2.new(1, -20, 0, 18)
    healthBg.Position = UDim2.new(0, 10, 0, 34)
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = topFrame

    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 6)
    healthCorner.Parent = healthBg

    healthBarFill = Instance.new("Frame")
    healthBarFill.Name = "HealthFill"
    healthBarFill.Size = UDim2.new(1, 0, 1, 0)
    healthBarFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    healthBarFill.BorderSizePixel = 0
    healthBarFill.Parent = healthBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = healthBarFill

    healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextSize = 11
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.Text = "100 / 100"
    healthLabel.Parent = healthBg

    -- Element Indicator
    elementLabel = Instance.new("TextLabel")
    elementLabel.Name = "ElementLabel"
    elementLabel.Size = UDim2.new(1, 0, 0, 14)
    elementLabel.Position = UDim2.new(0, 0, 0, 56)
    elementLabel.BackgroundTransparency = 1
    elementLabel.Font = Enum.Font.GothamMedium
    elementLabel.TextSize = 12
    elementLabel.TextColor3 = Color3.fromRGB(255, 100, 50)
    elementLabel.Text = "Element: Fire"
    elementLabel.Parent = topFrame

    -- Error Meter Frame (Only displayed if using Error element)
    errorMeterFrame = Instance.new("Frame")
    errorMeterFrame.Name = "ErrorMeterFrame"
    errorMeterFrame.Size = UDim2.new(0, 240, 0, 14)
    errorMeterFrame.Position = UDim2.new(0.5, -120, 0, 95)
    errorMeterFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    errorMeterFrame.Visible = false
    errorMeterFrame.Parent = screenGui

    local errCorner = Instance.new("UICorner")
    errCorner.CornerRadius = UDim.new(0, 4)
    errCorner.Parent = errorMeterFrame

    errorMeterFill = Instance.new("Frame")
    errorMeterFill.Name = "ErrorMeterFill"
    errorMeterFill.Size = UDim2.new(0, 0, 1, 0)
    errorMeterFill.BackgroundColor3 = Color3.fromRGB(255, 20, 120)
    errorMeterFill.BorderSizePixel = 0
    errorMeterFill.Parent = errorMeterFrame

    local errFillCorner = Instance.new("UICorner")
    errFillCorner.CornerRadius = UDim.new(0, 4)
    errFillCorner.Parent = errorMeterFill

    -- ==================== 2. ABILITY HOTBAR ====================
    local hotbarFrame = Instance.new("Frame")
    hotbarFrame.Name = "AbilityHotbar"
    hotbarFrame.Size = UDim2.new(0, 420, 0, 75)
    hotbarFrame.Position = UDim2.new(0.5, -210, 1, -95)
    hotbarFrame.BackgroundTransparency = 1
    hotbarFrame.Parent = screenGui

    local hotbarLayout = Instance.new("UIListLayout")
    hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
    hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hotbarLayout.Padding = UDim.new(0, 10)
    hotbarLayout.Parent = hotbarFrame

    local slots = { "M1", "1", "2", "3", "4", "5" }
    for _, slot in slots do
        local btn = Instance.new("TextButton")
        btn.Name = "Slot_" .. slot
        btn.Size = UDim2.new(0, 60, 0, 65)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        btn.Text = ""
        btn.AutoButtonColor = true
        btn.Parent = hotbarFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(70, 70, 90)
        btnStroke.Thickness = 1.5
        btnStroke.Parent = btn

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(1, 0, 0, 18)
        keyLabel.Position = UDim2.new(0, 0, 0, 4)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Font = Enum.Font.GothamBold
        keyLabel.TextSize = 13
        keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyLabel.Text = slot
        keyLabel.Parent = btn

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -6, 0, 36)
        nameLabel.Position = UDim2.new(0, 3, 0, 24)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 9
        nameLabel.TextWrapped = true
        nameLabel.TextColor3 = Color3.fromRGB(190, 190, 210)
        nameLabel.Text = "Ability"
        nameLabel.Parent = btn

        -- Cooldown Dark Overlay
        local cdOverlay = Instance.new("Frame")
        cdOverlay.Name = "CooldownOverlay"
        cdOverlay.Size = UDim2.new(1, 0, 0, 0)
        cdOverlay.Position = UDim2.new(0, 0, 1, 0)
        cdOverlay.AnchorPoint = Vector2.new(0, 1)
        cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        cdOverlay.BackgroundTransparency = 0.5
        cdOverlay.BorderSizePixel = 0
        cdOverlay.Visible = false
        cdOverlay.Parent = btn

        local cdCorner = Instance.new("UICorner")
        cdCorner.CornerRadius = UDim.new(0, 8)
        cdCorner.Parent = cdOverlay

        local cdText = Instance.new("TextLabel")
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamBold
        cdText.TextSize = 18
        cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
        cdText.Text = ""
        cdText.Parent = cdOverlay

        -- Mobile click trigger
        btn.MouseButton1Click:Connect(function()
            local combatController = require(script.Parent.CombatController)
            combatController.Cast(slot)
        end)

        abilityButtons[slot] = {
            Button = btn,
            CooldownOverlay = cdOverlay,
            CooldownText = cdText,
            NameLabel = nameLabel,
        }
    end

    -- ==================== 3. ANNOUNCEMENT BANNER ====================
    announcementBanner = Instance.new("TextLabel")
    announcementBanner.Name = "AnnouncementBanner"
    announcementBanner.Size = UDim2.new(0, 600, 0, 40)
    announcementBanner.Position = UDim2.new(0.5, -300, 0, 110)
    announcementBanner.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    announcementBanner.BackgroundTransparency = 0.3
    announcementBanner.Font = Enum.Font.GothamBlack
    announcementBanner.TextSize = 16
    announcementBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
    announcementBanner.Visible = false
    announcementBanner.Parent = screenGui

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = announcementBanner

    -- ==================== 4. BLIND OVERLAY ====================
    blindOverlay = Instance.new("Frame")
    blindOverlay.Name = "BlindOverlay"
    blindOverlay.Size = UDim2.new(1, 0, 1, 0)
    blindOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    blindOverlay.BackgroundTransparency = 1
    blindOverlay.ZIndex = 50
    blindOverlay.Parent = screenGui
end

-- Update Top Stats Display
function UIController.UpdateStats(data: { Level: number, Charges: number, Element: string, ErrorMeter: number, MaxHealth: number })
    if levelLabel then
        levelLabel.Text = "Lv. " .. tostring(data.Level)
    end
    if chargesLabel then
        chargesLabel.Text = string.format("Charges: %d / %d", data.Charges, GameConfig.MAX_CHARGES)
    end
    if elementLabel then
        elementLabel.Text = "Element: " .. data.Element
        local color = ElementColors[data.Element] or Color3.fromRGB(255, 255, 255)
        elementLabel.TextColor3 = color
    end

    -- Error meter toggle
    if errorMeterFrame and errorMeterFill then
        if data.Element == "Error" then
            errorMeterFrame.Visible = true
            local ratio = math.clamp(data.ErrorMeter / 100, 0, 1)
            errorMeterFill.Size = UDim2.new(ratio, 0, 1, 0)
        else
            errorMeterFrame.Visible = false
        end
    end

    -- Update move 5 button visibility (only visible if Error element)
    if abilityButtons["5"] then
        abilityButtons["5"].Button.Visible = (data.Element == "Error")
    end

    -- Refresh ability names on buttons
    for slot, btnData in abilityButtons do
        local ability = AbilityConfig.GetAbility(data.Element, slot)
        if ability then
            btnData.NameLabel.Text = ability.Name
        end
    end
end

-- Start Visual Cooldown Overlay on Button
function UIController.StartCooldown(slot: string, durationSeconds: number)
    local btnData = abilityButtons[slot]
    if not btnData then return end

    local overlay = btnData.CooldownOverlay
    local cdText = btnData.CooldownText

    overlay.Visible = true
    overlay.Size = UDim2.new(1, 0, 1, 0)

    local startTime = os.clock()
    task.spawn(function()
        while true do
            local elapsed = os.clock() - startTime
            local remaining = math.max(0, durationSeconds - elapsed)

            if remaining <= 0 then
                overlay.Visible = false
                cdText.Text = ""
                break
            end

            cdText.Text = string.format("%.1f", remaining)
            overlay.Size = UDim2.new(1, 0, remaining / durationSeconds, 0)
            task.wait(0.05)
        end
    end)
end

-- Show Global Announcement with smooth fade
function UIController.ShowAnnouncement(text: string)
    if not announcementBanner then return end

    announcementBanner.Text = text
    announcementBanner.Visible = true
    announcementBanner.TextTransparency = 0

    task.delay(4.0, function()
        if announcementBanner then
            local tween = TweenService:Create(announcementBanner, TweenInfo.new(1.0), { TextTransparency = 1, BackgroundTransparency = 1 })
            tween:Play()
            tween.Completed:Once(function()
                announcementBanner.Visible = false
                announcementBanner.BackgroundTransparency = 0.3
            end)
        end
    end)
end

-- Trigger Blind Screen Effect (Light Move 3)
function UIController.TriggerBlind(durationSeconds: number)
    if not blindOverlay then return end

    blindOverlay.BackgroundTransparency = 0
    local tween = TweenService:Create(blindOverlay, TweenInfo.new(durationSeconds), { BackgroundTransparency = 1 })
    tween:Play()
end

return table.freeze(UIController)
