--!strict
--[[
    ===========================================================================
    ELEMENTAL WORLDS — MASTER ANIME COMBAT VFX & HUD TEST HARNESS
    ===========================================================================
    Location: StarterPlayer.StarterPlayerScripts.TestElementalVFX
    Demonstrates and tests all 36 ability visual effects from ReplicatedStorage.ElementalVFX.

    FEATURES:
    - Responsive On-Screen Glassmorphic HUD with glowing element badges & clickable cards
    - Prominent Center-Screen Element Switch Notifications with elastic bounce & audio chime
    - Hotkey & Click support:
      [T] / Click Top Switcher: Cycle elements (Fire -> Aqua -> Earth -> Light -> Wind -> Error -> Time)
      [M] / [F] / Click Card: Cast M1
      [1] / Click Card: Cast Move 1
      [2] / Click Card: Cast Move 2
      [3] / Click Card: Cast Move 3
      [4] / Click Card: Cast Move 4
      [5] / Click Card: Cast Move 5 (Error only)
      [P] / Click Button: Run 36-Ability Automatic Showcase Demo
    - High-velocity camera shake on impact/cast
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local camera = workspace.CurrentCamera

-- Camera Shake Function (Requested Specification)
local function triggerCameraShake(duration: number, intensity: number)
    local startTime = tick()
    local connection
    
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed < duration then
            local decay = 1 - (elapsed / duration)
            local offsetX = math.random(-100, 100) * 0.001 * intensity * decay
            local offsetY = math.random(-100, 100) * 0.001 * intensity * decay
            camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
        else
            connection:Disconnect()
        end
    end)
end

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

local elementalVFXFolder = ReplicatedStorage:WaitForChild("ElementalVFX", 10)
if not elementalVFXFolder then
    warn("[TestElementalVFX] ReplicatedStorage.ElementalVFX not found!")
    return
end

local DispatcherMod = elementalVFXFolder:WaitForChild("Dispatcher", 5) :: ModuleScript?
if not DispatcherMod then
    warn("[TestElementalVFX] ReplicatedStorage.ElementalVFX.Dispatcher not found!")
    return
end

local VFX = require(DispatcherMod)

-- Ability Catalog & Color Palette for all 7 elements
local ABILITIES: { [string]: any } = {
    Fire = {
        Theme = Color3.fromRGB(255, 95, 25),
        Accent = Color3.fromRGB(255, 205, 70),
        M1 = { Name = "Flame Dagger", Key = "M", Move = "M1" },
        ["1"] = { Name = "Scorching Fireball", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Infernal Beast", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Flames of Fury", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Infernal Judgement", Key = "4", Move = "Move4" },
    },
    Aqua = {
        Theme = Color3.fromRGB(0, 195, 255),
        Accent = Color3.fromRGB(60, 240, 220),
        M1 = { Name = "Water Stream", Key = "M", Move = "M1" },
        ["1"] = { Name = "Water Hand", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Vortex of Destruction", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Water Dragon", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Limitless Punches", Key = "4", Move = "Move4" },
    },
    Earth = {
        Theme = Color3.fromRGB(180, 140, 85),
        Accent = Color3.fromRGB(225, 185, 130),
        M1 = { Name = "Earth Sword", Key = "M", Move = "M1" },
        ["1"] = { Name = "Earthy Wall", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Boulder of Destruction", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Accelerated Earth Punch", Key = "3", Move = "Move3" },
        ["4"] = { Name = "The Master of Terra", Key = "4", Move = "Move4" },
    },
    Light = {
        Theme = Color3.fromRGB(255, 240, 120),
        Accent = Color3.fromRGB(220, 185, 255),
        M1 = { Name = "Dim Light Ray", Key = "M", Move = "M1" },
        ["1"] = { Name = "Amplified Light", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Mirrors of Judgement", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Blinding Attack", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Divine Amplification", Key = "4", Move = "Move4" },
    },
    Wind = {
        Theme = Color3.fromRGB(60, 235, 170),
        Accent = Color3.fromRGB(180, 255, 225),
        M1 = { Name = "Compressed Wind", Key = "M", Move = "M1" },
        ["1"] = { Name = "Airy Vortex", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Cyclone of Fury", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Maximum Speed", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Wind: Death Speed", Key = "4", Move = "Move4" },
    },
    Error = {
        Theme = Color3.fromRGB(255, 25, 140),
        Accent = Color3.fromRGB(0, 255, 240),
        M1 = { Name = "Glitched Dash", Key = "M", Move = "M1" },
        ["1"] = { Name = "Chaotic Destruction", Key = "1", Move = "Move1" },
        ["2"] = { Name = "404 Not Found", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Got Glitched", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Spatial Distortion", Key = "4", Move = "Move4" },
        ["5"] = { Name = "Unparalleled", Key = "5", Move = "Move5" },
    },
    Time = {
        Theme = Color3.fromRGB(130, 95, 255),
        Accent = Color3.fromRGB(0, 240, 255),
        M1 = { Name = "Time Punch", Key = "M", Move = "M1" },
        ["1"] = { Name = "Got Throwed", Key = "1", Move = "Move1" },
        ["2"] = { Name = "Time Injection", Key = "2", Move = "Move2" },
        ["3"] = { Name = "Untouchable", Key = "3", Move = "Move3" },
        ["4"] = { Name = "Virtual Kill", Key = "4", Move = "Move4" },
    },
}

local ELEMENTS = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
local currentElementIndex = 1
local activeHandles = {}

local function PlayChime(pitch: number?)
    local s = Instance.new("Sound")
    s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    s.Volume = 0.55
    s.PlaybackSpeed = pitch or 1.1
    s.Parent = SoundService
    s:Play()
    s.Ended:Once(function() s:Destroy() end)
end

-- ==================== CREATE MASTER ON-SCREEN HUD ====================
local playerGui = player:WaitForChild("PlayerGui", 15) :: PlayerGui
local screenGui = playerGui:FindFirstChild("ElementalVFX_TesterHUD") :: ScreenGui?
if screenGui then
    screenGui:Destroy()
end

screenGui = Instance.new("ScreenGui")
screenGui.Name = "ElementalVFX_TesterHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

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

-- 1. TOP HEADER CONTROL CARD
local topBar = Instance.new("Frame")
topBar.Name = "TopControlCard"
topBar.Size = UDim2.new(0, 520, 0, 54)
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 14)
topBar.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
topBar.BackgroundTransparency = 0.15
topBar.Parent = screenGui
MakeCorner(topBar, 10)
local topStroke = MakeStroke(topBar, ABILITIES.Fire.Theme, 1.8)

-- Element Crest Badge & Button
local elemBtn = Instance.new("TextButton")
elemBtn.Name = "ElementSwitchButton"
elemBtn.Size = UDim2.new(0, 270, 0, 38)
elemBtn.Position = UDim2.new(0, 8, 0, 8)
elemBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
elemBtn.Text = ""
elemBtn.AutoButtonColor = false
elemBtn.Parent = topBar
MakeCorner(elemBtn, 8)
local elemBtnStroke = MakeStroke(elemBtn, ABILITIES.Fire.Theme, 1.4)

local elemTitle = Instance.new("TextLabel")
elemTitle.Name = "ElementTitle"
elemTitle.Size = UDim2.new(1, -12, 0, 20)
elemTitle.Position = UDim2.new(0, 8, 0, 2)
elemTitle.BackgroundTransparency = 1
elemTitle.Font = Enum.Font.GothamBlack
elemTitle.TextSize = 14
elemTitle.TextColor3 = ABILITIES.Fire.Theme
elemTitle.TextXAlignment = Enum.TextXAlignment.Left
elemTitle.Text = "ELEMENT: FIRE"
elemTitle.Parent = elemBtn

local elemSubtext = Instance.new("TextLabel")
elemSubtext.Name = "ElementSubtext"
elemSubtext.Size = UDim2.new(1, -12, 0, 14)
elemSubtext.Position = UDim2.new(0, 8, 0, 21)
elemSubtext.BackgroundTransparency = 1
elemSubtext.Font = Enum.Font.GothamBold
elemSubtext.TextSize = 10
elemSubtext.TextColor3 = Color3.fromRGB(160, 175, 200)
elemSubtext.TextXAlignment = Enum.TextXAlignment.Left
elemSubtext.Text = "Press [T] or Click to Cycle Elements"
elemSubtext.Parent = elemBtn

-- Showcase Button
local showcaseBtn = Instance.new("TextButton")
showcaseBtn.Name = "ShowcaseButton"
showcaseBtn.Size = UDim2.new(0, 226, 0, 38)
showcaseBtn.Position = UDim2.new(1, -234, 0, 8)
showcaseBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 52)
showcaseBtn.Font = Enum.Font.GothamBlack
showcaseBtn.TextSize = 11
showcaseBtn.TextColor3 = Color3.fromRGB(255, 225, 120)
showcaseBtn.Text = "⚡ 36-ABILITY SHOWCASE [P]"
showcaseBtn.AutoButtonColor = false
showcaseBtn.Parent = topBar
MakeCorner(showcaseBtn, 8)
local showcaseStroke = MakeStroke(showcaseBtn, Color3.fromRGB(255, 205, 50), 1.2)

-- 2. CENTER NOTIFICATION TOAST
local toastBanner = Instance.new("Frame")
toastBanner.Name = "ToastBanner"
toastBanner.Size = UDim2.new(0, 460, 0, 48)
toastBanner.AnchorPoint = Vector2.new(0.5, 0.5)
toastBanner.Position = UDim2.new(0.5, 0, 0.35, 0)
toastBanner.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
toastBanner.BackgroundTransparency = 1
toastBanner.Visible = false
toastBanner.Parent = screenGui
MakeCorner(toastBanner, 10)
local toastStroke = MakeStroke(toastBanner, ABILITIES.Fire.Theme, 2)
toastStroke.Transparency = 1

local toastText = Instance.new("TextLabel")
toastText.Name = "ToastText"
toastText.Size = UDim2.new(1, 0, 1, 0)
toastText.BackgroundTransparency = 1
toastText.Font = Enum.Font.GothamBlack
toastText.TextSize = 17
toastText.TextColor3 = ABILITIES.Fire.Theme
toastText.Text = "ELEMENT SWITCHED: FIRE"
toastText.TextTransparency = 1
toastText.Parent = toastBanner

local function ShowToast(text: string, color: Color3)
    toastText.Text = text
    toastText.TextColor3 = color
    toastStroke.Color = color
    toastBanner.Visible = true
    toastBanner.Size = UDim2.new(0, 420, 0, 44)

    TweenService:Create(toastBanner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.15,
        Size = UDim2.new(0, 460, 0, 48),
    }):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
    TweenService:Create(toastText, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.delay(1.5, function()
        TweenService:Create(toastBanner, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
        local t = TweenService:Create(toastText, TweenInfo.new(0.4), { TextTransparency = 1 })
        t:Play()
        t.Completed:Once(function()
            toastBanner.Visible = false
        end)
    end)
end

-- 3. BOTTOM ABILITY HOTBAR (6 Clickable Cards)
local hotbar = Instance.new("Frame")
hotbar.Name = "AbilityHotbar"
hotbar.Size = UDim2.new(0, 680, 0, 80)
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -16)
hotbar.BackgroundTransparency = 1
hotbar.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = hotbar

local slotCards: { [string]: {
    Card: TextButton,
    Stroke: UIStroke,
    NameLabel: TextLabel,
    KeyLabel: TextLabel,
    CooldownOverlay: Frame,
} } = {}

local slotKeys = { "M1", "1", "2", "3", "4", "5" }
local slotDefaultKeys = { M1 = "M", ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5" }

for _, slot in ipairs(slotKeys) do
    local cardBtn = Instance.new("TextButton")
    cardBtn.Name = "Slot_" .. slot
    cardBtn.Size = UDim2.new(0, 102, 0, 74)
    cardBtn.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
    cardBtn.BackgroundTransparency = 0.15
    cardBtn.Text = ""
    cardBtn.AutoButtonColor = false
    cardBtn.Parent = hotbar
    MakeCorner(cardBtn, 8)
    local stroke = MakeStroke(cardBtn, ABILITIES.Fire.Theme, 1.6)

    -- Key Badge
    local keyBadge = Instance.new("Frame")
    keyBadge.Name = "KeyBadge"
    keyBadge.Size = UDim2.new(0, 24, 0, 20)
    keyBadge.Position = UDim2.new(0, 6, 0, 6)
    keyBadge.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
    keyBadge.Parent = cardBtn
    MakeCorner(keyBadge, 4)

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(1, 0, 1, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Font = Enum.Font.GothamBlack
    keyLbl.TextSize = 11
    keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLbl.Text = slotDefaultKeys[slot]
    keyLbl.Parent = keyBadge

    -- Ability Name Label
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "AbilityName"
    nameLbl.Size = UDim2.new(1, -12, 0, 36)
    nameLbl.Position = UDim2.new(0, 6, 1, -40)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
    nameLbl.TextWrapped = true
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextYAlignment = Enum.TextYAlignment.Center
    nameLbl.Text = "Ability"
    nameLbl.Parent = cardBtn

    -- Cooldown Sweep Overlay
    local cdOverlay = Instance.new("Frame")
    cdOverlay.Name = "CooldownOverlay"
    cdOverlay.Size = UDim2.new(1, 0, 0, 0)
    cdOverlay.Position = UDim2.new(0, 0, 1, 0)
    cdOverlay.AnchorPoint = Vector2.new(0, 1)
    cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cdOverlay.BackgroundTransparency = 0.55
    cdOverlay.BorderSizePixel = 0
    cdOverlay.Parent = cardBtn
    MakeCorner(cdOverlay, 8)

    slotCards[slot] = {
        Card = cardBtn,
        Stroke = stroke,
        NameLabel = nameLbl,
        KeyLabel = keyLbl,
        CooldownOverlay = cdOverlay,
    }
end

-- Update HUD elements to match active element
local function RefreshHUD()
    local selectedElem = ELEMENTS[currentElementIndex]
    local config = ABILITIES[selectedElem]
    if not config then return end

    local color = config.Theme
    topStroke.Color = color
    elemBtnStroke.Color = color
    elemTitle.TextColor3 = color
    elemTitle.Text = string.format("ELEMENT: %s", string.upper(selectedElem))

    for _, slot in ipairs(slotKeys) do
        local cardInfo = slotCards[slot]
        local abilityData = config[slot]
        if abilityData then
            cardInfo.Card.Visible = true
            cardInfo.NameLabel.Text = abilityData.Name
            cardInfo.Stroke.Color = color
            cardInfo.KeyLabel.TextColor3 = config.Accent or Color3.fromRGB(255, 255, 255)
        else
            cardInfo.Card.Visible = false
        end
    end
end

-- Trigger Cooldown Visual on Card
local function AnimateCardCooldown(slot: string, duration: number)
    local cardInfo = slotCards[slot]
    if not cardInfo then return end

    -- Elastic Click Pop
    cardInfo.Card.Size = UDim2.new(0, 94, 0, 68)
    TweenService:Create(cardInfo.Card, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 102, 0, 74),
    }):Play()

    -- Cooldown wipe
    local overlay = cardInfo.CooldownOverlay
    overlay.Size = UDim2.new(1, 0, 1, 0)
    TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 0, 0),
    }):Play()
end

local function GetContext()
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return nil end
    local targetPos = root.Position + root.CFrame.LookVector * 90
    return {
        character = character,
        target = targetPos,
        origin = root.Position,
        direction = root.CFrame.LookVector,
        duration = 5,
        radius = 18,
    }
end

local function PlayMove(element: string, move: string, slotKey: string?)
    local ctx = GetContext()
    if not ctx then return end

    local config = ABILITIES[element]
    local moveTitle = (config and slotKey and config[slotKey] and config[slotKey].Name) or move
    print(string.format("[VFX Test] Casting %s %s (%s)...", element, move, moveTitle))

    local handle = VFX.Play(element, move, ctx)

    -- Visceral Camera Shake
    triggerCameraShake(0.15, 1.5)

    -- Hotbar visual feedback
    if slotKey then
        AnimateCardCooldown(slotKey, slotKey == "M1" and 0.8 or 3.0)
    end

    if handle then
        table.insert(activeHandles, { element = element, move = move, handle = handle })

        task.delay(2.2, function()
            if handle.Hit then pcall(function() handle:Hit() end) end
            if handle.SetHealth then pcall(function() handle:SetHealth(0.4) end) end
            if handle.Attack then pcall(function() handle:Attack(ctx.target) end) end
        end)

        task.delay(4.2, function()
            if handle.Shatter then
                pcall(function() handle:Shatter() end)
            elseif handle.End then
                pcall(function() handle:End(ctx.target) end)
            elseif handle.Despawn then
                pcall(function() handle:Despawn() end)
            end
        end)
    end
end

local function CycleElement()
    currentElementIndex = (currentElementIndex % #ELEMENTS) + 1
    local selected = ELEMENTS[currentElementIndex]
    local config = ABILITIES[selected]
    RefreshHUD()
    PlayChime(1.2)
    ShowToast(string.format("🔥 ELEMENT SWITCHED TO: %s 🔥", string.upper(selected)), config.Theme)
    print(string.format("[VFX Test] Element cycled to: %s. Use M / 1 / 2 / 3 / 4 / 5 or click abilities below!", selected))
end

-- Automatic Showcase
local isShowcaseRunning = false
local function RunShowcase()
    if isShowcaseRunning then return end
    isShowcaseRunning = true
    PlayChime(1.4)
    ShowToast("⚡ STARTING 36-ABILITY SHOWCASE ⚡", Color3.fromRGB(255, 215, 60))
    print("==================================================")
    print("STARTING COMPLETE 36-ABILITY VFX SHOWCASE DEMO...")
    print("==================================================")

    task.spawn(function()
        for idx, elem in ipairs(ELEMENTS) do
            currentElementIndex = idx
            RefreshHUD()
            ShowToast(string.format("SHOWCASE: %s ELEMENT", string.upper(elem)), ABILITIES[elem].Theme)

            local moves = {
                { move = "M1", slot = "M1" },
                { move = "Move1", slot = "1" },
                { move = "Move2", slot = "2" },
                { move = "Move3", slot = "3" },
                { move = "Move4", slot = "4" },
            }
            if elem == "Error" then
                table.insert(moves, { move = "Move5", slot = "5" })
            end

            for _, mInfo in ipairs(moves) do
                PlayMove(elem, mInfo.move, mInfo.slot)
                task.wait(1.5)
            end
            task.wait(0.8)
        end
        ShowToast("⭐ SHOWCASE COMPLETED (36/36) ⭐", Color3.fromRGB(50, 255, 150))
        print("==================================================")
        print("VFX SHOWCASE DEMO COMPLETED!")
        print("==================================================")
        isShowcaseRunning = false
    end)
end

-- ==================== BIND CLICK EVENTS ====================
elemBtn.MouseButton1Click:Connect(function()
    CycleElement()
end)

showcaseBtn.MouseButton1Click:Connect(function()
    RunShowcase()
end)

for slot, info in pairs(slotCards) do
    info.Card.MouseButton1Click:Connect(function()
        local elem = ELEMENTS[currentElementIndex]
        local config = ABILITIES[elem]
        if config and config[slot] then
            PlayMove(elem, config[slot].Move, slot)
        end
    end)
end

-- ==================== BIND KEYBOARD EVENTS ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.T then
        CycleElement()

    elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.F then
        local elem = ELEMENTS[currentElementIndex]
        PlayMove(elem, "M1", "M1")

    elseif input.KeyCode == Enum.KeyCode.One then
        local elem = ELEMENTS[currentElementIndex]
        PlayMove(elem, "Move1", "1")

    elseif input.KeyCode == Enum.KeyCode.Two then
        local elem = ELEMENTS[currentElementIndex]
        PlayMove(elem, "Move2", "2")

    elseif input.KeyCode == Enum.KeyCode.Three then
        local elem = ELEMENTS[currentElementIndex]
        PlayMove(elem, "Move3", "3")

    elseif input.KeyCode == Enum.KeyCode.Four then
        local elem = ELEMENTS[currentElementIndex]
        PlayMove(elem, "Move4", "4")

    elseif input.KeyCode == Enum.KeyCode.Five then
        if ELEMENTS[currentElementIndex] == "Error" then
            PlayMove("Error", "Move5", "5")
        end

    elseif input.KeyCode == Enum.KeyCode.P then
        RunShowcase()
    end
end)

-- Initialize HUD immediately
RefreshHUD()
ShowToast("🔥 ELEMENTAL WORLDS VFX ACTIVE [T TO CYCLE] 🔥", ABILITIES.Fire.Theme)
print("[Elemental Worlds VFX] Master Test Harness Ready! Press 'T' or Click Top Button to Switch Elements.")
