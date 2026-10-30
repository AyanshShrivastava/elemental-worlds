--!strict
--[[
    Elemental Worlds: In-Game Gamepass & Robux Shop UI
    Features:
    - Two tabs: GAMEPASSES and SPIN BUNDLES
    - Card layout with perk description and price
    - Animated modal open/close
    - Purchase prompt integration (MarketplaceService)
    - Shows "COMING SOON" for unset IDs (guides you to Creator Hub)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local ShopUIController = {}

local shopGui: ScreenGui? = nil
local shopModal: Frame? = nil

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

-- Perk color by type
local PERK_COLORS = {
    DoubleExp     = Color3.fromRGB(46, 200, 110),
    DoubleCharges = Color3.fromRGB(80, 160, 255),
    LuckySpins    = Color3.fromRGB(255, 180, 0),
    VIPMaster     = Color3.fromRGB(255, 215, 0),
    SpeedBoost    = Color3.fromRGB(100, 230, 255),
}

function ShopUIController.Init()
    shopGui = Instance.new("ScreenGui")
    shopGui.Name = "ElementalWorlds_Shop"
    shopGui.ResetOnSpawn = false
    shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    shopGui.Parent = playerGui

    -- HUD Toggle Button
    local shopToggleBtn = Instance.new("TextButton")
    shopToggleBtn.Name = "ShopHUDButton"
    shopToggleBtn.Size = UDim2.new(0, 130, 0, 40)
    shopToggleBtn.Position = UDim2.new(0, 14, 0.59, 0)
    shopToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 28, 16)
    shopToggleBtn.Font = Enum.Font.GothamBlack
    shopToggleBtn.TextSize = 13
    shopToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    shopToggleBtn.Text = "ROBUX SHOP"
    shopToggleBtn.Parent = shopGui
    MakeRounded(shopToggleBtn, 10)
    MakeStroke(shopToggleBtn, Color3.fromRGB(255, 215, 0), 2)

    shopToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(shopToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(65, 46, 22) }):Play()
    end)
    shopToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(shopToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(40, 28, 16) }):Play()
    end)

    -- Shop Modal Window
    shopModal = Instance.new("Frame")
    shopModal.Name = "ShopModalWindow"
    shopModal.Size = UDim2.new(0, 580, 0, 500)
    shopModal.Position = UDim2.new(0.5, -290, 0.5, -250)
    shopModal.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
    shopModal.BackgroundTransparency = 0.04
    shopModal.Visible = false
    shopModal.ZIndex = 15
    shopModal.Parent = shopGui
    MakeRounded(shopModal, 16)
    MakeStroke(shopModal, Color3.fromRGB(255, 215, 0), 2.5)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
    titleBar.ZIndex = 16
    titleBar.Parent = shopModal
    MakeRounded(titleBar, 16)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL WORLDS SHOP"
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

    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 38)
    tabBar.Position = UDim2.new(0, 10, 0, 56)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 16
    tabBar.Parent = shopModal

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabBar

    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -20, 1, -110)
    contentArea.Position = UDim2.new(0, 10, 0, 100)
    contentArea.BackgroundColor3 = Color3.fromRGB(20, 17, 34)
    contentArea.ZIndex = 16
    contentArea.Parent = shopModal
    MakeRounded(contentArea, 10)

    -- ==================== TAB 1: GAMEPASSES ====================
    local passesTab = Instance.new("ScrollingFrame")
    passesTab.Size = UDim2.new(1, -16, 1, -16)
    passesTab.Position = UDim2.new(0, 8, 0, 8)
    passesTab.BackgroundTransparency = 1
    passesTab.ScrollBarThickness = 5
    passesTab.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    passesTab.Visible = true
    passesTab.ZIndex = 17
    passesTab.Parent = contentArea

    local passesLayout = Instance.new("UIListLayout")
    passesLayout.Padding = UDim.new(0, 8)
    passesLayout.Parent = passesTab

    -- Calculate canvas height
    local passCount = 0
    for _ in ShopConfig.GAMEPASSES do passCount += 1 end
    passesTab.CanvasSize = UDim2.new(0, 0, 0, passCount * 88)

    for passKey, pass in ShopConfig.GAMEPASSES do
        local perkColor = PERK_COLORS[pass.PerkType] or Color3.fromRGB(180, 180, 200)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(24, 22, 40)
        card.ZIndex = 18
        card.Parent = passesTab
        MakeRounded(card, 10)
        MakeStroke(card, Color3.fromRGB(50, 46, 75), 1.5)

        -- Left accent bar
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 5, 1, 0)
        accent.BackgroundColor3 = perkColor
        accent.ZIndex = 19
        accent.Parent = card
        MakeRounded(accent, 4)

        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(0, 260, 0, 24)
        nameL.Position = UDim2.new(0, 16, 0, 8)
        nameL.BackgroundTransparency = 1
        nameL.Font = Enum.Font.GothamBlack
        nameL.TextSize = 15
        nameL.TextColor3 = Color3.fromRGB(240, 238, 255)
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.Text = pass.Name
        nameL.ZIndex = 19
        nameL.Parent = card

        local descL = Instance.new("TextLabel")
        descL.Size = UDim2.new(0, 300, 0, 36)
        descL.Position = UDim2.new(0, 16, 0, 34)
        descL.BackgroundTransparency = 1
        descL.Font = Enum.Font.GothamMedium
        descL.TextSize = 11
        descL.TextColor3 = Color3.fromRGB(155, 153, 175)
        descL.TextXAlignment = Enum.TextXAlignment.Left
        descL.TextWrapped = true
        descL.Text = pass.Description
        descL.ZIndex = 19
        descL.Parent = card

        -- Perk Badge
        local perkBadge = Instance.new("TextLabel")
        perkBadge.Size = UDim2.new(0, 100, 0, 22)
        perkBadge.Position = UDim2.new(1, -210, 0, 12)
        perkBadge.BackgroundColor3 = perkColor
        perkBadge.BackgroundTransparency = 0.3
        perkBadge.Font = Enum.Font.GothamBold
        perkBadge.TextSize = 10
        perkBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        perkBadge.Text = pass.PerkDetail or pass.PerkType
        perkBadge.ZIndex = 19
        perkBadge.Parent = card
        MakeRounded(perkBadge, 6)

        -- Buy Button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 100, 0, 40)
        buyBtn.Position = UDim2.new(1, -112, 0.5, -20)
        buyBtn.BackgroundColor3 = perkColor
        buyBtn.Font = Enum.Font.GothamBlack
        buyBtn.TextSize = 14
        buyBtn.TextColor3 = Color3.fromRGB(15, 12, 25)
        buyBtn.Text = "R$ " .. tostring(pass.Price)
        buyBtn.ZIndex = 19
        buyBtn.Parent = card
        MakeRounded(buyBtn, 8)

        -- Hover animation
        buyBtn.MouseEnter:Connect(function()
            TweenService:Create(buyBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 106, 0, 44) }):Play()
        end)
        buyBtn.MouseLeave:Connect(function()
            TweenService:Create(buyBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 100, 0, 40) }):Play()
        end)

        local capturedPass = pass
        buyBtn.MouseButton1Click:Connect(function()
            SoundController.PlayUI("click")
            if capturedPass.Id and capturedPass.Id > 0 then
                MarketplaceService:PromptGamePassPurchase(localPlayer, capturedPass.Id)
            else
                -- ID not set yet — guide user
                print(string.format("[ShopUI] Pass '%s' not configured yet. Create it in Creator Hub > Monetization > Game Passes.", capturedPass.Name))
            end
        end)
    end

    -- ==================== TAB 2: SPIN BUNDLES ====================
    local bundlesTab = Instance.new("ScrollingFrame")
    bundlesTab.Size = UDim2.new(1, -16, 1, -16)
    bundlesTab.Position = UDim2.new(0, 8, 0, 8)
    bundlesTab.BackgroundTransparency = 1
    bundlesTab.ScrollBarThickness = 5
    bundlesTab.ScrollBarImageColor3 = Color3.fromRGB(80, 210, 255)
    bundlesTab.Visible = false
    bundlesTab.ZIndex = 17
    bundlesTab.Parent = contentArea

    local bundlesLayout = Instance.new("UIListLayout")
    bundlesLayout.Padding = UDim.new(0, 8)
    bundlesLayout.Parent = bundlesTab

    local productCount = 0
    for _ in ShopConfig.PRODUCTS do productCount += 1 end
    bundlesTab.CanvasSize = UDim2.new(0, 0, 0, productCount * 88)

    for _, product in ShopConfig.PRODUCTS do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
        card.ZIndex = 18
        card.Parent = bundlesTab
        MakeRounded(card, 10)
        MakeStroke(card, Color3.fromRGB(40, 100, 200), 1.5)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 5, 1, 0)
        accent.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
        accent.ZIndex = 19
        accent.Parent = card
        MakeRounded(accent, 4)

        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(0, 240, 0, 24)
        nameL.Position = UDim2.new(0, 16, 0, 8)
        nameL.BackgroundTransparency = 1
        nameL.Font = Enum.Font.GothamBlack
        nameL.TextSize = 15
        nameL.TextColor3 = Color3.fromRGB(80, 210, 255)
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.Text = product.Name
        nameL.ZIndex = 19
        nameL.Parent = card

        local descL = Instance.new("TextLabel")
        descL.Size = UDim2.new(0, 300, 0, 34)
        descL.Position = UDim2.new(0, 16, 0, 36)
        descL.BackgroundTransparency = 1
        descL.Font = Enum.Font.GothamMedium
        descL.TextSize = 11
        descL.TextColor3 = Color3.fromRGB(140, 155, 180)
        descL.TextXAlignment = Enum.TextXAlignment.Left
        descL.TextWrapped = true
        descL.Text = product.Description
        descL.ZIndex = 19
        descL.Parent = card

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 100, 0, 40)
        buyBtn.Position = UDim2.new(1, -112, 0.5, -20)
        buyBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
        buyBtn.Font = Enum.Font.GothamBlack
        buyBtn.TextSize = 14
        buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyBtn.Text = "R$ " .. tostring(product.Price)
        buyBtn.ZIndex = 19
        buyBtn.Parent = card
        MakeRounded(buyBtn, 8)

        buyBtn.MouseEnter:Connect(function()
            TweenService:Create(buyBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 106, 0, 44) }):Play()
        end)
        buyBtn.MouseLeave:Connect(function()
            TweenService:Create(buyBtn, TweenInfo.new(0.1), { Size = UDim2.new(0, 100, 0, 40) }):Play()
        end)

        local capturedProduct = product
        buyBtn.MouseButton1Click:Connect(function()
            SoundController.PlayUI("click")
            if capturedProduct.Id and capturedProduct.Id > 0 then
                MarketplaceService:PromptProductPurchase(localPlayer, capturedProduct.Id)
            else
                print(string.format("[ShopUI] Product '%s' not configured yet. Create it in Creator Hub > Monetization > Developer Products.", capturedProduct.Name))
            end
        end)
    end

    -- ==================== TAB BUTTONS ====================
    local tabs = {
        { name = "GAMEPASSES", content = passesTab },
        { name = "SPIN BUNDLES", content = bundlesTab },
    }

    for i, tab in tabs do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(0, 140, 1, 0)
        tb.BackgroundColor3 = (i == 1) and Color3.fromRGB(55, 42, 90) or Color3.fromRGB(24, 20, 42)
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 13
        tb.TextColor3 = Color3.fromRGB(220, 218, 240)
        tb.Text = tab.name
        tb.LayoutOrder = i
        tb.ZIndex = 17
        tb.Parent = tabBar
        MakeRounded(tb, 8)

        local capturedTb = tb
        local capturedContent = tab.content
        tb.MouseButton1Click:Connect(function()
            for _, tb2 in tabBar:GetChildren() do
                if tb2:IsA("TextButton") then
                    TweenService:Create(tb2, TweenInfo.new(0.12), {
                        BackgroundColor3 = Color3.fromRGB(24, 20, 42),
                    }):Play()
                end
            end
            TweenService:Create(capturedTb, TweenInfo.new(0.12), {
                BackgroundColor3 = Color3.fromRGB(55, 42, 90),
            }):Play()
            passesTab.Visible = (capturedContent == passesTab)
            bundlesTab.Visible = (capturedContent == bundlesTab)
        end)
    end

    -- Toggle modal
    local function ToggleShop()
        if not shopModal then return end
        if shopModal.Visible then
            TweenService:Create(shopModal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            }):Play()
            task.delay(0.2, function()
                if shopModal then shopModal.Visible = false end
            end)
        else
            shopModal.Visible = true
            shopModal.Size = UDim2.new(0, 0, 0, 0)
            shopModal.Position = UDim2.new(0.5, 0, 0.5, 0)
            TweenService:Create(shopModal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 580, 0, 500),
                Position = UDim2.new(0.5, -290, 0.5, -250),
            }):Play()
        end
    end

    shopToggleBtn.MouseButton1Click:Connect(ToggleShop)
    closeBtn.MouseButton1Click:Connect(ToggleShop)
end

return table.freeze(ShopUIController)
