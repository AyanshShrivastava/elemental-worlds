--!strict
--[[
    Elemental Worlds: In-Game Gamepass & Robux Shop UI (Blox Fruits Modern Design)
    Features:
    - Blox Fruits style categorized shop: GAMEPASSES & SPIN BUNDLES
    - Sleek dark obsidian cards with electric indigo/cyan accents
    - Integrated purchase prompting via MarketplaceService
    - Hover highlights, animated transitions, clean typography
    - NO gold or rainbow styling
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local SharedLoader = require(script.Parent.Parent.SharedLoader)
local ShopConfig = SharedLoader.ShopConfig
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer

local function GetPlayerGui(): PlayerGui?
    if not localPlayer then
        localPlayer = Players.LocalPlayer
    end
    if not localPlayer then return nil end
    return (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)) :: PlayerGui?
end

local ShopUIController = {}

local shopGui: ScreenGui? = nil
local shopModal: Frame? = nil
local activeTab = "GamePasses"
local scrollContainer: ScrollingFrame? = nil

-- Modern Blox Fruits Style Color Tokens
local PALETTE = {
    BG_MAIN         = Color3.fromRGB(12, 16, 26),
    BG_CARD         = Color3.fromRGB(18, 24, 38),
    BG_CARD_HOVER   = Color3.fromRGB(26, 34, 54),
    BORDER_DEFAULT  = Color3.fromRGB(42, 52, 75),
    BORDER_ACCENT   = Color3.fromRGB(115, 90, 245),
    BTN_PRIMARY     = Color3.fromRGB(115, 90, 245),
    BTN_HOVER       = Color3.fromRGB(135, 110, 255),
    TEXT_PRIMARY    = Color3.fromRGB(245, 248, 255),
    TEXT_MUTED      = Color3.fromRGB(135, 145, 170),
    PRICE_TAG       = Color3.fromRGB(80, 215, 255),
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

-- Renders item cards into the scroll container
local function PopulateCards()
    if not scrollContainer then return end

    for _, child in scrollContainer:GetChildren() do
        if child:IsA("Frame") then child:Destroy() end
    end

    if activeTab == "GamePasses" then
        local passes = {
            ShopConfig.GAMEPASSES.DoubleExp,
            ShopConfig.GAMEPASSES.DoubleCharges,
            ShopConfig.GAMEPASSES.LuckySpins,
            ShopConfig.GAMEPASSES.VIPMaster,
            ShopConfig.GAMEPASSES.SpeedBoost,
        }

        scrollContainer.CanvasSize = UDim2.new(0, 0, 0, #passes * 88)

        for _, pass in passes do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -10, 0, 80)
            card.BackgroundColor3 = PALETTE.BG_CARD
            card.Parent = scrollContainer
            MakeRounded(card, 8)
            local stroke = MakeStroke(card, PALETTE.BORDER_DEFAULT, 1.2)

            -- Left accent bar
            local accentBar = Instance.new("Frame")
            accentBar.Size = UDim2.new(0, 4, 1, 0)
            accentBar.BackgroundColor3 = PALETTE.BORDER_ACCENT
            accentBar.BorderSizePixel = 0
            accentBar.Parent = card
            MakeRounded(accentBar, 4)

            -- Pass Name
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -150, 0, 24)
            nameLbl.Position = UDim2.new(0, 16, 0, 10)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBlack
            nameLbl.TextSize = 14
            nameLbl.TextColor3 = PALETTE.TEXT_PRIMARY
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = pass.Name
            nameLbl.Parent = card

            -- Description
            local descLbl = Instance.new("TextLabel")
            descLbl.Size = UDim2.new(1, -150, 0, 36)
            descLbl.Position = UDim2.new(0, 16, 0, 34)
            descLbl.BackgroundTransparency = 1
            descLbl.Font = Enum.Font.GothamMedium
            descLbl.TextSize = 11
            descLbl.TextColor3 = PALETTE.TEXT_MUTED
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.TextWrapped = true
            descLbl.Text = pass.Description
            descLbl.Parent = card

            -- Buy Button
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0, 115, 0, 36)
            buyBtn.Position = UDim2.new(1, -125, 0.5, -18)
            buyBtn.BackgroundColor3 = PALETTE.BTN_PRIMARY
            buyBtn.Font = Enum.Font.GothamBlack
            buyBtn.TextSize = 12
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Text = "R$ " .. tostring(pass.Price)
            buyBtn.AutoButtonColor = false
            buyBtn.Parent = card
            MakeRounded(buyBtn, 6)

            buyBtn.MouseEnter:Connect(function()
                TweenService:Create(buyBtn, TweenInfo.new(0.12), { BackgroundColor3 = PALETTE.BTN_HOVER }):Play()
            end)
            buyBtn.MouseLeave:Connect(function()
                TweenService:Create(buyBtn, TweenInfo.new(0.12), { BackgroundColor3 = PALETTE.BTN_PRIMARY }):Play()
            end)
            buyBtn.MouseButton1Click:Connect(function()
                if pass.Id and pass.Id > 0 then
                    MarketplaceService:PromptGamePassPurchase(localPlayer, pass.Id)
                else
                    SoundController.PlayUI("hover")
                end
            end)

            card.MouseEnter:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = PALETTE.BG_CARD_HOVER }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.12), { Color = PALETTE.BORDER_ACCENT }):Play()
            end)
            card.MouseLeave:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = PALETTE.BG_CARD }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.12), { Color = PALETTE.BORDER_DEFAULT }):Play()
            end)
        end
    else
        -- Spin Bundles
        local products = {
            ShopConfig.PRODUCTS.Spins_1,
            ShopConfig.PRODUCTS.Spins_5,
            ShopConfig.PRODUCTS.Spins_10,
        }

        scrollContainer.CanvasSize = UDim2.new(0, 0, 0, #products * 88)

        for _, prod in products do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -10, 0, 80)
            card.BackgroundColor3 = PALETTE.BG_CARD
            card.Parent = scrollContainer
            MakeRounded(card, 8)
            local stroke = MakeStroke(card, PALETTE.BORDER_DEFAULT, 1.2)

            local accentBar = Instance.new("Frame")
            accentBar.Size = UDim2.new(0, 4, 1, 0)
            accentBar.BackgroundColor3 = PALETTE.PRICE_TAG
            accentBar.BorderSizePixel = 0
            accentBar.Parent = card
            MakeRounded(accentBar, 4)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -150, 0, 24)
            nameLbl.Position = UDim2.new(0, 16, 0, 10)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBlack
            nameLbl.TextSize = 14
            nameLbl.TextColor3 = PALETTE.TEXT_PRIMARY
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = prod.Name
            nameLbl.Parent = card

            local descLbl = Instance.new("TextLabel")
            descLbl.Size = UDim2.new(1, -150, 0, 36)
            descLbl.Position = UDim2.new(0, 16, 0, 34)
            descLbl.BackgroundTransparency = 1
            descLbl.Font = Enum.Font.GothamMedium
            descLbl.TextSize = 11
            descLbl.TextColor3 = PALETTE.TEXT_MUTED
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.TextWrapped = true
            descLbl.Text = prod.Description
            descLbl.Parent = card

            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0, 115, 0, 36)
            buyBtn.Position = UDim2.new(1, -125, 0.5, -18)
            buyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 245)
            buyBtn.Font = Enum.Font.GothamBlack
            buyBtn.TextSize = 12
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Text = "R$ " .. tostring(prod.Price)
            buyBtn.AutoButtonColor = false
            buyBtn.Parent = card
            MakeRounded(buyBtn, 6)

            buyBtn.MouseButton1Click:Connect(function()
                if prod.Id and prod.Id > 0 then
                    MarketplaceService:PromptProductPurchase(localPlayer, prod.Id)
                else
                    SoundController.PlayUI("hover")
                end
            end)
        end
    end
end

function ShopUIController.Init()
    local playerGui = GetPlayerGui()
    if not playerGui then return end

    shopGui = Instance.new("ScreenGui")
    shopGui.Name = "ElementalWorlds_Shop"
    shopGui.ResetOnSpawn = false
    shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    shopGui.Parent = playerGui

    -- HUD Toggle Button
    local shopToggleBtn = Instance.new("TextButton")
    shopToggleBtn.Name = "ShopHUDButton"
    shopToggleBtn.Size = UDim2.new(0, 130, 0, 38)
    shopToggleBtn.Position = UDim2.new(0, 20, 0.53, 0)
    shopToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
    shopToggleBtn.Font = Enum.Font.GothamBlack
    shopToggleBtn.TextSize = 12
    shopToggleBtn.TextColor3 = PALETTE.PRICE_TAG
    shopToggleBtn.Text = "ROBUX SHOP"
    shopToggleBtn.AutoButtonColor = false
    shopToggleBtn.Parent = shopGui
    MakeRounded(shopToggleBtn, 8)
    MakeStroke(shopToggleBtn, PALETTE.PRICE_TAG, 1.8)

    shopToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(shopToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 30, 48) }):Play()
        SoundController.PlayUI("hover")
    end)
    shopToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(shopToggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(15, 20, 32) }):Play()
    end)

    -- Shop Modal Window
    shopModal = Instance.new("Frame")
    shopModal.Name = "ShopModalWindow"
    shopModal.Size = UDim2.new(0, 580, 0, 480)
    shopModal.Position = UDim2.new(0.5, -290, 0.5, -240)
    shopModal.BackgroundColor3 = PALETTE.BG_MAIN
    shopModal.BackgroundTransparency = 0.05
    shopModal.Visible = false
    shopModal.ZIndex = 25
    shopModal.Parent = shopGui
    MakeRounded(shopModal, 12)
    MakeStroke(shopModal, PALETTE.BORDER_ACCENT, 2.0)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    titleBar.ZIndex = 26
    titleBar.Parent = shopModal
    MakeRounded(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL SHOP"
    titleLabel.ZIndex = 27
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.ZIndex = 27
    closeBtn.Parent = titleBar
    MakeRounded(closeBtn, 6)

    -- Tab Bar (Blox Fruits Style Clean Navigation)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -36, 0, 36)
    tabBar.Position = UDim2.new(0, 18, 0, 56)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 26
    tabBar.Parent = shopModal

    local tabPasses = Instance.new("TextButton")
    tabPasses.Size = UDim2.new(0.5, -4, 1, 0)
    tabPasses.BackgroundColor3 = PALETTE.BORDER_ACCENT
    tabPasses.Font = Enum.Font.GothamBlack
    tabPasses.TextSize = 12
    tabPasses.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabPasses.Text = "GAMEPASSES"
    tabPasses.ZIndex = 27
    tabPasses.Parent = tabBar
    MakeRounded(tabPasses, 6)

    local tabSpins = Instance.new("TextButton")
    tabSpins.Size = UDim2.new(0.5, -4, 1, 0)
    tabSpins.Position = UDim2.new(0.5, 4, 0, 0)
    tabSpins.BackgroundColor3 = PALETTE.BG_CARD
    tabSpins.Font = Enum.Font.GothamBlack
    tabSpins.TextSize = 12
    tabSpins.TextColor3 = PALETTE.TEXT_MUTED
    tabSpins.Text = "SPIN BUNDLES"
    tabSpins.ZIndex = 27
    tabSpins.Parent = tabBar
    MakeRounded(tabSpins, 6)

    -- Scroll Area
    scrollContainer = Instance.new("ScrollingFrame")
    scrollContainer.Size = UDim2.new(1, -36, 1, -110)
    scrollContainer.Position = UDim2.new(0, 18, 0, 98)
    scrollContainer.BackgroundTransparency = 1
    scrollContainer.ScrollBarThickness = 5
    scrollContainer.ScrollBarImageColor3 = PALETTE.BORDER_ACCENT
    scrollContainer.ZIndex = 26
    scrollContainer.Parent = shopModal

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.Padding = UDim.new(0, 8)
    scrollLayout.Parent = scrollContainer

    local function SwitchTab(tabName: string)
        activeTab = tabName
        if activeTab == "GamePasses" then
            tabPasses.BackgroundColor3 = PALETTE.BORDER_ACCENT
            tabPasses.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabSpins.BackgroundColor3 = PALETTE.BG_CARD
            tabSpins.TextColor3 = PALETTE.TEXT_MUTED
        else
            tabSpins.BackgroundColor3 = PALETTE.BORDER_ACCENT
            tabSpins.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabPasses.BackgroundColor3 = PALETTE.BG_CARD
            tabPasses.TextColor3 = PALETTE.TEXT_MUTED
        end
        PopulateCards()
    end

    tabPasses.MouseButton1Click:Connect(function() SwitchTab("GamePasses") end)
    tabSpins.MouseButton1Click:Connect(function() SwitchTab("Spins") end)

    local function ToggleShop()
        shopModal.Visible = not shopModal.Visible
        if shopModal.Visible then
            SoundController.PlayUI("open")
            PopulateCards()
            shopModal.Position = UDim2.new(0.5, -290, 0.5, -220)
            TweenService:Create(shopModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -290, 0.5, -240),
            }):Play()
        else
            SoundController.PlayUI("close")
        end
    end

    shopToggleBtn.MouseButton1Click:Connect(ToggleShop)
    closeBtn.MouseButton1Click:Connect(ToggleShop)
end

return table.freeze(ShopUIController)
