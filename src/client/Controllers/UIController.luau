--!strict
--[[
    Elemental Worlds: Master Anime Combat HUD (Blox Fruits Modern Design)
    
    Aesthetic rules:
    - NO gold or rainbow cycling
    - Deep obsidian-navy cards (Color3.fromRGB(12, 16, 24))
    - Dual Stats: Emerald Health Bar + Electric Cyan Energy Bar (Blox Fruits signature)
    - Hotbar supporting [Z], [X], [C], [V], and [Q] Dash + M1
    - Cooldown swipe with bold countdown and off-cooldown flash
    - Floating combo counter with elastic bounce
    - Clean side menu buttons (MENU, SPIN, SHOP, CREATOR SUITE)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SharedLoader = require(script.Parent.Parent.SharedLoader)
local GameConfig = SharedLoader.GameConfig
local AbilityConfig = SharedLoader.AbilityConfig
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer

local function GetPlayerGui(): PlayerGui?
    if not localPlayer then
        localPlayer = Players.LocalPlayer
    end
    if not localPlayer then return nil end
    return (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)) :: PlayerGui?
end

local UIController = {}

-- Modern Blox Fruits Color Tokens
local PALETTE = {
    BG_MAIN         = Color3.fromRGB(12, 16, 26),
    BG_CARD         = Color3.fromRGB(18, 24, 38),
    BG_SLOT         = Color3.fromRGB(15, 20, 34),
    BORDER_DEFAULT  = Color3.fromRGB(45, 55, 80),
    BORDER_ACCENT   = Color3.fromRGB(115, 90, 245),
    TEXT_PRIMARY    = Color3.fromRGB(245, 248, 255),
    TEXT_MUTED      = Color3.fromRGB(135, 145, 170),
    HP_GREEN        = Color3.fromRGB(46, 204, 113),
    HP_ORANGE       = Color3.fromRGB(230, 126, 34),
    HP_RED          = Color3.fromRGB(231, 76, 60),
    HP_CHIP         = Color3.fromRGB(140, 30, 30),
    ENERGY_CYAN     = Color3.fromRGB(0, 165, 255),
    ENERGY_DARK     = Color3.fromRGB(10, 60, 110),
}

-- Curated Element Accents (No gold, clean vibrant anime tones)
local ELEMENT_THEMES = {
    Fire  = { Primary = Color3.fromRGB(255, 75, 30),  Accent = Color3.fromRGB(255, 130, 50) },
    Aqua  = { Primary = Color3.fromRGB(0, 160, 255),  Accent = Color3.fromRGB(100, 215, 255) },
    Earth = { Primary = Color3.fromRGB(150, 110, 65), Accent = Color3.fromRGB(200, 160, 110) },
    Light = { Primary = Color3.fromRGB(240, 220, 90), Accent = Color3.fromRGB(255, 255, 180) },
    Wind  = { Primary = Color3.fromRGB(60, 215, 150), Accent = Color3.fromRGB(160, 255, 210) },
    Error = { Primary = Color3.fromRGB(255, 20, 140), Accent = Color3.fromRGB(0, 255, 240) },
    Time  = { Primary = Color3.fromRGB(120, 80, 255), Accent = Color3.fromRGB(190, 160, 255) },
}

-- GUI References
local screenGui: ScreenGui? = nil
local healthFill: Frame? = nil
local healthChip: Frame? = nil
local healthText: TextLabel? = nil
local energyFill: Frame? = nil
local energyText: TextLabel? = nil
local levelBadgeText: TextLabel? = nil
local elementTagText: TextLabel? = nil
local elementTagFrame: Frame? = nil
local spinTicketText: TextLabel? = nil
local fragmentsText: TextLabel? = nil
local chargesText: TextLabel? = nil
local comboLabel: TextLabel? = nil
local announcementBanner: Frame? = nil
local announcementLabel: TextLabel? = nil
local fragmentNotif: Frame? = nil
local fragmentLabel: TextLabel? = nil
local regionLabel: TextLabel? = nil
local blindOverlay: Frame? = nil
local errorMeterContainer: Frame? = nil
local errorMeterFill: Frame? = nil
local errorMeterText: TextLabel? = nil

local abilityButtons: { [string]: {
    Button: TextButton,
    CooldownOverlay: Frame,
    CooldownText: TextLabel,
    NameLabel: TextLabel,
    KeyLabel: TextLabel,
    Stroke: UIStroke,
} } = {}

-- State
local currentHealth = 100
local currentMaxHealth = 100
local currentEnergy = 500
local maxEnergy = 500
local currentCombo = 0
local lastComboTime = 0.0

local function MakeCorner(inst: GuiObject, r: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
end

local function MakeStroke(inst: GuiObject, color: Color3, thickness: number): UIStroke
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- ==================== CREATE HUD ====================
function UIController.CreateHUD()
    if screenGui then return end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ElementalWorlds_BloxFruitsHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local playerGui = GetPlayerGui()
    if not playerGui then
        warn("[UIController] PlayerGui not available.")
        return
    end
    screenGui.Parent = playerGui

    -- ==================== 1. PLAYER STATS CARD (Bottom-Left) ====================
    local statsCard = Instance.new("Frame")
    statsCard.Name = "PlayerStatsCard"
    statsCard.Size = UDim2.new(0, 360, 0, 110)
    statsCard.Position = UDim2.new(0, 20, 1, -135)
    statsCard.BackgroundColor3 = PALETTE.BG_MAIN
    statsCard.BackgroundTransparency = 0.12
    statsCard.Parent = screenGui
    MakeCorner(statsCard, 10)
    MakeStroke(statsCard, PALETTE.BORDER_DEFAULT, 1.8)

    -- Top Row: Level Pill & Element Badge & Currency
    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, -20, 0, 26)
    topRow.Position = UDim2.new(0, 10, 0, 8)
    topRow.BackgroundTransparency = 1
    topRow.Parent = statsCard

    -- Level Pill
    local levelPill = Instance.new("Frame")
    levelPill.Size = UDim2.new(0, 75, 1, 0)
    levelPill.BackgroundColor3 = PALETTE.BG_CARD
    levelPill.Parent = topRow
    MakeCorner(levelPill, 6)
    MakeStroke(levelPill, PALETTE.BORDER_DEFAULT, 1.2)

    levelBadgeText = Instance.new("TextLabel")
    levelBadgeText.Size = UDim2.new(1, 0, 1, 0)
    levelBadgeText.BackgroundTransparency = 1
    levelBadgeText.Font = Enum.Font.GothamBlack
    levelBadgeText.TextSize = 12
    levelBadgeText.TextColor3 = PALETTE.TEXT_PRIMARY
    levelBadgeText.Text = "Lv. 1"
    levelBadgeText.Parent = levelPill

    -- Element Badge
    elementTagFrame = Instance.new("Frame")
    elementTagFrame.Size = UDim2.new(0, 110, 1, 0)
    elementTagFrame.Position = UDim2.new(0, 82, 0, 0)
    elementTagFrame.BackgroundColor3 = PALETTE.BG_CARD
    elementTagFrame.Parent = topRow
    MakeCorner(elementTagFrame, 6)
    local elemStroke = MakeStroke(elementTagFrame, PALETTE.BORDER_ACCENT, 1.2)

    elementTagText = Instance.new("TextLabel")
    elementTagText.Size = UDim2.new(1, 0, 1, 0)
    elementTagText.BackgroundTransparency = 1
    elementTagText.Font = Enum.Font.GothamBold
    elementTagText.TextSize = 11
    elementTagText.TextColor3 = PALETTE.BORDER_ACCENT
    elementTagText.Text = "FIRE"
    elementTagText.Parent = elementTagFrame

    -- Spins & Charges
    spinTicketText = Instance.new("TextLabel")
    spinTicketText.Size = UDim2.new(0, 140, 1, 0)
    spinTicketText.Position = UDim2.new(1, -140, 0, 0)
    spinTicketText.BackgroundTransparency = 1
    spinTicketText.Font = Enum.Font.GothamBold
    spinTicketText.TextSize = 11
    spinTicketText.TextColor3 = PALETTE.TEXT_MUTED
    spinTicketText.TextXAlignment = Enum.TextXAlignment.Right
    spinTicketText.Text = "Spins: 1 | Charges: 0"
    spinTicketText.Parent = topRow

    -- Health Bar (Emerald Green with damage chip underneath)
    local hpTrack = Instance.new("Frame")
    hpTrack.Name = "HealthTrack"
    hpTrack.Size = UDim2.new(1, -20, 0, 24)
    hpTrack.Position = UDim2.new(0, 10, 0, 42)
    hpTrack.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
    hpTrack.Parent = statsCard
    MakeCorner(hpTrack, 6)
    MakeStroke(hpTrack, Color3.fromRGB(30, 40, 55), 1.2)

    healthChip = Instance.new("Frame")
    healthChip.Name = "HealthChip"
    healthChip.Size = UDim2.new(1, 0, 1, 0)
    healthChip.BackgroundColor3 = PALETTE.HP_CHIP
    healthChip.BorderSizePixel = 0
    healthChip.Parent = hpTrack
    MakeCorner(healthChip, 6)

    healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = PALETTE.HP_GREEN
    healthFill.BorderSizePixel = 0
    healthFill.Parent = hpTrack
    MakeCorner(healthFill, 6)

    healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, -12, 1, 0)
    healthText.Position = UDim2.new(0, 6, 0, 0)
    healthText.BackgroundTransparency = 1
    healthText.Font = Enum.Font.GothamBlack
    healthText.TextSize = 11
    healthText.TextColor3 = PALETTE.TEXT_PRIMARY
    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthText.TextStrokeTransparency = 0.3
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    healthText.Text = "100 / 100"
    healthText.Parent = hpTrack

    -- Energy Bar (Blox Fruits Electric Cyan)
    local energyTrack = Instance.new("Frame")
    energyTrack.Name = "EnergyTrack"
    energyTrack.Size = UDim2.new(1, -20, 0, 20)
    energyTrack.Position = UDim2.new(0, 10, 0, 74)
    energyTrack.BackgroundColor3 = Color3.fromRGB(8, 20, 36)
    energyTrack.Parent = statsCard
    MakeCorner(energyTrack, 6)
    MakeStroke(energyTrack, Color3.fromRGB(20, 50, 80), 1.2)

    energyFill = Instance.new("Frame")
    energyFill.Name = "EnergyFill"
    energyFill.Size = UDim2.new(1, 0, 1, 0)
    energyFill.BackgroundColor3 = PALETTE.ENERGY_CYAN
    energyFill.BorderSizePixel = 0
    energyFill.Parent = energyTrack
    MakeCorner(energyFill, 6)

    energyText = Instance.new("TextLabel")
    energyText.Size = UDim2.new(1, -12, 1, 0)
    energyText.Position = UDim2.new(0, 6, 0, 0)
    energyText.BackgroundTransparency = 1
    energyText.Font = Enum.Font.GothamBlack
    energyText.TextSize = 10
    energyText.TextColor3 = PALETTE.TEXT_PRIMARY
    energyText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    energyText.TextStrokeTransparency = 0.4
    energyText.TextXAlignment = Enum.TextXAlignment.Center
    energyText.Text = "500 / 500"
    energyText.Parent = energyTrack

    -- Smooth energy regeneration loop
    task.spawn(function()
        while true do
            if currentEnergy < maxEnergy then
                currentEnergy = math.min(maxEnergy, currentEnergy + 15)
                UIController.SetEnergy(currentEnergy, maxEnergy)
            end
            task.wait(0.2)
        end
    end)

    -- ==================== 2. BLOX FRUITS ABILITY HOTBAR (Bottom-Center) ====================
    local hotbar = Instance.new("Frame")
    hotbar.Name = "AbilityHotbar"
    hotbar.Size = UDim2.new(0, 480, 0, 78)
    hotbar.Position = UDim2.new(0.5, -190, 1, -98)
    hotbar.BackgroundTransparency = 1
    hotbar.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = hotbar

    -- Hotbar slots matching Blox Fruits anime RPG conventions
    local slots = {
        { slot = "M1", key = "M1", name = "Basic Attack" },
        { slot = "1",  key = "Z",  name = "Move 1" },
        { slot = "2",  key = "X",  name = "Move 2" },
        { slot = "3",  key = "C",  name = "Move 3" },
        { slot = "4",  key = "V",  name = "Move 4" },
        { slot = "5",  key = "B",  name = "Secret" },
    }

    for _, slotInfo in slots do
        local slot = slotInfo.slot
        local btn = Instance.new("TextButton")
        btn.Name = "Slot_" .. slot
        btn.Size = UDim2.new(0, 70, 0, 70)
        btn.BackgroundColor3 = PALETTE.BG_SLOT
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = hotbar
        MakeCorner(btn, 8)
        local btnStroke = MakeStroke(btn, PALETTE.BORDER_DEFAULT, 1.8)

        -- Keybind Badge [Z], [X], [C], [V]
        local keyBadge = Instance.new("Frame")
        keyBadge.Size = UDim2.new(0, 22, 0, 18)
        keyBadge.Position = UDim2.new(0, 5, 0, 5)
        keyBadge.BackgroundColor3 = PALETTE.BG_CARD
        keyBadge.Parent = btn
        MakeCorner(keyBadge, 4)

        local keyText = Instance.new("TextLabel")
        keyText.Size = UDim2.new(1, 0, 1, 0)
        keyText.BackgroundTransparency = 1
        keyText.Font = Enum.Font.GothamBlack
        keyText.TextSize = 10
        keyText.TextColor3 = PALETTE.BORDER_ACCENT
        keyText.Text = slotInfo.key
        keyText.Parent = keyBadge

        -- Ability Name
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "AbilityName"
        nameLbl.Size = UDim2.new(1, -8, 0, 36)
        nameLbl.Position = UDim2.new(0, 4, 1, -40)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 10
        nameLbl.TextWrapped = true
        nameLbl.TextColor3 = PALETTE.TEXT_PRIMARY
        nameLbl.Text = slotInfo.name
        nameLbl.Parent = btn

        -- Translucent vertical wipe cooldown overlay
        local cdOverlay = Instance.new("Frame")
        cdOverlay.Name = "CooldownOverlay"
        cdOverlay.Size = UDim2.new(1, 0, 0, 0)
        cdOverlay.Position = UDim2.new(0, 0, 1, 0)
        cdOverlay.AnchorPoint = Vector2.new(0, 1)
        cdOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
        cdOverlay.BackgroundTransparency = 0.25
        cdOverlay.Visible = false
        cdOverlay.Parent = btn
        MakeCorner(cdOverlay, 8)

        local cdText = Instance.new("TextLabel")
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamBlack
        cdText.TextSize = 18
        cdText.TextColor3 = PALETTE.TEXT_PRIMARY
        cdText.Text = ""
        cdText.Parent = cdOverlay

        -- Hover and tactile press animations
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(0, 74, 0, 74), BackgroundColor3 = PALETTE.BG_CARD }):Play()
            SoundController.PlayUI("hover")
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(0, 70, 0, 70), BackgroundColor3 = PALETTE.BG_SLOT }):Play()
        end)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                TweenService:Create(btn, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 65, 0, 65) }):Play()
                task.delay(0.08, function()
                    TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 70, 0, 70) }):Play()
                end)
                local combatController = require(script.Parent.CombatController)
                combatController.Cast(slot)
            end
        end)

        abilityButtons[slot] = {
            Button = btn,
            CooldownOverlay = cdOverlay,
            CooldownText = cdText,
            NameLabel = nameLbl,
            KeyLabel = keyText,
            Stroke = btnStroke,
        }
    end

    -- ==================== 3. ERROR METER (For Secret Error Element) ====================
    errorMeterContainer = Instance.new("Frame")
    errorMeterContainer.Name = "ErrorMeter"
    errorMeterContainer.Size = UDim2.new(0, 320, 0, 22)
    errorMeterContainer.Position = UDim2.new(0.5, -160, 1, -128)
    errorMeterContainer.BackgroundColor3 = Color3.fromRGB(16, 10, 24)
    errorMeterContainer.Visible = false
    errorMeterContainer.Parent = screenGui
    MakeCorner(errorMeterContainer, 6)
    MakeStroke(errorMeterContainer, Color3.fromRGB(255, 20, 140), 1.5)

    errorMeterFill = Instance.new("Frame")
    errorMeterFill.Size = UDim2.new(0, 0, 1, 0)
    errorMeterFill.BackgroundColor3 = Color3.fromRGB(255, 20, 140)
    errorMeterFill.BorderSizePixel = 0
    errorMeterFill.Parent = errorMeterContainer
    MakeCorner(errorMeterFill, 6)

    errorMeterText = Instance.new("TextLabel")
    errorMeterText.Size = UDim2.new(1, 0, 1, 0)
    errorMeterText.BackgroundTransparency = 1
    errorMeterText.Font = Enum.Font.GothamBlack
    errorMeterText.TextSize = 11
    errorMeterText.TextColor3 = PALETTE.TEXT_PRIMARY
    errorMeterText.Text = "ERROR METER: 0%"
    errorMeterText.Parent = errorMeterContainer

    -- ==================== 4. BLOX FRUITS COMBO COUNTER ====================
    comboLabel = Instance.new("TextLabel")
    comboLabel.Name = "BloxFruitsCombo"
    comboLabel.Size = UDim2.new(0, 240, 0, 48)
    comboLabel.Position = UDim2.new(0.12, 0, 0.45, 0)
    comboLabel.BackgroundTransparency = 1
    comboLabel.Font = Enum.Font.GothamBlack
    comboLabel.TextSize = 34
    comboLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    comboLabel.TextStrokeColor3 = Color3.fromRGB(15, 20, 32)
    comboLabel.TextStrokeTransparency = 0.2
    comboLabel.TextXAlignment = Enum.TextXAlignment.Left
    comboLabel.Visible = false
    comboLabel.Text = "COMBO x3"
    comboLabel.Parent = screenGui

    -- ==================== 5. ANNOUNCEMENT BANNER ====================
    announcementBanner = Instance.new("Frame")
    announcementBanner.Name = "AnnouncementBanner"
    announcementBanner.Size = UDim2.new(0, 620, 0, 44)
    announcementBanner.Position = UDim2.new(0.5, -310, 0, 36)
    announcementBanner.BackgroundColor3 = PALETTE.BG_MAIN
    announcementBanner.BackgroundTransparency = 0.12
    announcementBanner.Visible = false
    announcementBanner.Parent = screenGui
    MakeCorner(announcementBanner, 8)
    MakeStroke(announcementBanner, PALETTE.BORDER_ACCENT, 1.8)

    announcementLabel = Instance.new("TextLabel")
    announcementLabel.Size = UDim2.new(1, -20, 1, 0)
    announcementLabel.Position = UDim2.new(0, 10, 0, 0)
    announcementLabel.BackgroundTransparency = 1
    announcementLabel.Font = Enum.Font.GothamBlack
    announcementLabel.TextSize = 14
    announcementLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    announcementLabel.Text = ""
    announcementLabel.Parent = announcementBanner

    -- ==================== 6. FRAGMENT NOTIFICATION ====================
    fragmentNotif = Instance.new("Frame")
    fragmentNotif.Name = "FragmentNotif"
    fragmentNotif.Size = UDim2.new(0, 340, 0, 52)
    fragmentNotif.Position = UDim2.new(1, -360, 0.5, -26)
    fragmentNotif.BackgroundColor3 = PALETTE.BG_MAIN
    fragmentNotif.BackgroundTransparency = 0.12
    fragmentNotif.Visible = false
    fragmentNotif.Parent = screenGui
    MakeCorner(fragmentNotif, 8)
    MakeStroke(fragmentNotif, PALETTE.ENERGY_CYAN, 2.0)

    fragmentLabel = Instance.new("TextLabel")
    fragmentLabel.Size = UDim2.new(1, -16, 1, 0)
    fragmentLabel.Position = UDim2.new(0, 8, 0, 0)
    fragmentLabel.BackgroundTransparency = 1
    fragmentLabel.Font = Enum.Font.GothamBold
    fragmentLabel.TextSize = 13
    fragmentLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    fragmentLabel.TextXAlignment = Enum.TextXAlignment.Left
    fragmentLabel.TextWrapped = true
    fragmentLabel.Text = "Fragment Discovered!"
    fragmentLabel.Parent = fragmentNotif

    -- ==================== 7. REGION BADGE (Top-Right) ====================
    local regionFrame = Instance.new("Frame")
    regionFrame.Size = UDim2.new(0, 200, 0, 32)
    regionFrame.Position = UDim2.new(1, -220, 0, 16)
    regionFrame.BackgroundColor3 = PALETTE.BG_MAIN
    regionFrame.BackgroundTransparency = 0.15
    regionFrame.Parent = screenGui
    MakeCorner(regionFrame, 6)
    MakeStroke(regionFrame, PALETTE.BORDER_DEFAULT, 1.2)

    regionLabel = Instance.new("TextLabel")
    regionLabel.Size = UDim2.new(1, -16, 1, 0)
    regionLabel.Position = UDim2.new(0, 8, 0, 0)
    regionLabel.BackgroundTransparency = 1
    regionLabel.Font = Enum.Font.GothamBold
    regionLabel.TextSize = 12
    regionLabel.TextColor3 = PALETTE.TEXT_MUTED
    regionLabel.TextXAlignment = Enum.TextXAlignment.Right
    regionLabel.Text = "Ember Highlands"
    regionLabel.Parent = regionFrame

    -- Blind Flash Overlay
    blindOverlay = Instance.new("Frame")
    blindOverlay.Name = "BlindOverlay"
    blindOverlay.Size = UDim2.new(1, 0, 1, 0)
    blindOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    blindOverlay.BackgroundTransparency = 1
    blindOverlay.ZIndex = 80
    blindOverlay.Parent = screenGui
end

-- ==================== HEALTH UPDATES ====================
function UIController.SetHealth(newHealth: number, maxHealth: number)
    currentHealth = math.clamp(newHealth, 0, maxHealth)
    currentMaxHealth = maxHealth

    local ratio = math.clamp(currentHealth / currentMaxHealth, 0, 1)

    if healthText then
        healthText.Text = string.format("%d / %d", math.round(currentHealth), math.round(currentMaxHealth))
    end

    if healthFill then
        healthFill.Size = UDim2.new(ratio, 0, 1, 0)
        -- Dynamic shift: Emerald green > Orange > Crimson
        healthFill.BackgroundColor3 = (ratio > 0.5)
            and PALETTE.HP_GREEN
            or (ratio > 0.25 and PALETTE.HP_ORANGE or PALETTE.HP_RED)
    end

    -- Catch-up damage chip
    if healthChip then
        task.delay(0.25, function()
            if healthChip then
                TweenService:Create(healthChip, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(ratio, 0, 1, 0),
                }):Play()
            end
        end)
    end
end

-- ==================== ENERGY / STAMINA ====================
function UIController.SetEnergy(newEnergy: number, maxEng: number)
    currentEnergy = math.clamp(newEnergy, 0, maxEng)
    maxEnergy = maxEng

    local ratio = math.clamp(currentEnergy / maxEnergy, 0, 1)
    if energyFill then
        energyFill.Size = UDim2.new(ratio, 0, 1, 0)
    end
    if energyText then
        energyText.Text = string.format("%d / %d", math.round(currentEnergy), math.round(maxEnergy))
    end
end

function UIController.ConsumeEnergy(amount: number): boolean
    if currentEnergy >= amount then
        currentEnergy -= amount
        UIController.SetEnergy(currentEnergy, maxEnergy)
        return true
    end
    return false
end

-- ==================== COMBO COUNTER ====================
function UIController.RegisterComboHit(count: number)
    currentCombo = count
    lastComboTime = os.clock()

    if comboLabel then
        comboLabel.Text = string.format("COMBO x%d", count)
        comboLabel.Visible = true
        comboLabel.TextSize = 42
        comboLabel.TextColor3 = if count >= 4 then PALETTE.BORDER_ACCENT else PALETTE.TEXT_PRIMARY

        TweenService:Create(comboLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 34,
        }):Play()

        task.delay(1.5, function()
            if os.clock() - lastComboTime >= 1.4 then
                if comboLabel then
                    local t = TweenService:Create(comboLabel, TweenInfo.new(0.25), { TextTransparency = 1 })
                    t:Play()
                    t.Completed:Wait()
                    comboLabel.Visible = false
                    comboLabel.TextTransparency = 0
                end
            end
        end)
    end
end

-- ==================== STATS SYNC ====================
function UIController.UpdateStats(data: {
    Level: number,
    Charges: number,
    Element: string,
    ErrorMeter: number,
    MaxHealth: number,
    SpinTickets: number?,
})
    if levelBadgeText then
        levelBadgeText.Text = "Lv. " .. tostring(data.Level)
    end

    if spinTicketText then
        spinTicketText.Text = string.format("Spins: %d | Charges: %d", data.SpinTickets or 0, data.Charges)
    end

    local theme = ELEMENT_THEMES[data.Element] or ELEMENT_THEMES.Fire
    if elementTagText then
        elementTagText.Text = string.upper(data.Element)
        elementTagText.TextColor3 = theme.Primary
    end
    if elementTagFrame then
        local stroke = elementTagFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Primary
        end
    end

    -- Update slot labels and borders
    for slot, btnData in abilityButtons do
        local ability = AbilityConfig.GetAbility(data.Element, slot)
        if ability then
            btnData.NameLabel.Text = ability.Name
        end
        TweenService:Create(btnData.Stroke, TweenInfo.new(0.3), { Color = theme.Primary }):Play()
    end

    -- Error meter
    if errorMeterContainer and errorMeterFill and errorMeterText then
        local isError = (data.Element == "Error")
        errorMeterContainer.Visible = isError
        if isError then
            local ratio = math.clamp(data.ErrorMeter / 100, 0, 1)
            TweenService:Create(errorMeterFill, TweenInfo.new(0.25), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
            errorMeterText.Text = string.format("ERROR METER: %d%%", math.round(data.ErrorMeter))
        end
    end

    if abilityButtons["5"] then
        abilityButtons["5"].Button.Visible = (data.Element == "Error")
    end

    UIController.SetHealth(currentHealth, data.MaxHealth)
end

-- ==================== COOLDOWN TIMER & READY FLASH ====================
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

                -- Off-cooldown flash effect!
                local origColor = btnData.Stroke.Color
                TweenService:Create(btnData.Stroke, TweenInfo.new(0.08), { Color = Color3.fromRGB(255, 255, 255), Thickness = 3.2 }):Play()
                task.delay(0.15, function()
                    TweenService:Create(btnData.Stroke, TweenInfo.new(0.2), { Color = origColor, Thickness = 1.8 }):Play()
                end)
                break
            end

            cdText.Text = string.format("%.1f", remaining)
            overlay.Size = UDim2.new(1, 0, remaining / durationSeconds, 0)
            task.wait(0.04)
        end
    end)
end

-- ==================== ANNOUNCEMENTS ====================
function UIController.ShowAnnouncement(text: string)
    if not announcementBanner or not announcementLabel then return end

    announcementLabel.Text = text
    announcementBanner.Visible = true
    announcementBanner.BackgroundTransparency = 0.12
    announcementLabel.TextTransparency = 0

    task.delay(4.0, function()
        if announcementBanner then
            local t = TweenService:Create(announcementBanner, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
            TweenService:Create(announcementLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
            t:Play()
            t.Completed:Wait()
            announcementBanner.Visible = false
            announcementLabel.TextTransparency = 0
        end
    end)
end

-- ==================== FRAGMENT NOTIFICATION ====================
function UIController.ShowFragmentCollected(fragmentName: string)
    if not fragmentNotif or not fragmentLabel then return end

    fragmentLabel.Text = "[FRAGMENT DISCOVERED]\n" .. fragmentName
    fragmentNotif.Visible = true
    fragmentNotif.Position = UDim2.new(1, 10, 0.5, -26)

    TweenService:Create(fragmentNotif, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -360, 0.5, -26),
    }):Play()

    task.delay(3.5, function()
        if fragmentNotif then
            local t = TweenService:Create(fragmentNotif, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 10, 0.5, -26),
            })
            t:Play()
            t.Completed:Wait()
            fragmentNotif.Visible = false
        end
    end)
end

function UIController.SetRegion(regionName: string)
    if regionLabel then
        regionLabel.Text = regionName
    end
end

function UIController.TriggerBlind(durationSeconds: number)
    if not blindOverlay then return end
    blindOverlay.BackgroundTransparency = 0
    TweenService:Create(blindOverlay, TweenInfo.new(durationSeconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    }):Play()
end

return table.freeze(UIController)
