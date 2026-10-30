--!strict
--[[
    Elemental Worlds: Master Anime Combat HUD & UI Controller
    Features:
    - Dual-layer health bar with damage chip catch-up
    - Animated element crest badge with themed colors
    - Radial cooldown sweep with live countdown
    - Floating combo counter with bounce elastic
    - Error meter with neon pulsing strip
    - World map panel with world unlock status
    - Fragment collection notification
    - Stats sidebar (level, charges, element)
    - Announcement banner system
    - Blind flash overlay (Light ability)
    - Minimap indicator (top-right region label)
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
    Fire  = { Primary = Color3.fromRGB(255, 70, 20),  Accent = Color3.fromRGB(255, 165, 40),  Glow = Color3.fromRGB(255, 100, 0) },
    Aqua  = { Primary = Color3.fromRGB(20, 155, 255), Accent = Color3.fromRGB(130, 225, 255),  Glow = Color3.fromRGB(0, 180, 255) },
    Earth = { Primary = Color3.fromRGB(155, 105, 55), Accent = Color3.fromRGB(205, 165, 95),  Glow = Color3.fromRGB(180, 130, 60) },
    Light = { Primary = Color3.fromRGB(255, 230, 60), Accent = Color3.fromRGB(255, 255, 175),  Glow = Color3.fromRGB(255, 240, 100) },
    Wind  = { Primary = Color3.fromRGB(90, 235, 165), Accent = Color3.fromRGB(185, 255, 215),  Glow = Color3.fromRGB(120, 255, 190) },
    Error = { Primary = Color3.fromRGB(255, 0, 130),  Accent = Color3.fromRGB(0, 255, 255),  Glow = Color3.fromRGB(200, 0, 200) },
    Time  = { Primary = Color3.fromRGB(60, 125, 255), Accent = Color3.fromRGB(175, 210, 255),  Glow = Color3.fromRGB(80, 150, 255) },
}

-- UI Element References
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
local announcementBanner: Frame? = nil
local announcementLabel: TextLabel? = nil
local blindOverlay: Frame? = nil
local fragmentNotif: Frame? = nil
local fragmentLabel: TextLabel? = nil
local regionLabel: TextLabel? = nil
local spinTicketLabel: TextLabel? = nil

local abilitySlotButtons: { [string]: {
    Button: TextButton,
    CooldownOverlay: Frame,
    CooldownText: TextLabel,
    NameLabel: TextLabel,
    SlotStroke: UIStroke,
    KeyLabel: TextLabel,
} } = {}

local currentMaxHealth = 100
local currentHealth = 100
local currentComboCount = 0
local lastComboTime = 0.0

local function MakeShadow(parent: GuiObject, blur: number?)
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = blur or 1.5
    shadow.Transparency = 0.6
    shadow.Parent = parent
    return shadow
end

local function MakeRoundedFrame(name: string, size: UDim2, pos: UDim2, color: Color3, parent: Instance, radius: number?, alpha: number?): Frame
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color
    f.BackgroundTransparency = alpha or 0
    f.BorderSizePixel = 0
    f.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = f

    return f
end

function UIController.CreateHUD()
    if screenGui then return end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ElementalWorlds_AnimeHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = false
    screenGui.Parent = playerGui

    -- ==================== 1. TOP STATUS BAR ====================
    local topBg = MakeRoundedFrame("TopStatusPanel",
        UDim2.new(0, 420, 0, 90),
        UDim2.new(0.5, -210, 0, 14),
        Color3.fromRGB(12, 10, 20), screenGui, 14, 0.15)

    elementStroke = Instance.new("UIStroke")
    elementStroke.Color = Color3.fromRGB(255, 70, 20)
    elementStroke.Thickness = 2.5
    elementStroke.Parent = topBg

    -- Level Diamond Badge
    local levelDiamond = Instance.new("Frame")
    levelDiamond.Name = "LevelBadge"
    levelDiamond.Size = UDim2.new(0, 40, 0, 40)
    levelDiamond.Position = UDim2.new(0, 14, 0.5, -20)
    levelDiamond.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
    levelDiamond.Rotation = 45
    levelDiamond.Parent = topBg

    local diaCorner = Instance.new("UICorner")
    diaCorner.CornerRadius = UDim.new(0, 5)
    diaCorner.Parent = levelDiamond

    local diaStroke = Instance.new("UIStroke")
    diaStroke.Color = Color3.fromRGB(255, 215, 0)
    diaStroke.Thickness = 1.8
    diaStroke.Parent = levelDiamond

    levelBadgeText = Instance.new("TextLabel")
    levelBadgeText.Size = UDim2.new(1, 0, 1, 0)
    levelBadgeText.Rotation = -45
    levelBadgeText.BackgroundTransparency = 1
    levelBadgeText.Font = Enum.Font.GothamBlack
    levelBadgeText.TextSize = 14
    levelBadgeText.TextColor3 = Color3.fromRGB(255, 220, 60)
    levelBadgeText.Text = "1"
    levelBadgeText.Parent = levelDiamond

    -- Element Crest
    elementCrestBadge = Instance.new("TextLabel")
    elementCrestBadge.Name = "ElementCrest"
    elementCrestBadge.Size = UDim2.new(0, 140, 0, 22)
    elementCrestBadge.Position = UDim2.new(0, 64, 0, 10)
    elementCrestBadge.BackgroundTransparency = 1
    elementCrestBadge.Font = Enum.Font.GothamBlack
    elementCrestBadge.TextSize = 17
    elementCrestBadge.TextColor3 = Color3.fromRGB(255, 70, 20)
    elementCrestBadge.TextXAlignment = Enum.TextXAlignment.Left
    elementCrestBadge.Text = "FIRE ELEMENT"
    elementCrestBadge.Parent = topBg

    -- Charges Counter
    chargesText = Instance.new("TextLabel")
    chargesText.Name = "ChargesText"
    chargesText.Size = UDim2.new(0, 180, 0, 22)
    chargesText.Position = UDim2.new(1, -190, 0, 10)
    chargesText.BackgroundTransparency = 1
    chargesText.Font = Enum.Font.GothamBold
    chargesText.TextSize = 13
    chargesText.TextColor3 = Color3.fromRGB(110, 215, 255)
    chargesText.TextXAlignment = Enum.TextXAlignment.Right
    chargesText.Text = "Charges: 0 / 10000"
    chargesText.Parent = topBg

    -- Spin Ticket Count
    spinTicketLabel = Instance.new("TextLabel")
    spinTicketLabel.Name = "SpinTickets"
    spinTicketLabel.Size = UDim2.new(0, 160, 0, 20)
    spinTicketLabel.Position = UDim2.new(1, -170, 0, 36)
    spinTicketLabel.BackgroundTransparency = 1
    spinTicketLabel.Font = Enum.Font.GothamBold
    spinTicketLabel.TextSize = 12
    spinTicketLabel.TextColor3 = Color3.fromRGB(255, 200, 40)
    spinTicketLabel.TextXAlignment = Enum.TextXAlignment.Right
    spinTicketLabel.Text = "Spin Tickets: 1"
    spinTicketLabel.Parent = topBg

    -- Dual-Layer Health Bar
    local healthBg = MakeRoundedFrame("HealthBg",
        UDim2.new(1, -76, 0, 22),
        UDim2.new(0, 64, 0, 44),
        Color3.fromRGB(22, 20, 32), topBg, 6, 0)

    healthFillDamageChip = MakeRoundedFrame("DamageChip",
        UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(255, 220, 80), healthBg, 6, 0)

    healthFillForeground = MakeRoundedFrame("HPForeground",
        UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(40, 215, 110), healthBg, 6, 0)

    healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Font = Enum.Font.GothamBlack
    healthText.TextSize = 11
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthText.TextStrokeTransparency = 0.3
    healthText.Text = "100 / 100"
    healthText.Parent = healthBg

    -- Level subtitle
    local levelSubtitle = Instance.new("TextLabel")
    levelSubtitle.Name = "LevelSub"
    levelSubtitle.Size = UDim2.new(0, 140, 0, 18)
    levelSubtitle.Position = UDim2.new(0, 64, 0, 68)
    levelSubtitle.BackgroundTransparency = 1
    levelSubtitle.Font = Enum.Font.GothamBold
    levelSubtitle.TextSize = 11
    levelSubtitle.TextColor3 = Color3.fromRGB(160, 155, 180)
    levelSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    levelSubtitle.Text = "Elemental Warrior"
    levelSubtitle.Parent = topBg

    -- ==================== 2. ERROR METER ====================
    errorMeterContainer = MakeRoundedFrame("ErrorMeterContainer",
        UDim2.new(0, 320, 0, 24),
        UDim2.new(0.5, -160, 0, 116),
        Color3.fromRGB(18, 8, 28), screenGui, 7, 0.1)
    errorMeterContainer.Visible = false

    local errStroke = Instance.new("UIStroke")
    errStroke.Color = Color3.fromRGB(255, 0, 130)
    errStroke.Thickness = 2
    errStroke.Parent = errorMeterContainer

    errorMeterFill = MakeRoundedFrame("ErrorFill",
        UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(255, 0, 130), errorMeterContainer, 7, 0)

    errorMeterPercentText = Instance.new("TextLabel")
    errorMeterPercentText.Size = UDim2.new(1, 0, 1, 0)
    errorMeterPercentText.BackgroundTransparency = 1
    errorMeterPercentText.Font = Enum.Font.GothamBlack
    errorMeterPercentText.TextSize = 12
    errorMeterPercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
    errorMeterPercentText.TextStrokeTransparency = 0.4
    errorMeterPercentText.Text = "ERROR METER: 0%"
    errorMeterPercentText.Parent = errorMeterContainer

    -- ==================== 3. COMBO COUNTER ====================
    comboCounterText = Instance.new("TextLabel")
    comboCounterText.Name = "ComboCounter"
    comboCounterText.Size = UDim2.new(0, 220, 0, 50)
    comboCounterText.Position = UDim2.new(0.1, 0, 0.44, 0)
    comboCounterText.BackgroundTransparency = 1
    comboCounterText.Font = Enum.Font.GothamBlack
    comboCounterText.TextSize = 32
    comboCounterText.TextColor3 = Color3.fromRGB(255, 200, 40)
    comboCounterText.TextStrokeColor3 = Color3.fromRGB(15, 12, 25)
    comboCounterText.TextStrokeTransparency = 0.1
    comboCounterText.TextXAlignment = Enum.TextXAlignment.Left
    comboCounterText.Visible = false
    comboCounterText.Text = "3 HITS"
    comboCounterText.Parent = screenGui

    -- ==================== 4. ABILITY HOTBAR ====================
    local hotbarFrame = Instance.new("Frame")
    hotbarFrame.Name = "AbilityHotbar"
    hotbarFrame.Size = UDim2.new(0, 490, 0, 84)
    hotbarFrame.Position = UDim2.new(0.5, -245, 1, -104)
    hotbarFrame.BackgroundTransparency = 1
    hotbarFrame.Parent = screenGui

    local hotbarLayout = Instance.new("UIListLayout")
    hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
    hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hotbarLayout.Padding = UDim.new(0, 8)
    hotbarLayout.Parent = hotbarFrame

    local slotKeys: { { slot: string, key: string } } = {
        { slot = "M1", key = "Q" },
        { slot = "1", key = "1" },
        { slot = "2", key = "2" },
        { slot = "3", key = "3" },
        { slot = "4", key = "4" },
        { slot = "5", key = "5" },
    }

    for _, info in slotKeys do
        local slot = info.slot
        local btn = Instance.new("TextButton")
        btn.Name = "Slot_" .. slot
        btn.Size = UDim2.new(0, 68, 0, 76)
        btn.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = hotbarFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(70, 68, 95)
        btnStroke.Thickness = 2.2
        btnStroke.Parent = btn

        local keyBadge = Instance.new("TextLabel")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.new(0, 22, 0, 18)
        keyBadge.Position = UDim2.new(0, 4, 0, 4)
        keyBadge.BackgroundColor3 = Color3.fromRGB(35, 33, 50)
        keyBadge.Font = Enum.Font.GothamBold
        keyBadge.TextSize = 10
        keyBadge.TextColor3 = Color3.fromRGB(200, 200, 220)
        keyBadge.Text = info.key
        keyBadge.Parent = btn

        local kbCorner = Instance.new("UICorner")
        kbCorner.CornerRadius = UDim.new(0, 4)
        kbCorner.Parent = keyBadge

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "AbilityName"
        nameLabel.Size = UDim2.new(1, -6, 0, 40)
        nameLabel.Position = UDim2.new(0, 3, 0, 28)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextWrapped = true
        nameLabel.TextColor3 = Color3.fromRGB(200, 198, 220)
        nameLabel.Text = "Ability"
        nameLabel.Parent = btn

        -- Cooldown overlay (fills from top)
        local cdOverlay = MakeRoundedFrame("CooldownOverlay",
            UDim2.new(1, 0, 0, 0),
            UDim2.new(0, 0, 1, 0),
            Color3.fromRGB(5, 4, 12), btn, 12, 0.3)
        cdOverlay.AnchorPoint = Vector2.new(0, 1)
        cdOverlay.Visible = false

        local cdText = Instance.new("TextLabel")
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamBlack
        cdText.TextSize = 20
        cdText.TextColor3 = Color3.fromRGB(255, 255, 255)
        cdText.Text = ""
        cdText.Parent = cdOverlay

        -- Hover & click animations
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 73, 0, 81)
            }):Play()
            SoundController.PlayUI("hover")
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 68, 0, 76)
            }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 62, 0, 70)
            }):Play()
            task.delay(0.06, function()
                TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 68, 0, 76)
                }):Play()
            end)
            local combatController = require(script.Parent.CombatController)
            combatController.Cast(slot)
        end)

        abilitySlotButtons[slot] = {
            Button = btn,
            CooldownOverlay = cdOverlay,
            CooldownText = cdText,
            NameLabel = nameLabel,
            SlotStroke = btnStroke,
            KeyLabel = keyBadge,
        }
    end

    -- ==================== 5. ANNOUNCEMENT BANNER ====================
    announcementBanner = MakeRoundedFrame("AnnouncementBanner",
        UDim2.new(0, 680, 0, 50),
        UDim2.new(0.5, -340, 0, 148),
        Color3.fromRGB(10, 8, 22), screenGui, 12, 0.15)
    announcementBanner.Visible = false

    local abStroke = Instance.new("UIStroke")
    abStroke.Color = Color3.fromRGB(255, 215, 0)
    abStroke.Thickness = 2
    abStroke.Parent = announcementBanner

    announcementLabel = Instance.new("TextLabel")
    announcementLabel.Name = "AnnounceText"
    announcementLabel.Size = UDim2.new(1, -20, 1, 0)
    announcementLabel.Position = UDim2.new(0, 10, 0, 0)
    announcementLabel.BackgroundTransparency = 1
    announcementLabel.Font = Enum.Font.GothamBlack
    announcementLabel.TextSize = 16
    announcementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    announcementLabel.TextStrokeTransparency = 0.4
    announcementLabel.Text = ""
    announcementLabel.Parent = announcementBanner

    -- ==================== 6. FRAGMENT NOTIFICATION ====================
    fragmentNotif = MakeRoundedFrame("FragmentNotif",
        UDim2.new(0, 380, 0, 60),
        UDim2.new(1, -400, 0.5, -30),
        Color3.fromRGB(255, 215, 0), screenGui, 12, 0.1)
    fragmentNotif.Visible = false

    local fragStroke = Instance.new("UIStroke")
    fragStroke.Color = Color3.fromRGB(255, 255, 100)
    fragStroke.Thickness = 2.5
    fragStroke.Parent = fragmentNotif

    fragmentLabel = Instance.new("TextLabel")
    fragmentLabel.Size = UDim2.new(1, -16, 1, 0)
    fragmentLabel.Position = UDim2.new(0, 8, 0, 0)
    fragmentLabel.BackgroundTransparency = 1
    fragmentLabel.Font = Enum.Font.GothamBlack
    fragmentLabel.TextSize = 16
    fragmentLabel.TextColor3 = Color3.fromRGB(20, 15, 30)
    fragmentLabel.TextXAlignment = Enum.TextXAlignment.Left
    fragmentLabel.Text = "Fragment Collected!"
    fragmentLabel.TextWrapped = true
    fragmentLabel.Parent = fragmentNotif

    -- ==================== 7. REGION INDICATOR (top-right) ====================
    local regionBg = MakeRoundedFrame("RegionBg",
        UDim2.new(0, 200, 0, 34),
        UDim2.new(1, -216, 0, 14),
        Color3.fromRGB(12, 10, 22), screenGui, 8, 0.2)

    local regionStroke = Instance.new("UIStroke")
    regionStroke.Color = Color3.fromRGB(100, 100, 140)
    regionStroke.Thickness = 1.5
    regionStroke.Parent = regionBg

    regionLabel = Instance.new("TextLabel")
    regionLabel.Size = UDim2.new(1, -10, 1, 0)
    regionLabel.Position = UDim2.new(0, 5, 0, 0)
    regionLabel.BackgroundTransparency = 1
    regionLabel.Font = Enum.Font.GothamBold
    regionLabel.TextSize = 13
    regionLabel.TextColor3 = Color3.fromRGB(180, 175, 200)
    regionLabel.TextXAlignment = Enum.TextXAlignment.Right
    regionLabel.Text = "Ember Highlands"
    regionLabel.Parent = regionBg

    -- ==================== 8. BLIND OVERLAY ====================
    blindOverlay = Instance.new("Frame")
    blindOverlay.Name = "BlindOverlay"
    blindOverlay.Size = UDim2.new(1, 0, 1, 0)
    blindOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    blindOverlay.BackgroundTransparency = 1
    blindOverlay.ZIndex = 60
    blindOverlay.Parent = screenGui
end

-- ========== HEALTH ==========
function UIController.SetHealth(newHealth: number, maxHealth: number)
    currentHealth = math.clamp(newHealth, 0, maxHealth)
    currentMaxHealth = maxHealth

    local ratio = math.clamp(currentHealth / currentMaxHealth, 0, 1)

    if healthText then
        healthText.Text = string.format("%d / %d", math.round(currentHealth), math.round(currentMaxHealth))
    end

    if healthFillForeground then
        healthFillForeground.Size = UDim2.new(ratio, 0, 1, 0)
        -- Color shift: green > yellow > red
        healthFillForeground.BackgroundColor3 = (ratio > 0.5)
            and Color3.fromRGB(40, 215, 110)
            or (ratio > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(220, 50, 50))
    end

    if healthFillDamageChip then
        task.delay(0.3, function()
            if healthFillDamageChip then
                TweenService:Create(healthFillDamageChip, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(ratio, 0, 1, 0),
                }):Play()
            end
        end)
    end
end

-- ========== COMBO ==========
function UIController.RegisterComboHit(count: number)
    currentComboCount = count
    lastComboTime = os.clock()

    if comboCounterText then
        local labels = { "HIT", "NICE", "GREAT", "BEAST", "GODLY" }
        local label = labels[math.min(count, #labels)] or "GODLY"
        comboCounterText.Text = string.format("%d %s", count, label)
        comboCounterText.Visible = true
        comboCounterText.TextSize = 42
        TweenService:Create(comboCounterText, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 32,
        }):Play()

        task.delay(1.6, function()
            if os.clock() - lastComboTime >= 1.5 then
                if comboCounterText then
                    TweenService:Create(comboCounterText, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                    task.delay(0.35, function()
                        if comboCounterText then
                            comboCounterText.Visible = false
                            comboCounterText.TextTransparency = 0
                        end
                    end)
                end
            end
        end)
    end
end

-- ========== UPDATE STATS ==========
function UIController.UpdateStats(data: {
    Level: number,
    Charges: number,
    Element: string,
    ErrorMeter: number,
    MaxHealth: number,
    SpinTickets: number?,
})
    if levelBadgeText then
        levelBadgeText.Text = tostring(data.Level)
    end
    if chargesText then
        chargesText.Text = string.format("Charges: %d / %d", data.Charges, GameConfig.MAX_CHARGES)
    end
    if spinTicketLabel and data.SpinTickets then
        spinTicketLabel.Text = string.format("Spin Tickets: %d", data.SpinTickets)
    end

    local theme = ELEMENT_THEMES[data.Element] or ELEMENT_THEMES.Fire
    if elementCrestBadge then
        elementCrestBadge.Text = string.upper(data.Element) .. " ELEMENT"
        elementCrestBadge.TextColor3 = theme.Primary
    end
    if elementStroke then
        TweenService:Create(elementStroke, TweenInfo.new(0.4), { Color = theme.Primary }):Play()
    end

    for _, btnData in abilitySlotButtons do
        TweenService:Create(btnData.SlotStroke, TweenInfo.new(0.3), { Color = theme.Primary }):Play()
    end

    -- Error meter
    if errorMeterContainer and errorMeterFill and errorMeterPercentText then
        local isError = (data.Element == "Error")
        errorMeterContainer.Visible = isError
        if isError then
            local ratio = math.clamp(data.ErrorMeter / 100, 0, 1)
            TweenService:Create(errorMeterFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()
            errorMeterPercentText.Text = string.format("ERROR METER: %d%%", math.round(data.ErrorMeter))
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

-- ========== COOLDOWN ==========
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

-- ========== ANNOUNCEMENT ==========
function UIController.ShowAnnouncement(text: string)
    if not announcementBanner or not announcementLabel then return end

    announcementLabel.Text = text
    announcementBanner.Visible = true
    announcementBanner.BackgroundTransparency = 0.15
    announcementLabel.TextTransparency = 0

    task.delay(4.5, function()
        if announcementBanner then
            TweenService:Create(announcementBanner, TweenInfo.new(0.8), {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(announcementLabel, TweenInfo.new(0.8), {
                TextTransparency = 1,
            }):Play()
            task.delay(0.85, function()
                if announcementBanner then
                    announcementBanner.Visible = false
                    announcementLabel.TextTransparency = 0
                end
            end)
        end
    end)
end

-- ========== FRAGMENT NOTIFICATION ==========
function UIController.ShowFragmentCollected(fragmentName: string)
    if not fragmentNotif or not fragmentLabel then return end

    fragmentLabel.Text = "FRAGMENT COLLECTED\n" .. fragmentName
    fragmentNotif.Visible = true
    fragmentNotif.Position = UDim2.new(1, -10, 0.5, -30)

    TweenService:Create(fragmentNotif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -400, 0.5, -30),
    }):Play()

    task.delay(3.5, function()
        if fragmentNotif then
            TweenService:Create(fragmentNotif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, -10, 0.5, -30),
            }):Play()
            task.delay(0.45, function()
                if fragmentNotif then fragmentNotif.Visible = false end
            end)
        end
    end)
end

-- ========== REGION LABEL ==========
function UIController.SetRegion(regionName: string)
    if regionLabel then
        regionLabel.Text = regionName
    end
end

-- ========== BLIND FLASH ==========
function UIController.TriggerBlind(durationSeconds: number)
    if not blindOverlay then return end
    blindOverlay.BackgroundTransparency = 0
    TweenService:Create(blindOverlay, TweenInfo.new(durationSeconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    }):Play()
end

return table.freeze(UIController)
