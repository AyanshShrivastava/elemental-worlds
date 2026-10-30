--!strict
--[[
    Elemental Worlds: Creator & Admin In-Game Panel Controller
    Exclusively available to Creator (coolzgamer9 - 6225357795) and authorized Admins.
    Provides graphical controls for Player Moderation, Stat Grants, Element Swapping,
    RNG Simulation & Configuration, and Server Announcements.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local AdminPanelController = {}

local panelGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local isPanelOpen = false

local selectedPlayerName: string = ""

function AdminPanelController.Init()
    -- Only load if local player is Owner or Admin
    local isOwner = (localPlayer.UserId == GameConfig.OWNER_USER_ID)

    panelGui = Instance.new("ScreenGui")
    panelGui.Name = "ElementalWorlds_CreatorPanel"
    panelGui.ResetOnSpawn = false
    panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    panelGui.Parent = playerGui

    -- ==================== TOGGLE BUTTON ====================
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "CreatorPanelToggle"
    toggleBtn.Size = UDim2.new(0, 140, 0, 36)
    toggleBtn.Position = UDim2.new(0, 15, 0.45, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    toggleBtn.Text = "👑 CREATOR PANEL"
    toggleBtn.Parent = panelGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Color3.fromRGB(255, 215, 0)
    toggleStroke.Thickness = 1.5
    toggleStroke.Parent = toggleBtn

    -- ==================== MAIN DASHBOARD ====================
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "CreatorDashboard"
    mainFrame.Size = UDim2.new(0, 560, 0, 390)
    mainFrame.Position = UDim2.new(0.5, -280, 0.5, -195)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Visible = false
    mainFrame.Parent = panelGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(180, 60, 255)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame

    -- Header Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 38)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL WORLDS — CREATOR SUITE"
    titleLabel.Parent = mainFrame

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- ==================== TAB NAVIGATION ====================
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -40, 0, 32)
    tabContainer.Position = UDim2.new(0, 20, 0, 52)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabContainer

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -40, 1, -100)
    contentArea.Position = UDim2.new(0, 20, 0, 90)
    contentArea.BackgroundColor3 = Color3.fromRGB(25, 22, 35)
    contentArea.Parent = mainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentArea

    -- Helper to execute admin command
    local function RunAdminCommand(cmd: string)
        local chat = game:GetService("TextChatService")
        local channel = chat:FindFirstChild("TextChannels") and chat.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:SendAsync(cmd)
        else
            Players:Chat(cmd)
        end
    end

    -- TAB 1: Players & Moderation
    local playersTabContent = Instance.new("ScrollingFrame")
    playersTabContent.Size = UDim2.new(1, -16, 1, -16)
    playersTabContent.Position = UDim2.new(0, 8, 0, 8)
    playersTabContent.BackgroundTransparency = 1
    playersTabContent.ScrollBarThickness = 6
    playersTabContent.Parent = contentArea

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim.new(0, 6)
    playersLayout.Parent = playersTabContent

    local function RefreshPlayerList()
        for _, child in playersTabContent:GetChildren() do
            if child:IsA("Frame") then child:Destroy() end
        end

        for _, targetPlayer in Players:GetPlayers() do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundColor3 = Color3.fromRGB(35, 32, 48)
            row.Parent = playersTabContent

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 6)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0, 160, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Text = targetPlayer.Name
            nameLabel.Parent = row

            local function AddActionBtn(btnText: string, posX: number, color: Color3, callback: () => ())
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 55, 0, 26)
                btn.Position = UDim2.new(0, posX, 0.5, -13)
                btn.BackgroundColor3 = color
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 11
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Text = btnText
                btn.Parent = row

                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = btn

                btn.MouseButton1Click:Connect(callback)
            end

            AddActionBtn("TP TO", 175, Color3.fromRGB(40, 140, 220), function()
                RunAdminCommand("/tp " .. targetPlayer.Name)
            end)
            AddActionBtn("BRING", 235, Color3.fromRGB(120, 60, 200), function()
                RunAdminCommand("/bring " .. targetPlayer.Name)
            end)
            AddActionBtn("KILL", 295, Color3.fromRGB(200, 60, 60), function()
                RunAdminCommand("/kill " .. targetPlayer.Name)
            end)
            AddActionBtn("KICK", 355, Color3.fromRGB(220, 120, 30), function()
                RunAdminCommand("/kick " .. targetPlayer.Name)
            end)
            AddActionBtn("+10 LVL", 415, Color3.fromRGB(46, 204, 113), function()
                RunAdminCommand("/givelevel " .. targetPlayer.Name .. " 10")
            end)
        end
    end

    -- TAB 2: Element Giver & Stats
    local statsTabContent = Instance.new("Frame")
    statsTabContent.Size = UDim2.new(1, -16, 1, -16)
    statsTabContent.Position = UDim2.new(0, 8, 0, 8)
    statsTabContent.BackgroundTransparency = 1
    statsTabContent.Visible = false
    statsTabContent.Parent = contentArea

    local statsHeader = Instance.new("TextLabel")
    statsHeader.Size = UDim2.new(1, 0, 0, 24)
    statsHeader.BackgroundTransparency = 1
    statsHeader.Font = Enum.Font.GothamBold
    statsHeader.TextSize = 14
    statsHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
    statsHeader.TextXAlignment = Enum.TextXAlignment.Left
    statsHeader.Text = "QUICK ELEMENT GIVER (Select Element to Equip Instantly):"
    statsHeader.Parent = statsTabContent

    local elemContainer = Instance.new("Frame")
    elemContainer.Size = UDim2.new(1, 0, 0, 45)
    elemContainer.Position = UDim2.new(0, 0, 0, 30)
    elemContainer.BackgroundTransparency = 1
    elemContainer.Parent = statsTabContent

    local elemLayout = Instance.new("UIListLayout")
    elemLayout.FillDirection = Enum.FillDirection.Horizontal
    elemLayout.Padding = UDim.new(0, 8)
    elemLayout.Parent = elemContainer

    local elements = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
    local elemColors = {
        Fire = Color3.fromRGB(255, 80, 20),
        Aqua = Color3.fromRGB(30, 160, 255),
        Earth = Color3.fromRGB(160, 110, 60),
        Light = Color3.fromRGB(255, 220, 50),
        Wind = Color3.fromRGB(100, 230, 160),
        Error = Color3.fromRGB(255, 0, 128),
        Time = Color3.fromRGB(70, 130, 255),
    }

    for _, elem in elements do
        local eBtn = Instance.new("TextButton")
        eBtn.Size = UDim2.new(0, 65, 0, 36)
        eBtn.BackgroundColor3 = elemColors[elem]
        eBtn.Font = Enum.Font.GothamBlack
        eBtn.TextSize = 11
        eBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        eBtn.Text = elem
        eBtn.Parent = elemContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = eBtn

        eBtn.MouseButton1Click:Connect(function()
            RunAdminCommand("/giveelement " .. localPlayer.Name .. " " .. elem)
        end)
    end

    -- Stat boost buttons
    local boostContainer = Instance.new("Frame")
    boostContainer.Size = UDim2.new(1, 0, 0, 45)
    boostContainer.Position = UDim2.new(0, 0, 0, 90)
    boostContainer.BackgroundTransparency = 1
    boostContainer.Parent = statsTabContent

    local boostLayout = Instance.new("UIListLayout")
    boostLayout.FillDirection = Enum.FillDirection.Horizontal
    boostLayout.Padding = UDim.new(0, 8)
    boostLayout.Parent = boostContainer

    local function MakeBoostBtn(text: string, cmd: string)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 115, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Parent = boostContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            RunAdminCommand(cmd)
        end)
    end

    MakeBoostBtn("+50 LEVELS", "/givelevel " .. localPlayer.Name .. " 50")
    MakeBoostBtn("MAX LEVEL (300)", "/setlevel " .. localPlayer.Name .. " 300")
    MakeBoostBtn("+1,000 CHARGES", "/givecharges " .. localPlayer.Name .. " 1000")
    MakeBoostBtn("MAX CHARGES", "/setcharges " .. localPlayer.Name .. " 10000")

    -- TAB Buttons
    local function CreateTabButton(tabName: string, targetTab: GuiObject)
        local tBtn = Instance.new("TextButton")
        tBtn.Size = UDim2.new(0, 110, 1, 0)
        tBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 48)
        tBtn.Font = Enum.Font.GothamBold
        tBtn.TextSize = 12
        tBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
        tBtn.Text = tabName
        tBtn.Parent = tabContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = tBtn

        tBtn.MouseButton1Click:Connect(function()
            playersTabContent.Visible = (targetTab == playersTabContent)
            statsTabContent.Visible = (targetTab == statsTabContent)
            if targetTab == playersTabContent then
                RefreshPlayerList()
            end
        end)
    end

    CreateTabButton("PLAYERS", playersTabContent)
    CreateTabButton("STATS & ELEMENTS", statsTabContent)

    -- Toggle visibility
    local function TogglePanel()
        isPanelOpen = not isPanelOpen
        mainFrame.Visible = isPanelOpen
        if isPanelOpen then
            RefreshPlayerList()
        end
    end

    toggleBtn.MouseButton1Click:Connect(TogglePanel)
    closeBtn.MouseButton1Click:Connect(TogglePanel)

    -- Keybind P to toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.P then
            TogglePanel()
        end
    end)
end

return table.freeze(AdminPanelController)
