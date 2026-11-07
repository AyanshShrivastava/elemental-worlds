--!strict
--[[
    Elemental Worlds: Master Anime Combat HUD & UI Controller
    Top-tier modern anime RPG interface inspired by Blox Fruits, Jujutsu Shenanigans,
    and The Strongest Battlegrounds.
    
    Aesthetic rules:
    - Deep obsidian-slate glassmorphism (Color3.fromRGB(10, 14, 22), 0.18 transparency)
    - Dynamic element theme rim lighting on borders and badges
    - Beveled Player Avatar Card with Level & Element Crest
    - Dual Segmented Stats: Emerald-to-Crimson Health with Lag Damage Ghost Chip + Electric Cyan Energy
    - Critical Health Pulsing Red Screen Vignette
    - Modern Angled Ability Deck (Hotbar): M1, Z, X, C, V, Secret (B), Dash (Q)
    - Off-cooldown luminous ready flare with elastic scale pop and audio chime
    - Elastic Punch Combo Counter with tiered color shifts
    - Cybernetic Error Meter for secret elemental mastery
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

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

-- Modern Deep Slate & Obsidian Glass Tokens
local PALETTE = {
    BG_OBSIDIAN     = Color3.fromRGB(10, 14, 22),
    BG_CARD         = Color3.fromRGB(16, 22, 34),
    BG_SLOT         = Color3.fromRGB(14, 18, 30),
    BORDER_DEFAULT  = Color3.fromRGB(40, 52, 75),
    BORDER_ACCENT   = Color3.fromRGB(120, 95, 255),
    TEXT_PRIMARY    = Color3.fromRGB(245, 248, 255),
    TEXT_MUTED      = Color3.fromRGB(140, 152, 175),
    HP_GREEN        = Color3.fromRGB(46, 204, 113),
    HP_ORANGE       = Color3.fromRGB(230, 126, 34),
    HP_RED          = Color3.fromRGB(231, 76, 60),
    HP_CHIP         = Color3.fromRGB(150, 25, 25),
    ENERGY_CYAN     = Color3.fromRGB(0, 190, 255),
    ENERGY_DARK     = Color3.fromRGB(8, 48, 90),
}

-- Curated Vibrant Anime Element Accents
local ELEMENT_THEMES: { [string]: { Primary: Color3, Secondary: Color3, Accent: Color3 } } = {
    Fire  = { Primary = Color3.fromRGB(255, 80, 25),  Secondary = Color3.fromRGB(255, 145, 40), Accent = Color3.fromRGB(255, 235, 160) },
    Aqua  = { Primary = Color3.fromRGB(0, 175, 255),  Secondary = Color3.fromRGB(60, 230, 220), Accent = Color3.fromRGB(220, 250, 255) },
    Earth = { Primary = Color3.fromRGB(175, 125, 75), Secondary = Color3.fromRGB(130, 95, 60),  Accent = Color3.fromRGB(240, 205, 165) },
    Light = { Primary = Color3.fromRGB(225, 190, 255), Secondary = Color3.fromRGB(255, 235, 130), Accent = Color3.fromRGB(255, 255, 255) },
    Wind  = { Primary = Color3.fromRGB(60, 225, 165), Secondary = Color3.fromRGB(160, 255, 220), Accent = Color3.fromRGB(235, 255, 250) },
    Error = { Primary = Color3.fromRGB(255, 20, 140), Secondary = Color3.fromRGB(0, 255, 240), Accent = Color3.fromRGB(255, 255, 255) },
    Time  = { Primary = Color3.fromRGB(130, 85, 255), Secondary = Color3.fromRGB(0, 240, 255), Accent = Color3.fromRGB(255, 225, 120) },
}

-- GUI Object References
local screenGui: ScreenGui? = nil
local playerCard: Frame? = nil
local avatarImage: ImageLabel? = nil
local avatarStroke: UIStroke? = nil
local playerNameLabel: TextLabel? = nil
local levelBadgeText: TextLabel? = nil
local elementTagFrame: Frame? = nil
local elementTagText: TextLabel? = nil
local currencyPillText: TextLabel? = nil

local healthFill: Frame? = nil
local healthChip: Frame? = nil
local healthText: TextLabel? = nil
local energyFill: Frame? = nil
local energyText: TextLabel? = nil

local comboLabel: TextLabel? = nil
local announcementBanner: Frame? = nil
local announcementLabel: TextLabel? = nil
local fragmentNotif: Frame? = nil
local fragmentLabel: TextLabel? = nil
local regionLabel: TextLabel? = nil
local blindOverlay: Frame? = nil
local lowHealthOverlay: Frame? = nil

local errorMeterContainer: Frame? = nil
local errorMeterFill: Frame? = nil
local errorMeterText: TextLabel? = nil

local abilityButtons: { [string]: {
    Button: TextButton,
    Card: Frame,
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
local currentElement = "Fire"

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

local function MakeGradient(inst: GuiObject, colorSeq: ColorSequence, rot: number?)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq
    g.Rotation = rot or 90
    g.Parent = inst
    return g
end

-- ==================== CREATE MASTER ANIME COMBAT HUD ====================
function UIController.CreateHUD()
    local playerGui = GetPlayerGui()
    if not playerGui then
        warn("[UIController] PlayerGui not available yet.")
        return
    end

    if screenGui and screenGui.Parent == playerGui then
        return
    end

    local existing = playerGui:FindFirstChild("ElementalWorlds_MasterHUD") :: ScreenGui?
    if existing then
        screenGui = existing
        return
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ElementalWorlds_MasterHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local userId = localPlayer and localPlayer.UserId or 1
    local displayName = localPlayer and localPlayer.DisplayName or "Hero"

    -- ==================== 1. GLASSMORPHIC PLAYER CARD (Top-Left) ====================
    playerCard = Instance.new("Frame")
    playerCard.Name = "PlayerCard"
    playerCard.Size = UDim2.new(0, 330, 0, 88)
    playerCard.Position = UDim2.new(0, 18, 0, 16)
    playerCard.BackgroundColor3 = PALETTE.BG_OBSIDIAN
    playerCard.BackgroundTransparency = 0.18
    playerCard.Parent = screenGui
    MakeCorner(playerCard, 10)
    local cardStroke = MakeStroke(playerCard, PALETTE.BORDER_DEFAULT, 1.4)

    -- Avatar Portrait Dock
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Name = "AvatarDock"
    avatarFrame.Size = UDim2.new(0, 56, 0, 56)
    avatarFrame.Position = UDim2.new(0, 10, 0, 16)
    avatarFrame.BackgroundColor3 = PALETTE.BG_CARD
    avatarFrame.Parent = playerCard
    MakeCorner(avatarFrame, 8)
    avatarStroke = MakeStroke(avatarFrame, ELEMENT_THEMES.Fire.Primary, 1.8)

    avatarImage = Instance.new("ImageLabel")
    avatarImage.Name = "AvatarThumbnail"
    avatarImage.Size = UDim2.new(1, -4, 1, -4)
    avatarImage.Position = UDim2.new(0, 2, 0, 2)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
    avatarImage.Parent = avatarFrame
    MakeCorner(avatarImage, 6)

    -- Player Header Details (Right of Avatar)
    local headerRow = Instance.new("Frame")
    headerRow.Name = "HeaderRow"
    headerRow.Size = UDim2.new(1, -78, 0, 20)
    headerRow.Position = UDim2.new(0, 74, 0, 8)
    headerRow.BackgroundTransparency = 1
    headerRow.Parent = playerCard

    playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.Name = "PlayerName"
    playerNameLabel.Size = UDim2.new(0, 110, 1, 0)
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Font = Enum.Font.GothamBlack
    playerNameLabel.TextSize = 13
    playerNameLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    playerNameLabel.Text = displayName
    playerNameLabel.Parent = headerRow

    levelBadgeText = Instance.new("TextLabel")
    levelBadgeText.Name = "LevelBadge"
    levelBadgeText.Size = UDim2.new(0, 48, 1, 0)
    levelBadgeText.Position = UDim2.new(0, 112, 0, 0)
    levelBadgeText.BackgroundTransparency = 1
    levelBadgeText.Font = Enum.Font.GothamBold
    levelBadgeText.TextSize = 11
    levelBadgeText.TextColor3 = PALETTE.BORDER_ACCENT
    levelBadgeText.TextXAlignment = Enum.TextXAlignment.Left
    levelBadgeText.Text = "Lv. 1"
    levelBadgeText.Parent = headerRow

    elementTagFrame = Instance.new("Frame")
    elementTagFrame.Name = "ElementBadge"
    elementTagFrame.Size = UDim2.new(0, 68, 1, 0)
    elementTagFrame.Position = UDim2.new(1, -72, 0, 0)
    elementTagFrame.BackgroundColor3 = PALETTE.BG_CARD
    elementTagFrame.Parent = headerRow
    MakeCorner(elementTagFrame, 4)
    local elemStroke = MakeStroke(elementTagFrame, ELEMENT_THEMES.Fire.Primary, 1.2)

    elementTagText = Instance.new("TextLabel")
    elementTagText.Size = UDim2.new(1, 0, 1, 0)
    elementTagText.BackgroundTransparency = 1
    elementTagText.Font = Enum.Font.GothamBlack
    elementTagText.TextSize = 10
    elementTagText.TextColor3 = ELEMENT_THEMES.Fire.Primary
    elementTagText.Text = "FIRE"
    elementTagText.Parent = elementTagFrame

    -- Segmented Health Bar Track (Emerald Green with Catch-Up Damage Chip)
    local hpTrack = Instance.new("Frame")
    hpTrack.Name = "HealthTrack"
    hpTrack.Size = UDim2.new(1, -84, 0, 20)
    hpTrack.Position = UDim2.new(0, 74, 0, 32)
    hpTrack.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
    hpTrack.Parent = playerCard
    MakeCorner(hpTrack, 5)
    MakeStroke(hpTrack, Color3.fromRGB(30, 42, 60), 1.0)

    healthChip = Instance.new("Frame")
    healthChip.Name = "HealthChip"
    healthChip.Size = UDim2.new(1, 0, 1, 0)
    healthChip.BackgroundColor3 = PALETTE.HP_CHIP
    healthChip.BorderSizePixel = 0
    healthChip.Parent = hpTrack
    MakeCorner(healthChip, 5)

    healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = PALETTE.HP_GREEN
    healthFill.BorderSizePixel = 0
    healthFill.Parent = hpTrack
    MakeCorner(healthFill, 5)

    healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Font = Enum.Font.GothamBlack
    healthText.TextSize = 10
    healthText.TextColor3 = PALETTE.TEXT_PRIMARY
    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthText.TextStrokeTransparency = 0.4
    healthText.Text = "100 / 100"
    healthText.Parent = hpTrack

    -- Segmented Energy / Stamina Bar Track (Electric Cyan Fill)
    local energyTrack = Instance.new("Frame")
    energyTrack.Name = "EnergyTrack"
    energyTrack.Size = UDim2.new(1, -84, 0, 16)
    energyTrack.Position = UDim2.new(0, 74, 0, 56)
    energyTrack.BackgroundColor3 = Color3.fromRGB(6, 14, 24)
    energyTrack.Parent = playerCard
    MakeCorner(energyTrack, 5)
    MakeStroke(energyTrack, Color3.fromRGB(15, 38, 64), 1.0)

    energyFill = Instance.new("Frame")
    energyFill.Name = "EnergyFill"
    energyFill.Size = UDim2.new(1, 0, 1, 0)
    energyFill.BackgroundColor3 = PALETTE.ENERGY_CYAN
    energyFill.BorderSizePixel = 0
    energyFill.Parent = energyTrack
    MakeCorner(energyFill, 5)

    energyText = Instance.new("TextLabel")
    energyText.Size = UDim2.new(1, 0, 1, 0)
    energyText.BackgroundTransparency = 1
    energyText.Font = Enum.Font.GothamBold
    energyText.TextSize = 9
    energyText.TextColor3 = PALETTE.TEXT_PRIMARY
    energyText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    energyText.TextStrokeTransparency = 0.4
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

    -- Critical Low Health Pulsing Vignette (Screen Edges)
    lowHealthOverlay = Instance.new("Frame")
    lowHealthOverlay.Name = "LowHealthOverlay"
    lowHealthOverlay.Size = UDim2.new(1, 0, 1, 0)
    lowHealthOverlay.BackgroundColor3 = Color3.fromRGB(230, 30, 30)
    lowHealthOverlay.BackgroundTransparency = 1
    lowHealthOverlay.ZIndex = 50
    lowHealthOverlay.Parent = screenGui

    -- ==================== 2. MASTER ANIME ABILITY DECK (Bottom-Center) ====================
    local hotbar = Instance.new("Frame")
    hotbar.Name = "AbilityHotbar"
    hotbar.Size = UDim2.new(0, 560, 0, 78)
    hotbar.AnchorPoint = Vector2.new(0.5, 1)
    hotbar.Position = UDim2.new(0.5, 0, 1, -18)
    hotbar.BackgroundTransparency = 1
    hotbar.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.Parent = hotbar

    local slots = {
        { slot = "M1",   key = "M1", name = "Basic Attack" },
        { slot = "1",    key = "Z",  name = "Move 1" },
        { slot = "2",    key = "X",  name = "Move 2" },
        { slot = "3",    key = "C",  name = "Move 3" },
        { slot = "4",    key = "V",  name = "Move 4" },
        { slot = "5",    key = "B",  name = "Secret" },
        { slot = "Dash", key = "Q",  name = "Dash" },
    }

    for _, slotInfo in slots do
        local slot = slotInfo.slot
        local card = Instance.new("Frame")
        card.Name = "Card_" .. slot
        card.Size = UDim2.new(0, 70, 0, 70)
        card.BackgroundTransparency = 1
        card.Parent = hotbar

        local btn = Instance.new("TextButton")
        btn.Name = "SlotBtn"
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = PALETTE.BG_SLOT
        btn.BackgroundTransparency = 0.15
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = card
        MakeCorner(btn, 8)
        local btnStroke = MakeStroke(btn, PALETTE.BORDER_DEFAULT, 1.8)

        -- Keybind Badge [Z], [X], [C], [V], [Q]
        local keyBadge = Instance.new("Frame")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.new(0, 24, 0, 18)
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

        -- Ability Name Label
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "AbilityName"
        nameLbl.Size = UDim2.new(1, -10, 0, 36)
        nameLbl.Position = UDim2.new(0, 5, 1, -40)
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
        cdOverlay.BackgroundColor3 = Color3.fromRGB(4, 6, 12)
        cdOverlay.BackgroundTransparency = 0.22
        cdOverlay.Visible = false
        cdOverlay.Parent = btn
        MakeCorner(cdOverlay, 8)

        local cdText = Instance.new("TextLabel")
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.BackgroundTransparency = 1
        cdText.Font = Enum.Font.GothamBlack
        cdText.TextSize = 18
        cdText.TextColor3 = PALETTE.TEXT_PRIMARY
        cdText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        cdText.TextStrokeTransparency = 0.25
        cdText.Text = ""
        cdText.Parent = cdOverlay

        -- Tactile hover and spring press feedback
        btn.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 74, 0, 74),
            }):Play()
            btn.BackgroundColor3 = PALETTE.BG_CARD
            SoundController.PlayUI("hover")
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 70, 0, 70),
            }):Play()
            btn.BackgroundColor3 = PALETTE.BG_SLOT
        end)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                TweenService:Create(card, TweenInfo.new(0.06), { Size = UDim2.new(0, 65, 0, 65) }):Play()
                task.delay(0.08, function()
                    TweenService:Create(card, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 70, 0, 70) }):Play()
                end)
                local hasCombat, combatController = pcall(function() return require(script.Parent.CombatController) end)
                if hasCombat and combatController and (combatController :: any).Cast then
                    (combatController :: any).Cast(slot)
                end
            end
        end)

        abilityButtons[slot] = {
            Button = btn,
            Card = card,
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
    errorMeterContainer.Size = UDim2.new(0, 440, 0, 24)
    errorMeterContainer.AnchorPoint = Vector2.new(0.5, 1)
    errorMeterContainer.Position = UDim2.new(0.5, 0, 1, -104)
    errorMeterContainer.BackgroundColor3 = Color3.fromRGB(14, 8, 22)
    errorMeterContainer.Visible = false
    errorMeterContainer.Parent = screenGui
    MakeCorner(errorMeterContainer, 6)
    MakeStroke(errorMeterContainer, Color3.fromRGB(255, 20, 140), 1.6)

    errorMeterFill = Instance.new("Frame")
    errorMeterFill.Size = UDim2.new(0, 0, 1, 0)
    errorMeterFill.BackgroundColor3 = Color3.fromRGB(255, 20, 140)
    errorMeterFill.BorderSizePixel = 0
    errorMeterFill.Parent = errorMeterContainer
    MakeCorner(errorMeterFill, 6)
    MakeGradient(errorMeterFill, ColorSequence.new(Color3.fromRGB(255, 20, 140), Color3.fromRGB(0, 240, 255)), 0)

    errorMeterText = Instance.new("TextLabel")
    errorMeterText.Size = UDim2.new(1, 0, 1, 0)
    errorMeterText.BackgroundTransparency = 1
    errorMeterText.Font = Enum.Font.GothamBlack
    errorMeterText.TextSize = 11
    errorMeterText.TextColor3 = PALETTE.TEXT_PRIMARY
    errorMeterText.Text = "ERROR METER: 0%"
    errorMeterText.Parent = errorMeterContainer

    -- ==================== 4. ELASTIC PUNCH COMBO COUNTER ====================
    comboLabel = Instance.new("TextLabel")
    comboLabel.Name = "AnimeComboCounter"
    comboLabel.Size = UDim2.new(0, 260, 0, 52)
    comboLabel.Position = UDim2.new(0.12, 0, 0.45, 0)
    comboLabel.BackgroundTransparency = 1
    comboLabel.Font = Enum.Font.GothamBlack
    comboLabel.TextSize = 36
    comboLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    comboLabel.TextStrokeColor3 = Color3.fromRGB(10, 14, 24)
    comboLabel.TextStrokeTransparency = 0.2
    comboLabel.TextXAlignment = Enum.TextXAlignment.Left
    comboLabel.Visible = false
    comboLabel.Text = "COMBO x3"
    comboLabel.Parent = screenGui

    -- ==================== 5. ANNOUNCEMENT BANNER ====================
    announcementBanner = Instance.new("Frame")
    announcementBanner.Name = "AnnouncementBanner"
    announcementBanner.Size = UDim2.new(0, 640, 0, 46)
    announcementBanner.Position = UDim2.new(0.5, -320, 0, 36)
    announcementBanner.BackgroundColor3 = PALETTE.BG_OBSIDIAN
    announcementBanner.BackgroundTransparency = 0.15
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
    fragmentNotif.Size = UDim2.new(0, 360, 0, 56)
    fragmentNotif.Position = UDim2.new(1, -380, 0.5, -28)
    fragmentNotif.BackgroundColor3 = PALETTE.BG_OBSIDIAN
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
    regionFrame.Size = UDim2.new(0, 210, 0, 34)
    regionFrame.Position = UDim2.new(1, -230, 0, 16)
    regionFrame.BackgroundColor3 = PALETTE.BG_OBSIDIAN
    regionFrame.BackgroundTransparency = 0.18
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

-- ==================== HEALTH UPDATES & DAMAGE CHIP ====================
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

    -- Smooth Catch-up Damage Ghost Chip
    if healthChip then
        task.delay(0.25, function()
            if healthChip then
                TweenService:Create(healthChip, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(ratio, 0, 1, 0),
                }):Play()
            end
        end)
    end

    -- Low health heartbeat screen vignette pulse
    if lowHealthOverlay then
        if ratio <= 0.25 and ratio > 0 then
            TweenService:Create(lowHealthOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundTransparency = 0.75,
            }):Play()
        else
            TweenService:Create(lowHealthOverlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        end
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

-- ==================== ELASTIC PUNCH COMBO COUNTER ====================
function UIController.RegisterComboHit(count: number)
    currentCombo = count
    lastComboTime = os.clock()

    if comboLabel then
        comboLabel.Text = string.format("COMBO x%d", count)
        comboLabel.Visible = true
        comboLabel.TextSize = 46

        -- Dynamic Tiered Color Progression
        if count >= 15 then
            comboLabel.TextColor3 = Color3.fromRGB(168, 85, 247) -- Void Amethyst
        elseif count >= 8 then
            comboLabel.TextColor3 = Color3.fromRGB(255, 185, 30) -- Blazing Amber
        elseif count >= 4 then
            comboLabel.TextColor3 = PALETTE.ENERGY_CYAN -- Electric Cyan
        else
            comboLabel.TextColor3 = PALETTE.TEXT_PRIMARY
        end

        -- Elastic spring punch bounce
        TweenService:Create(comboLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 36,
        }):Play()

        task.delay(1.6, function()
            if os.clock() - lastComboTime >= 1.5 then
                if comboLabel then
                    local t = TweenService:Create(comboLabel, TweenInfo.new(0.3), { TextTransparency = 1 })
                    t:Play()
                    t.Completed:Wait()
                    comboLabel.Visible = false
                    comboLabel.TextTransparency = 0
                end
            end
        end)
    end
end

-- ==================== STATS & ELEMENT THEME SYNC ====================
function UIController.UpdateStats(data: {
    Level: number,
    Charges: number,
    Element: string,
    ErrorMeter: number,
    MaxHealth: number,
    SpinTickets: number?,
})
    currentElement = data.Element
    local theme = ELEMENT_THEMES[data.Element] or ELEMENT_THEMES.Fire

    if levelBadgeText then
        levelBadgeText.Text = "Lv. " .. tostring(data.Level)
    end

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
    if avatarStroke then
        avatarStroke.Color = theme.Primary
    end

    -- Update slot names and dynamic border glow
    for slot, btnData in abilityButtons do
        if slot == "Dash" then
            btnData.NameLabel.Text = "Dash"
        else
            local ability = AbilityConfig.GetAbility(data.Element, slot)
            if ability then
                btnData.NameLabel.Text = ability.Name
            end
        end
        TweenService:Create(btnData.Stroke, TweenInfo.new(0.3), { Color = theme.Primary }):Play()
        btnData.KeyLabel.TextColor3 = theme.Secondary
    end

    -- Error Meter
    if errorMeterContainer and errorMeterFill and errorMeterText then
        local isError = (data.Element == "Error")
        errorMeterContainer.Visible = isError
        if isError then
            local pct = math.round(data.ErrorMeter)
            if pct >= 100 then
                errorMeterText.Text = "ERROR METER: 100% [MAX POWER: UNPARALLELED READY]"
            elseif pct >= 50 then
                errorMeterText.Text = string.format("ERROR METER: %d%% [DOMAIN UNLOCKED] (100%%: Freeze)", pct)
            else
                errorMeterText.Text = string.format("ERROR METER: %d%% (50%%: Domain | 100%%: Freeze)", pct)
            end
        end
    end

    if abilityButtons["5"] then
        abilityButtons["5"].Card.Visible = (data.Element == "Error")
    end

    UIController.SetHealth(currentHealth, data.MaxHealth)
end

-- ==================== COOLDOWN TIMER & READY FLARE ====================
function UIController.StartCooldown(slot: string, durationSeconds: number)
    local btnData = abilityButtons[slot]
    if not btnData then return end

    local overlay = btnData.CooldownOverlay
    local cdText = btnData.CooldownText
    local theme = ELEMENT_THEMES[currentElement] or ELEMENT_THEMES.Fire

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

                -- Off-Cooldown Luminous Ready Flare & Scale Pop!
                SoundController.PlayUI("success")
                local origColor = theme.Primary
                TweenService:Create(btnData.Stroke, TweenInfo.new(0.08), { Color = Color3.fromRGB(255, 255, 255), Thickness = 3.8 }):Play()
                TweenService:Create(btnData.Card, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 76, 0, 76) }):Play()

                task.delay(0.14, function()
                    TweenService:Create(btnData.Stroke, TweenInfo.new(0.25), { Color = origColor, Thickness = 1.8 }):Play()
                    TweenService:Create(btnData.Card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 70, 0, 70) }):Play()
                end)
                break
            end

            cdText.Text = string.format("%.1f", remaining)
            overlay.Size = UDim2.new(1, 0, remaining / durationSeconds, 0)
            task.wait(0.04)
        end
    end)
end

-- ==================== ANNOUNCEMENTS & REGION ====================
function UIController.ShowAnnouncement(text: string)
    if not announcementBanner or not announcementLabel then return end

    announcementLabel.Text = text
    announcementBanner.Visible = true
    announcementBanner.BackgroundTransparency = 0.15
    announcementLabel.TextTransparency = 0

    task.delay(4.0, function()
        if announcementBanner then
            local t = TweenService:Create(announcementBanner, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            TweenService:Create(announcementLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
            t:Play()
            t.Completed:Wait()
            announcementBanner.Visible = false
            announcementLabel.TextTransparency = 0
        end
    end)
end

function UIController.ShowFragmentCollected(fragmentName: string)
    if not fragmentNotif or not fragmentLabel then return end

    fragmentLabel.Text = "[FRAGMENT DISCOVERED]\n" .. fragmentName
    fragmentNotif.Visible = true
    fragmentNotif.Position = UDim2.new(1, 10, 0.5, -28)

    TweenService:Create(fragmentNotif, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -380, 0.5, -28),
    }):Play()

    task.delay(3.5, function()
        if fragmentNotif then
            local t = TweenService:Create(fragmentNotif, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 10, 0.5, -28),
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
