--!strict
--[[
    Elemental Worlds: Creator & Admin In-Game Suite (Blox Fruits Modern Design)
    Exclusively available to Creator (coolzgamer9 - 6225357795) and authorized Admins.
    
    Aesthetic rules:
    - NO yellow or gold
    - Deep obsidian-navy cards (Color3.fromRGB(12, 16, 26))
    - Electric indigo / violet accents (Color3.fromRGB(115, 90, 245))
    - Crisp white typography (Color3.fromRGB(245, 248, 255))
    - Clean developer dashboard tabs: PLAYERS, ELEMENTS, ANNOUNCEMENTS, SERVER
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local SharedLoader = require(script.Parent.Parent.SharedLoader)
local GameConfig = SharedLoader.GameConfig
local SoundController = require(script.Parent.SoundController)

local localPlayer = Players.LocalPlayer

local function GetPlayerGui(): PlayerGui?
    if not localPlayer then
        localPlayer = Players.LocalPlayer
    end
    if not localPlayer then return nil end
    return (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 15)) :: PlayerGui?
end

local AdminPanelController = {}

local panelGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local activeTabContent: GuiObject? = nil

local isOwner = (localPlayer.UserId == GameConfig.OWNER_USER_ID)

-- Modern Blox Fruits Style Color Tokens
local PALETTE = {
    BG_MAIN         = Color3.fromRGB(12, 16, 26),
    BG_CARD         = Color3.fromRGB(18, 24, 38),
    BG_ROW          = Color3.fromRGB(22, 28, 46),
    BORDER_DEFAULT  = Color3.fromRGB(42, 52, 75),
    BORDER_ACCENT   = Color3.fromRGB(115, 90, 245),
    TEXT_PRIMARY    = Color3.fromRGB(245, 248, 255),
    TEXT_MUTED      = Color3.fromRGB(135, 145, 170),
    BTN_PRIMARY     = Color3.fromRGB(115, 90, 245),
    BTN_DANGER      = Color3.fromRGB(225, 55, 65),
    BTN_SUCCESS     = Color3.fromRGB(46, 204, 113),
}

local function MakeRounded(instance: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function MakeStroke(instance: GuiObject, color: Color3, thickness: number): UIStroke
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = instance
    return s
end

-- Sends admin command via RemoteEvent
local function SendAdminCmd(cmd: string, arg1: any?, arg2: any?)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild(GameConfig.REMOTES.ADMIN_COMMAND) :: RemoteEvent?
    if event then
        event:FireServer(cmd, arg1, arg2)
    end
end

function AdminPanelController.Init()
    local playerGui = GetPlayerGui()
    if not playerGui then return end

    panelGui = Instance.new("ScreenGui")
    panelGui.Name = "ElementalWorlds_CreatorSuite"
    panelGui.ResetOnSpawn = false
    panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    panelGui.Parent = playerGui

    -- ==================== TOGGLE BUTTON (Owner only) ====================
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "CreatorSuiteToggle"
    toggleBtn.Size = UDim2.new(0, 130, 0, 38)
    toggleBtn.Position = UDim2.new(0, 20, 0.39, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = PALETTE.BORDER_ACCENT
    toggleBtn.Text = "CREATOR SUITE"
    toggleBtn.Visible = isOwner
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = panelGui
    MakeRounded(toggleBtn, 8)
    MakeStroke(toggleBtn, PALETTE.BORDER_ACCENT, 1.8)

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(32, 24, 58) }):Play()
        SoundController.PlayUI("hover")
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(20, 16, 36) }):Play()
    end)

    -- ==================== MAIN DASHBOARD ====================
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "CreatorDashboard"
    mainFrame.Size = UDim2.new(0, 640, 0, 460)
    mainFrame.Position = UDim2.new(0.5, -320, 0.5, -230)
    mainFrame.BackgroundColor3 = PALETTE.BG_MAIN
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Visible = false
    mainFrame.ZIndex = 30
    mainFrame.Parent = panelGui
    MakeRounded(mainFrame, 12)
    MakeStroke(mainFrame, PALETTE.BORDER_ACCENT, 2.0)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    titleBar.ZIndex = 31
    titleBar.Parent = mainFrame
    MakeRounded(titleBar, 12)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = PALETTE.TEXT_PRIMARY
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL WORLDS — DEVELOPER SUITE"
    titleLabel.ZIndex = 32
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = PALETTE.BTN_DANGER
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.ZIndex = 32
    closeBtn.Parent = titleBar
    MakeRounded(closeBtn, 6)

    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -36, 0, 36)
    tabBar.Position = UDim2.new(0, 18, 0, 56)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 31
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -36, 1, -108)
    contentArea.Position = UDim2.new(0, 18, 0, 98)
    contentArea.BackgroundColor3 = PALETTE.BG_CARD
    contentArea.ZIndex = 31
    contentArea.Parent = mainFrame
    MakeRounded(contentArea, 10)
    MakeStroke(contentArea, PALETTE.BORDER_DEFAULT, 1.2)

    -- ==================== TAB 1: PLAYERS ====================
    local playersTab = Instance.new("ScrollingFrame")
    playersTab.Name = "PlayersTab"
    playersTab.Size = UDim2.new(1, -16, 1, -16)
    playersTab.Position = UDim2.new(0, 8, 0, 8)
    playersTab.BackgroundTransparency = 1
    playersTab.ScrollBarThickness = 5
    playersTab.ScrollBarImageColor3 = PALETTE.BORDER_ACCENT
    playersTab.Visible = true
    playersTab.ZIndex = 32
    playersTab.Parent = contentArea

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim.new(0, 6)
    playersLayout.Parent = playersTab

    local function RefreshPlayers()
        for _, child in playersTab:GetChildren() do
            if child:IsA("Frame") then child:Destroy() end
        end

        local allPlayers = Players:GetPlayers()
        playersTab.CanvasSize = UDim2.new(0, 0, 0, #allPlayers * 54)

        for _, target in allPlayers do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -6, 0, 48)
            row.BackgroundColor3 = PALETTE.BG_ROW
            row.ZIndex = 33
            row.Parent = playersTab
            MakeRounded(row, 6)
            MakeStroke(row, PALETTE.BORDER_DEFAULT, 1.0)

            local pName = Instance.new("TextLabel")
            pName.Size = UDim2.new(0, 150, 1, 0)
            pName.Position = UDim2.new(0, 12, 0, 0)
            pName.BackgroundTransparency = 1
            pName.Font = Enum.Font.GothamBold
            pName.TextSize = 12
            pName.TextColor3 = PALETTE.TEXT_PRIMARY
            pName.TextXAlignment = Enum.TextXAlignment.Left
            pName.Text = target.Name .. (if target.UserId == GameConfig.OWNER_USER_ID then " [OWNER]" else "")
            pName.ZIndex = 34
            pName.Parent = row

            -- Action buttons container
            local actCont = Instance.new("Frame")
            actCont.Size = UDim2.new(1, -170, 1, 0)
            actCont.Position = UDim2.new(0, 165, 0, 0)
            actCont.BackgroundTransparency = 1
            actCont.ZIndex = 34
            actCont.Parent = row

            local actLayout = Instance.new("UIListLayout")
            actLayout.FillDirection = Enum.FillDirection.Horizontal
            actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            actLayout.Padding = UDim.new(0, 6)
            actLayout.Parent = actCont

            local function AddBtn(label: string, color: Color3, onClick: () -> ())
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 62, 0, 30)
                b.BackgroundColor3 = color
                b.Font = Enum.Font.GothamBlack
                b.TextSize = 10
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
                b.Text = label
                b.AutoButtonColor = false
                b.ZIndex = 35
                b.Parent = actCont
                MakeRounded(b, 4)
                b.MouseButton1Click:Connect(onClick)
            end

            AddBtn("TP", PALETTE.BTN_PRIMARY, function() SendAdminCmd("/tp", target.Name) end)
            AddBtn("BRING", PALETTE.BTN_PRIMARY, function() SendAdminCmd("/bring", target.Name) end)
            AddBtn("+5 LVL", PALETTE.BTN_SUCCESS, function() SendAdminCmd("/givelevel", target.Name, 5) end)
            AddBtn("+3 SPINS", Color3.fromRGB(0, 160, 245), function() SendAdminCmd("/givespins", target.Name, 3) end)
            AddBtn("HEAL", PALETTE.BTN_SUCCESS, function() SendAdminCmd("/heal", target.Name) end)
            if target.UserId ~= GameConfig.OWNER_USER_ID then
                AddBtn("KICK", PALETTE.BTN_DANGER, function() SendAdminCmd("/kick", target.Name) end)
            end
        end
    end

    -- ==================== TAB 2: ELEMENTS ====================
    local elementsTab = Instance.new("ScrollingFrame")
    elementsTab.Name = "ElementsTab"
    elementsTab.Size = UDim2.new(1, -16, 1, -16)
    elementsTab.Position = UDim2.new(0, 8, 0, 8)
    elementsTab.BackgroundTransparency = 1
    elementsTab.ScrollBarThickness = 5
    elementsTab.Visible = false
    elementsTab.ZIndex = 32
    elementsTab.Parent = contentArea

    local elemGrid = Instance.new("UIGridLayout")
    elemGrid.CellSize = UDim2.new(0, 180, 0, 52)
    elemGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    elemGrid.Parent = elementsTab

    local allElements = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
    for _, elem in allElements do
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = PALETTE.BG_ROW
        b.Font = Enum.Font.GothamBlack
        b.TextSize = 12
        b.TextColor3 = PALETTE.TEXT_PRIMARY
        b.Text = "SET " .. string.upper(elem)
        b.AutoButtonColor = false
        b.ZIndex = 33
        b.Parent = elementsTab
        MakeRounded(b, 6)
        MakeStroke(b, PALETTE.BORDER_ACCENT, 1.2)

        b.MouseButton1Click:Connect(function()
            SendAdminCmd("/giveelement", localPlayer.Name, elem)
            SoundController.PlayUI("success")
        end)
    end

    -- ==================== TAB 3: SERVER & RAIDS ====================
    local serverTab = Instance.new("Frame")
    serverTab.Name = "ServerTab"
    serverTab.Size = UDim2.new(1, -16, 1, -16)
    serverTab.Position = UDim2.new(0, 8, 0, 8)
    serverTab.BackgroundTransparency = 1
    serverTab.Visible = false
    serverTab.ZIndex = 32
    serverTab.Parent = contentArea

    local raidBtn = Instance.new("TextButton")
    raidBtn.Size = UDim2.new(0, 220, 0, 42)
    raidBtn.Position = UDim2.new(0, 10, 0, 10)
    raidBtn.BackgroundColor3 = PALETTE.BTN_PRIMARY
    raidBtn.Font = Enum.Font.GothamBlack
    raidBtn.TextSize = 13
    raidBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    raidBtn.Text = "TRIGGER ELEMENTAL RAID"
    raidBtn.AutoButtonColor = false
    raidBtn.ZIndex = 33
    raidBtn.Parent = serverTab
    MakeRounded(raidBtn, 6)

    raidBtn.MouseButton1Click:Connect(function()
        SendAdminCmd("/raid", "start")
        SoundController.PlayUI("success")
    end)

    local resetRngBtn = Instance.new("TextButton")
    resetRngBtn.Size = UDim2.new(0, 220, 0, 42)
    resetRngBtn.Position = UDim2.new(0, 240, 0, 10)
    resetRngBtn.BackgroundColor3 = PALETTE.BG_ROW
    resetRngBtn.Font = Enum.Font.GothamBold
    resetRngBtn.TextSize = 12
    resetRngBtn.TextColor3 = PALETTE.TEXT_PRIMARY
    resetRngBtn.Text = "RESET DROP RATES"
    resetRngBtn.AutoButtonColor = false
    resetRngBtn.ZIndex = 33
    resetRngBtn.Parent = serverTab
    MakeRounded(resetRngBtn, 6)
    MakeStroke(resetRngBtn, PALETTE.BORDER_DEFAULT, 1.2)

    resetRngBtn.MouseButton1Click:Connect(function()
        SendAdminCmd("/resetrng")
        SoundController.PlayUI("success")
    end)

    -- Tab buttons
    local function CreateTabBtn(name: string, targetFrame: GuiObject, isDefault: boolean)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 130, 1, 0)
        btn.BackgroundColor3 = if isDefault then PALETTE.BORDER_ACCENT else PALETTE.BG_CARD
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 11
        btn.TextColor3 = if isDefault then Color3.fromRGB(255, 255, 255) else PALETTE.TEXT_MUTED
        btn.Text = string.upper(name)
        btn.AutoButtonColor = false
        btn.ZIndex = 32
        btn.Parent = tabBar
        MakeRounded(btn, 6)

        btn.MouseButton1Click:Connect(function()
            for _, c in tabBar:GetChildren() do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = PALETTE.BG_CARD
                    c.TextColor3 = PALETTE.TEXT_MUTED
                end
            end
            btn.BackgroundColor3 = PALETTE.BORDER_ACCENT
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)

            playersTab.Visible = (targetFrame == playersTab)
            elementsTab.Visible = (targetFrame == elementsTab)
            serverTab.Visible = (targetFrame == serverTab)

            if targetFrame == playersTab then
                RefreshPlayers()
            end
        end)
    end

    CreateTabBtn("PLAYERS", playersTab, true)
    CreateTabBtn("ELEMENTS", elementsTab, false)
    CreateTabBtn("SERVER & RAIDS", serverTab, false)

    -- Toggle Dashboard
    local function TogglePanel()
        mainFrame.Visible = not mainFrame.Visible
        if mainFrame.Visible then
            SoundController.PlayUI("open")
            RefreshPlayers()
            mainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -320, 0.5, -230),
            }):Play()
        else
            SoundController.PlayUI("close")
        end
    end

    toggleBtn.MouseButton1Click:Connect(TogglePanel)
    closeBtn.MouseButton1Click:Connect(TogglePanel)

    -- Keyboard shortcut [P]
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.P and isOwner then
            TogglePanel()
        end
    end)
end

return table.freeze(AdminPanelController)
