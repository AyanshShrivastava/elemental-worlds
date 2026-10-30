--!strict
--[[
    Elemental Worlds: In-Game Gamepass & Robux Shop UI
    Allows players to browse and purchase 2x EXP, 2x Charges, Lucky Spins, VIP, and Spin Bundles.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local ShopUIController = {}

local shopGui: ScreenGui? = nil
local shopModal: Frame? = nil

function ShopUIController.Init()
    shopGui = Instance.new("ScreenGui")
    shopGui.Name = "ElementalWorlds_Shop"
    shopGui.ResetOnSpawn = false
    shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    shopGui.Parent = playerGui

    -- Floating Shop Button on HUD
    local shopToggleBtn = Instance.new("TextButton")
    shopToggleBtn.Name = "ShopHUDButton"
    shopToggleBtn.Size = UDim2.new(0, 100, 0, 36)
    shopToggleBtn.Position = UDim2.new(0, 15, 0.59, 0)
    shopToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 20)
    shopToggleBtn.Font = Enum.Font.GothamBlack
    shopToggleBtn.TextSize = 13
    shopToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    shopToggleBtn.Text = "🛒 SHOP"
    shopToggleBtn.Parent = shopGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = shopToggleBtn

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Color3.fromRGB(255, 215, 0)
    toggleStroke.Thickness = 1.5
    toggleStroke.Parent = shopToggleBtn

    -- Shop Modal Window
    shopModal = Instance.new("Frame")
    shopModal.Name = "ShopModalWindow"
    shopModal.Size = UDim2.new(0, 520, 0, 380)
    shopModal.Position = UDim2.new(0.5, -260, 0.5, -190)
    shopModal.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    shopModal.Visible = false
    shopModal.Parent = shopGui

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 12)
    modalCorner.Parent = shopModal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(255, 215, 0)
    modalStroke.Thickness = 2
    modalStroke.Parent = shopModal

    -- Header
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 36)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "GAMEPASSES & BUNDLES"
    titleLabel.Parent = shopModal

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0, 12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Parent = shopModal

    local cClose = Instance.new("UICorner")
    cClose.CornerRadius = UDim.new(0, 6)
    cClose.Parent = closeBtn

    -- Scrolling Items List
    local scrollList = Instance.new("ScrollingFrame")
    scrollList.Size = UDim2.new(1, -30, 1, -70)
    scrollList.Position = UDim2.new(0, 15, 0, 55)
    scrollList.BackgroundTransparency = 1
    scrollList.ScrollBarThickness = 6
    scrollList.Parent = shopModal

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = scrollList

    -- Render Gamepasses
    for passKey, pass in ShopConfig.GAMEPASSES do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 62)
        card.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        card.Parent = scrollList

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 240, 0, 22)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = pass.Name
        nameLabel.Parent = card

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0, 300, 0, 24)
        descLabel.Position = UDim2.new(0, 12, 0, 30)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.GothamMedium
        descLabel.TextSize = 10
        descLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Text = pass.Description
        descLabel.Parent = card

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 100, 0, 36)
        buyBtn.Position = UDim2.new(1, -112, 0.5, -18)
        buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        buyBtn.Font = Enum.Font.GothamBlack
        buyBtn.TextSize = 12
        buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyBtn.Text = "R$ " .. tostring(pass.Price)
        buyBtn.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = buyBtn

        buyBtn.MouseButton1Click:Connect(function()
            SoundController.PlaySound2D("MagicCast", 0.5)
            if pass.Id and pass.Id > 0 then
                MarketplaceService:PromptGamePassPurchase(localPlayer, pass.Id)
            else
                print("[ShopUI] Prompted test purchase for: " .. pass.Name)
            end
        end)
    end

    shopToggleBtn.MouseButton1Click:Connect(function()
        shopModal.Visible = not shopModal.Visible
    end)
    closeBtn.MouseButton1Click:Connect(function()
        shopModal.Visible = false
    end)
end

return table.freeze(ShopUIController)
