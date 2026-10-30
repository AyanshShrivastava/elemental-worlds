--!strict
--[[
    Elemental Worlds: Master Anime Combat HUD & UI Controller
    Features:
    - Dual-layer health bar with animated damage chip catch-up
    - Floating combo counter widget with punch-scale elasticity
    - Glowing element crest badge & Error meter with warning pulses
    - Radial cooldown sweep with live countdown numbers
    - Tactile sound feedback on hover and click
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UIController = {}

-- Element Theme Colors
local ELEMENT_THEMES = {
    Fire = { Primary = Color3.fromRGB(255, 75, 30), Accent = Color3.fromRGB(255, 170, 40) },
    Aqua = { Primary = Color3.fromRGB(30, 160, 255), Accent = Color3.fromRGB(150, 230, 255) },
    Earth = { Primary = Color3.fromRGB(160, 110, 60), Accent = Color3.fromRGB(210, 170, 100) },
    Light = { Primary = Color3.fromRGB(255, 230, 70), Accent = Color3.fromRGB(255, 255, 180) },
    Wind = { Primary = Color3.fromRGB(100, 240, 170), Accent = Color3.fromRGB(190, 255, 220) },
    Error = { Primary = Color3.fromRGB(255, 0, 128), Accent = Color3.fromRGB(0, 255, 255) },
    Time = { Primary = Color3.fromRGB(70, 130, 255), Accent = Color3.fromRGB(180, 215, 255) },
}

-- References
local screenGui: ScreenGui? = nil
local healthFillForeground: Frame? = nil
local healthFillDamageChip: Frame? = nil
local healthText: TextLabel? = nil
local levelBadgeText: TextLabel? = nil
local chargesText: TextLabel? = nil
local elementCrestBadge: TextLabel? = nil
local elementStroke: UIStroke? = nil
local errorMeterContainer: Frame? = nil
local errorMeterFill: Frame? = nil
local errorMeterPercentText: TextLabel? = nil
local comboCounterText: TextLabel? = nil
local announcementBanner: TextLabel? = nil
local blindOverlay: Frame? = nil

local abilitySlotButtons: { [string]: {
    Button: TextButton,
    CooldownOverlay: Frame,
    CooldownText: TextLabel,
    NameLabel: TextLabel,
    SlotStroke: UIStroke,
} } = {}

local currentMaxHealth = 100
local currentHealth = 100
local currentComboCount = 0
local lastComboTime = 0.0

function UIController.CreateHUD()
    if screenGui then return end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ElementalWorlds_AnimeHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- ==================== 1. TOP STATUS PANEL ====================
    local topContainer = Instance.new("Frame")
    topContainer.Name = "TopStatusPanel"
    topContainer.Size = UDim2.new(0, 380, 0, 84)
    topContainer.Position = UDim2.new(0.5, -190, 0, 18)
    topContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    topContainer.BackgroundTransparency = 0.2
    topContainer.BorderSizePixel = 0
    topContainer.Parent = screenGui

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 12)
    topCorner.Parent = topContainer

    elementStroke = Instance.new("UIStroke")
    elementStroke.Color = Color3.fromRGB(255, 80, 30)
    elementStroke.Thickness = 2.0
    elementStroke.Parent = topContainer

    -- Level Diamond Badge
    local levelDiamond = Instance.new("Frame")
    levelDiamond.Name = "LevelBadge"
    levelDiamond.Size = UDim2.new(0, 36, 0, 36)
    levelDiamond.Position = UDim2.new(0, 10, 0, 8)
    levelDiamond.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    levelDiamond.Rotation = 45
    levelDiamond.Parent = topContainer

    local diamondStroke = Instance.new("UIStroke")
    diamondStroke.Color = Color3.fromRGB(255, 215, 0)
    diamondStroke.Thickness = 1.5
    diamondStroke.Parent = levelDiamond

    levelBadgeText = Instance.new("TextLabel")
    levelBadgeText.Size = UDim2.new(1, 0, 1, 0)
    levelBadgeText.Rotation = -45
    levelBadgeText.BackgroundTransparency = 1
    levelBadgeText.Font = Enum.Font.GothamBlack
    levelBadgeText.TextSize = 13
    levelBadgeText.TextColor3 = Color3.fromRGB(255, 225, 60)
    levelBadgeText.Text = "1"
    levelBadgeText.Parent = levelDiamond

    -- Element Crest Badge
    elementCrestBadge = Instance.new("TextLabel")
    elementCrestBadge.Name = "ElementCrest"
    elementCrestBadge.Size = UDim2.new(0, 120, 0, 22)
    elementCrestBadge.Position = UDim2.new(0, 56, 0, 10)
    elementCrestBadge.BackgroundTransparency = 1
    elementCrestBadge.Font = Enum.Font.GothamBlack
    elementCrestBadge.TextSize = 16
    elementCrestBadge.TextColor3 = Color3.fromRGB(255, 80, 30)
    elementCrestBadge.TextXAlignment = Enum.TextXAlignment.Left
    elementCrestBadge.Text = "FIRE ELEMENT"
    elementCrestBadge.Parent = topContainer

    -- Charges Text
    chargesText = Instance.new("TextLabel")
    chargesText.Name = "ChargesText"
    chargesText.Size = UDim2.new(0, 160, 0, 22)
    chargesText.Position = UDim2.new(1, -170, 0, 10)
    chargesText.BackgroundTransparency = 1
    chargesText.Font = Enum.Font.GothamBold
    chargesText.TextSize = 12
    chargesText.TextColor3 = Color3.fromRGB(120, 220, 255)
    chargesText.TextXAlignment = Enum.TextXAlignment.Right
    chargesText.Text = "Charges: 0"
    chargesText.Parent = topContainer

    -- Dual-Layer Health Bar Background
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBackground"
    healthBg.Size = UDim2.new(1, -66, 0, 20)
    healthBg.Position = UDim2.new(0, 56, 0, 42)
    healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = topContainer

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 6)
    hCorner.Parent = healthBg

    -- Trailing Damage Chip Bar (Catches up with smooth lag)
    healthFillDamageChip = Instance.new("Frame")
    healthFillDamageChip.Name = "HealthDamageChip"
    healthFillDamageChip.Size = UDim2.new(1, 0, 1, 0)
    healthFillDamageChip.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
    healthFillDamageChip.BorderSizePixel = 0
    healthFillDamageChip.Parent = healthBg

    local chipCorner = Instance.new("UICorner")
    chipCorner.CornerRadius = UDim.new(0, 6)
    chipCorner.Parent = healthFillDamageChip

    -- Main Green Health Bar
    healthFillForeground = Instance.new("Frame")
    healthFillForeground.Name = "HealthForeground"
    healthFillForeground.Size = UDim2.new(1, 0, 1, 0)
    healthFillForeground.BackgroundColor3 = Color3.fromRGB(46, 214, 115)
    healthFillForeground.BorderSizePixel = 0
    healthFillForeground.Parent = healthBg

    local fgCorner = Instance.new("UICorner")
    fgCorner.CornerRadius = UDim.new(0, 6)
    fgCorner.Parent = healthFillForeground

    healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Font = Enum.Font.GothamBlack
    healthText.TextSize = 11
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.Text = "100 / 100"
    healthText.Parent = healthBg

    -- ==================== 2. ERROR METER (Pulsing Bar) ====================
    errorMeterContainer = Instance.new("Frame")
    errorMeterContainer.Name = "ErrorMeterContainer"
    errorMeterContainer.Size = UDim2.new(0, 300, 0, 22)
    errorMeterContainer.Position = UDim2.new(0.5, -150, 0, 110)
    errorMeterContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
    errorMeterContainer.Visible = false
    errorMeterContainer.Parent = screenGui

    local errCorner = Instance.new("UICorner")
    errCorner.CornerRadius = UDim.new(0, 6)
    errCorner.Parent = errorMeterContainer

    local errStroke = Instance.new("UIStroke")
    errStroke.Color = Color3.fromRGB(255, 0, 128)
    errStroke.Thickness = 1.5
    errStroke.Parent = errorMeterContainer

    errorMeterFill = Instance.new("Frame")
    errorMeterFill.Name = "ErrorFill"
    errorMeterFill.Size = UDim2.new(0, 0, 1, 0)
    errorMeterFill.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
    errorMeterFill.BorderSizePixel = 0
    errorMeterFill.Parent = errorMeterContainer

    local errFillCorner = Instance.new("UICorner")
    errFillCorner.CornerRadius = UDim.new(0, 6)
    errFillCorner.Parent = errorMeterFill

    errorMeterPercentText = Instance.new("TextLabel")
    errorMeterPercentText.Size = UDim2.new(1, 0, 1, 0)
    errorMeterPercentText.BackgroundTransparency = 1
    errorMeterPercentText.Font = Enum.Font.GothamBlack
    errorMeterPercentText.TextSize = 11
    errorMeterPercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
    errorMeterPercentText.Text = "ERROR METER: 0%"
    errorMeterPercentText.Parent = errorMeterContainer

    -- ==================== 3. FLOATING COMBO COUNTER ====================
    comboCounterText = Instance.new("TextLabel")
    comboCounterText.Name = "ComboCounter"
    comboCounterText.Size = UDim2.new(0, 200, 0, 40)
    comboCounterText.Position = UDim2.new(0.12, 0, 0.45, 0)
    comboCounterText.BackgroundTransparency = 1
    comboCounterText.Font = Enum.Font.GothamBlack
    comboCounterText.TextSize = 28
    comboCounterText.TextColor3 = Color3.fromRGB(255, 200, 40)
    comboCounterText.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
    comboCounterText.TextStrokeTransparency = 0.2
    comboCounterText.Visible = false
    comboCounterText.Text = "3 HITS!"
    comboCounterText.Parent = screenGui

    -- ==================== 4. ABILITY HOTBAR ====================
    local hotbarFrame = Instance.new("Frame")
    hotbarFrame.Name = "AbilityHotbar"
    hotbarFrame.Size = UDim2.new(0, 450, 0, 80)
    hotbarFrame.Position = UDim2.new(0.5, -225, 1, -100)
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
        btn.Size = UDim2.new(0, 64, 0, 72)
        btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = hotbarFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(75, 75, 105)
        btnStroke.Thickness = 2.0
        btnStroke.Parent = btn

        local keyBadge = Instance.new("TextLabel")
        keyBadge.Size = UDim2.new(0, 22, 0, 18)
        keyBadge.Position = UDim2.new(0, 4, 0, 4)
        keyBadge.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        keyBadge.Font = Enum.Font.GothamBold
        keyBadge.TextSize = 10
        keyBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyBadge.Text = slot
        keyBadge.Parent = btn

        local kbCorner = Instance.new("UICorner")
        kbCorner.CornerRadius = UDim.new(0, 4)
        kbCorner.Parent = keyBadge

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -6, 0, 38)
        nameLabel.Position = UDim2.new(0, 3, 0, 26)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextWrapped = true
        nameLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
        nameLabel.Text = "Ability"
        nameLabel.Parent = btn

        -- Cooldown Overlay
        local cdOverlay = Instance.new("Frame")
        cdOverlay.Name = "CooldownOverlay"
        cdOverlay.Size = UDim2.new(1, 0, 0, 0)
        cdOverlay.Position = UDim2.new(0, 0, 1, 0)
        cdOverlay.AnchorPoint = Vector2.new(0, 1)
        cdOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
        cdOverlay.BackgroundTransparency = 0.4
        cdOverlay.BorderSizePixel = 0
        cdOverlay.Visible = false
        cdOverlay.Parent = btn

        local cdCorner = Instance.new("UICorner")
        cdCorner.CornerRadius = UDim.new(0, 10)
        cdCorner.Parent = cdOverlay

        local cdText = Instance.new("TextLabel")
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamBlack
        cdText.TextSize = 18
        cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
        cdText.Text = ""
        cdText.Parent = cdOverlay

        -- Tactile button hover animation
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(0, 68, 0, 76) }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(0, 64, 0, 72) }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            local combatController = require(script.Parent.CombatController)
            combatController.Cast(slot)
        end)

        abilitySlotButtons[slot] = {
            Button = btn,
            CooldownOverlay = cdOverlay,
            CooldownText = cdText,
            NameLabel = nameLabel,
            SlotStroke = btnStroke,
        }
    end

    -- ==================== 5. ANNOUNCEMENT BANNER ====================
    announcementBanner = Instance.new("TextLabel")
    announcementBanner.Name = "AnnouncementBanner"
    announcementBanner.Size = UDim2.new(0, 640, 0, 44)
    announcementBanner.Position = UDim2.new(0.5, -320, 0, 140)
    announcementBanner.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    announcementBanner.BackgroundTransparency = 0.2
    announcementBanner.Font = Enum.Font.GothamBlack
    announcementBanner.TextSize = 16
    announcementBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
    announcementBanner.Visible = false
    announcementBanner.Parent = screenGui

    local abCorner = Instance.new("UICorner")
    abCorner.CornerRadius = UDim.new(0, 10)
    abCorner.Parent = announcementBanner

    local abStroke = Instance.new("UIStroke")
    abStroke.Color = Color3.fromRGB(255, 215, 0)
    abStroke.Thickness = 1.5
    abStroke.Parent = announcementBanner

    -- ==================== 6. BLIND OVERLAY ====================
    blindOverlay = Instance.new("Frame")
    blindOverlay.Name = "BlindOverlay"
    blindOverlay.Size = UDim2.new(1, 0, 1, 0)
    blindOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    blindOverlay.BackgroundTransparency = 1
    blindOverlay.ZIndex = 60
    blindOverlay.Parent = screenGui
end

-- Updates Health and triggers the dual-layer damage chip catch-up
function UIController.SetHealth(newHealth: number, maxHealth: number)
    currentHealth = math.clamp(newHealth, 0, maxHealth)
    currentMaxHealth = maxHealth

    local targetRatio = math.clamp(currentHealth / currentMaxHealth, 0, 1)

    if healthText then
        healthText.Text = string.format("%d / %d", math.round(currentHealth), math.round(currentMaxHealth))
    end

    if healthFillForeground then
        -- Immediate snap for foreground
        healthFillForeground.Size = UDim2.new(targetRatio, 0, 1, 0)
    end

    if healthFillDamageChip then
        -- Lagging catch-up animation for white/orange chip bar
        task.delay(0.35, function()
            if healthFillDamageChip then
                local chipTween = TweenService:Create(healthFillDamageChip, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(targetRatio, 0, 1, 0)
                })
                chipTween:Play()
            end
        end)
    end
end

-- Registers Combo hit count and shows punch bounce
function UIController.RegisterComboHit(count: number)
    currentComboCount = count
    lastComboTime = os.clock()

    if comboCounterText then
        comboCounterText.Text = string.format("%d HITS!", currentComboCount)
        comboCounterText.Visible = true
        comboCounterText.TextSize = 36

        local bounceTween = TweenService:Create(comboCounterText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 28
        })
        bounceTween:Play()

        -- Auto hide if idle
        task.delay(1.5, function()
            if os.clock() - lastComboTime >= 1.4 then
                if comboCounterText then
                    comboCounterText.Visible = false
                end
            end
        end)
    end
end

function UIController.UpdateStats(data: { Level: number, Charges: number, Element: string, ErrorMeter: number, MaxHealth: number })
    if levelBadgeText then
        levelBadgeText.Text = tostring(data.Level)
    end
    if chargesText then
        chargesText.Text = string.format("Charges: %d / %d", data.Charges, GameConfig.MAX_CHARGES)
    end

    -- Update element theme colors
    local theme = ELEMENT_THEMES[data.Element] or ELEMENT_THEMES.Fire
    if elementCrestBadge then
        elementCrestBadge.Text = string.upper(data.Element) .. " ELEMENT"
        elementCrestBadge.TextColor3 = theme.Primary
    end
    if elementStroke then
        elementStroke.Color = theme.Primary
    end

    -- Update button strokes with element theme
    for _, btnData in abilitySlotButtons do
        btnData.SlotStroke.Color = theme.Primary
    end

    -- Error meter
    if errorMeterContainer and errorMeterFill and errorMeterPercentText then
        if data.Element == "Error" then
            errorMeterContainer.Visible = true
            local ratio = math.clamp(data.ErrorMeter / 100, 0, 1)
            errorMeterFill.Size = UDim2.new(ratio, 0, 1, 0)
            errorMeterPercentText.Text = string.format("ERROR METER: %d%%", math.round(data.ErrorMeter))
        else
            errorMeterContainer.Visible = false
        end
    end

    if abilitySlotButtons["5"] then
        abilitySlotButtons["5"].Button.Visible = (data.Element == "Error")
    end

    for slot, btnData in abilitySlotButtons do
        local ability = AbilityConfig.GetAbility(data.Element, slot)
        if ability then
            btnData.NameLabel.Text = ability.Name
        end
    end

    UIController.SetHealth(currentHealth, data.MaxHealth)
end

function UIController.StartCooldown(slot: string, durationSeconds: number)
    local btnData = abilitySlotButtons[slot]
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
            task.wait(0.04)
        end
    end)
end

function UIController.ShowAnnouncement(text: string)
    if not announcementBanner then return end

    announcementBanner.Text = text
    announcementBanner.Visible = true
    announcementBanner.TextTransparency = 0
    announcementBanner.BackgroundTransparency = 0.2

    task.delay(4.0, function()
        if announcementBanner then
            local tween = TweenService:Create(announcementBanner, TweenInfo.new(1.0), { TextTransparency = 1, BackgroundTransparency = 1 })
            tween:Play()
            tween.Completed:Once(function()
                announcementBanner.Visible = false
            end)
        end
    end)
end

function UIController.TriggerBlind(durationSeconds: number)
    if not blindOverlay then return end

    blindOverlay.BackgroundTransparency = 0
    local tween = TweenService:Create(blindOverlay, TweenInfo.new(durationSeconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    tween:Play()
end

return table.freeze(UIController)
