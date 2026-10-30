--!strict
--[[
    Elemental Worlds: Creator & Admin In-Game Panel Controller
    Exclusively available to Creator (coolzgamer9 - 6225357795) and authorized Admins.
    
    Features:
    - PLAYERS tab: Player list with TP/Bring/Kill/Kick/Level buttons
    - ELEMENTS tab: Instant element giver, stat boosts
    - ANNOUNCEMENTS tab: Server-wide announcements with custom text
    - SERVER tab: Server stats, RNG reset
    - Press [P] or click the CREATOR PANEL button to toggle

    The panel is always loaded but only functional for owner/admins.
    Non-admins see the toggle button hidden.
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
local activeTabContent: GuiObject? = nil

-- Only show panel for owner
local isOwner = (localPlayer.UserId == GameConfig.OWNER_USER_ID)

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

-- Sends admin command via RemoteEvent (server handles authorization)
local function SendAdminCmd(cmd: string, arg1: any?, arg2: any?)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild(GameConfig.REMOTES.ADMIN_COMMAND) :: RemoteEvent?
    if event then
        event:FireServer(cmd, arg1, arg2)
    end
end

function AdminPanelController.Init()
    panelGui = Instance.new("ScreenGui")
    panelGui.Name = "ElementalWorlds_CreatorPanel"
    panelGui.ResetOnSpawn = false
    panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    panelGui.Parent = playerGui

    -- ==================== TOGGLE BUTTON (only shown to owner) ====================
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "CreatorPanelToggle"
    toggleBtn.Size = UDim2.new(0, 160, 0, 40)
    toggleBtn.Position = UDim2.new(0, 14, 0.44, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    toggleBtn.Text = "CREATOR PANEL"
    toggleBtn.Visible = isOwner
    toggleBtn.Parent = panelGui

    MakeRounded(toggleBtn, 10)
    MakeStroke(toggleBtn, Color3.fromRGB(255, 215, 0), 2)

    -- Hover effect
    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(40, 32, 65) }):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(22, 18, 38) }):Play()
    end)

    -- ==================== MAIN DASHBOARD ====================
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "CreatorDashboard"
    mainFrame.Size = UDim2.new(0, 620, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -310, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 24)
    mainFrame.BackgroundTransparency = 0.04
    mainFrame.Visible = false
    mainFrame.ZIndex = 10
    mainFrame.Parent = panelGui

    MakeRounded(mainFrame, 14)
    MakeStroke(mainFrame, Color3.fromRGB(180, 60, 255), 2.5)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(24, 18, 45)
    titleBar.ZIndex = 11
    titleBar.Parent = mainFrame
    MakeRounded(titleBar, 14)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 17
    titleLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "ELEMENTAL WORLDS - CREATOR SUITE"
    titleLabel.ZIndex = 12
    titleLabel.Parent = titleBar

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.ZIndex = 12
    closeBtn.Parent = titleBar
    MakeRounded(closeBtn, 8)

    -- ==================== TAB NAVIGATION BAR ====================
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 38)
    tabBar.Position = UDim2.new(0, 10, 0, 52)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 11
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    -- ==================== CONTENT AREA ====================
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -104)
    contentArea.Position = UDim2.new(0, 10, 0, 96)
    contentArea.BackgroundColor3 = Color3.fromRGB(20, 17, 34)
    contentArea.ZIndex = 11
    contentArea.Parent = mainFrame
    MakeRounded(contentArea, 10)
    MakeStroke(contentArea, Color3.fromRGB(55, 50, 80), 1.5)

    -- ==================== TAB 1: PLAYERS ====================
    local playersTab = Instance.new("ScrollingFrame")
    playersTab.Name = "PlayersTab"
    playersTab.Size = UDim2.new(1, -16, 1, -16)
    playersTab.Position = UDim2.new(0, 8, 0, 8)
    playersTab.BackgroundTransparency = 1
    playersTab.ScrollBarThickness = 5
    playersTab.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 200)
    playersTab.Visible = true
    playersTab.ZIndex = 12
    playersTab.Parent = contentArea

    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim.new(0, 5)
    playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playersLayout.Parent = playersTab

    local function RefreshPlayerList()
        for _, child in playersTab:GetChildren() do
            if child:IsA("Frame") then child:Destroy() end
        end

        local allPlayers = Players:GetPlayers()
        playersTab.CanvasSize = UDim2.new(0, 0, 0, #allPlayers * 50)

        for _, target in allPlayers do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = Color3.fromRGB(30, 26, 48)
            row.ZIndex = 13
            row.Parent = playersTab
            MakeRounded(row, 8)

            -- Avatar icon placeholder
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 34, 0, 34)
            icon.Position = UDim2.new(0, 5, 0.5, -17)
            icon.BackgroundColor3 = Color3.fromRGB(40, 36, 60)
            icon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. target.UserId .. "&w=48&h=48"
            icon.ZIndex = 14
            icon.Parent = row
            MakeRounded(icon, 6)

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(0, 120, 1, 0)
            nameL.Position = UDim2.new(0, 44, 0, 0)
            nameL.BackgroundTransparency = 1
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 13
            nameL.TextColor3 = (target == localPlayer)
                and Color3.fromRGB(255, 215, 0)
                or Color3.fromRGB(230, 228, 245)
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Text = target.Name
            nameL.ZIndex = 14
            nameL.Parent = row

            -- Action buttons
            local btnDefs = {
                { text = "TP",   pos = 170, color = Color3.fromRGB(40, 140, 220), cmd = "/tp",   arg = target.Name },
                { text = "BRING", pos = 222, color = Color3.fromRGB(120, 60, 200), cmd = "/bring", arg = target.Name },
                { text = "KILL", pos = 280, color = Color3.fromRGB(200, 55, 55),  cmd = "/kill",  arg = target.Name },
                { text = "KICK", pos = 332, color = Color3.fromRGB(220, 110, 25), cmd = "/kick",  arg = target.Name },
                { text = "+10",  pos = 384, color = Color3.fromRGB(46, 204, 113), cmd = "/givelevel", arg = target.Name, arg2 = "10" },
                { text = "+ELM", pos = 436, color = Color3.fromRGB(180, 50, 255), cmd = "/giveelement", arg = target.Name, arg2 = "Fire" },
            }

            for _, def in btnDefs do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 46, 0, 28)
                b.Position = UDim2.new(0, def.pos, 0.5, -14)
                b.BackgroundColor3 = def.color
                b.Font = Enum.Font.GothamBold
                b.TextSize = 10
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
                b.Text = def.text
                b.ZIndex = 14
                b.Parent = row
                MakeRounded(b, 6)

                local capturedDef = def
                b.MouseButton1Click:Connect(function()
                    SendAdminCmd(capturedDef.cmd, capturedDef.arg, capturedDef.arg2)
                end)
            end
        end
    end

    -- ==================== TAB 2: ELEMENTS & STATS ====================
    local elemTab = Instance.new("Frame")
    elemTab.Name = "ElemTab"
    elemTab.Size = UDim2.new(1, -16, 1, -16)
    elemTab.Position = UDim2.new(0, 8, 0, 8)
    elemTab.BackgroundTransparency = 1
    elemTab.Visible = false
    elemTab.ZIndex = 12
    elemTab.Parent = contentArea

    local elemTabLayout = Instance.new("UIListLayout")
    elemTabLayout.Padding = UDim.new(0, 12)
    elemTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    elemTabLayout.Parent = elemTab

    -- Element Giver Section
    local elemHeader = Instance.new("TextLabel")
    elemHeader.Size = UDim2.new(1, 0, 0, 26)
    elemHeader.BackgroundTransparency = 1
    elemHeader.Font = Enum.Font.GothamBold
    elemHeader.TextSize = 14
    elemHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
    elemHeader.TextXAlignment = Enum.TextXAlignment.Left
    elemHeader.Text = "GIVE ELEMENT TO SELF:"
    elemHeader.ZIndex = 13
    elemHeader.Parent = elemTab

    local elemRow = Instance.new("Frame")
    elemRow.Size = UDim2.new(1, 0, 0, 44)
    elemRow.BackgroundTransparency = 1
    elemRow.ZIndex = 13
    elemRow.Parent = elemTab

    local elemRowLayout = Instance.new("UIListLayout")
    elemRowLayout.FillDirection = Enum.FillDirection.Horizontal
    elemRowLayout.Padding = UDim.new(0, 6)
    elemRowLayout.Parent = elemRow

    local elemColors = {
        Fire = Color3.fromRGB(255, 75, 20),
        Aqua = Color3.fromRGB(20, 155, 255),
        Earth = Color3.fromRGB(155, 105, 55),
        Light = Color3.fromRGB(255, 220, 50),
        Wind = Color3.fromRGB(90, 230, 155),
        Error = Color3.fromRGB(255, 0, 128),
        Time = Color3.fromRGB(60, 125, 255),
    }

    for elem, color in elemColors do
        local eb = Instance.new("TextButton")
        eb.Size = UDim2.new(0, 68, 0, 38)
        eb.BackgroundColor3 = color
        eb.Font = Enum.Font.GothamBlack
        eb.TextSize = 11
        eb.TextColor3 = Color3.fromRGB(255, 255, 255)
        eb.Text = elem
        eb.ZIndex = 14
        eb.Parent = elemRow
        MakeRounded(eb, 8)

        local capturedElem = elem
        eb.MouseButton1Click:Connect(function()
            SendAdminCmd("/giveelement", localPlayer.Name, capturedElem)
        end)
    end

    -- Stat Boost Section
    local statHeader = Instance.new("TextLabel")
    statHeader.Size = UDim2.new(1, 0, 0, 26)
    statHeader.BackgroundTransparency = 1
    statHeader.Font = Enum.Font.GothamBold
    statHeader.TextSize = 14
    statHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
    statHeader.TextXAlignment = Enum.TextXAlignment.Left
    statHeader.Text = "STAT BOOSTS FOR SELF:"
    statHeader.ZIndex = 13
    statHeader.Parent = elemTab

    local boostRow = Instance.new("Frame")
    boostRow.Size = UDim2.new(1, 0, 0, 44)
    boostRow.BackgroundTransparency = 1
    boostRow.ZIndex = 13
    boostRow.Parent = elemTab

    local boostRowLayout = Instance.new("UIListLayout")
    boostRowLayout.FillDirection = Enum.FillDirection.Horizontal
    boostRowLayout.Padding = UDim.new(0, 6)
    boostRowLayout.Parent = boostRow

    local boosts = {
        { text = "+50 LVL",     cmd = "/givelevel",   arg1 = localPlayer.Name, arg2 = "50" },
        { text = "MAX LVL",     cmd = "/setlevel",    arg1 = localPlayer.Name, arg2 = "300" },
        { text = "+5000 CHG",   cmd = "/givecharges", arg1 = localPlayer.Name, arg2 = "5000" },
        { text = "MAX CHARGES", cmd = "/setcharges",  arg1 = localPlayer.Name, arg2 = "10000" },
    }
    for _, b in boosts do
        local bb = Instance.new("TextButton")
        bb.Size = UDim2.new(0, 120, 0, 38)
        bb.BackgroundColor3 = Color3.fromRGB(46, 200, 110)
        bb.Font = Enum.Font.GothamBold
        bb.TextSize = 11
        bb.TextColor3 = Color3.fromRGB(255, 255, 255)
        bb.Text = b.text
        bb.ZIndex = 14
        bb.Parent = boostRow
        MakeRounded(bb, 8)

        local captured = b
        bb.MouseButton1Click:Connect(function()
            SendAdminCmd(captured.cmd, captured.arg1, captured.arg2)
        end)
    end

    -- ==================== TAB 3: ANNOUNCEMENTS ====================
    local announceTab = Instance.new("Frame")
    announceTab.Name = "AnnounceTab"
    announceTab.Size = UDim2.new(1, -16, 1, -16)
    announceTab.Position = UDim2.new(0, 8, 0, 8)
    announceTab.BackgroundTransparency = 1
    announceTab.Visible = false
    announceTab.ZIndex = 12
    announceTab.Parent = contentArea

    local announceHeader = Instance.new("TextLabel")
    announceHeader.Size = UDim2.new(1, 0, 0, 28)
    announceHeader.BackgroundTransparency = 1
    announceHeader.Font = Enum.Font.GothamBold
    announceHeader.TextSize = 14
    announceHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
    announceHeader.TextXAlignment = Enum.TextXAlignment.Left
    announceHeader.Text = "SEND SERVER ANNOUNCEMENT:"
    announceHeader.ZIndex = 13
    announceHeader.Parent = announceTab

    local announceInput = Instance.new("TextBox")
    announceInput.Size = UDim2.new(1, 0, 0, 44)
    announceInput.Position = UDim2.new(0, 0, 0, 36)
    announceInput.BackgroundColor3 = Color3.fromRGB(28, 24, 44)
    announceInput.Font = Enum.Font.GothamBold
    announceInput.TextSize = 14
    announceInput.TextColor3 = Color3.fromRGB(240, 238, 255)
    announceInput.PlaceholderText = "Type announcement here..."
    announceInput.PlaceholderColor3 = Color3.fromRGB(100, 95, 130)
    announceInput.ClearTextOnFocus = false
    announceInput.ZIndex = 13
    announceInput.Parent = announceTab
    MakeRounded(announceInput, 8)
    MakeStroke(announceInput, Color3.fromRGB(100, 80, 160), 1.5)

    local sendAnnounceBtn = Instance.new("TextButton")
    sendAnnounceBtn.Size = UDim2.new(0, 180, 0, 40)
    sendAnnounceBtn.Position = UDim2.new(0, 0, 0, 92)
    sendAnnounceBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    sendAnnounceBtn.Font = Enum.Font.GothamBlack
    sendAnnounceBtn.TextSize = 14
    sendAnnounceBtn.TextColor3 = Color3.fromRGB(18, 15, 28)
    sendAnnounceBtn.Text = "SEND TO ALL"
    sendAnnounceBtn.ZIndex = 13
    sendAnnounceBtn.Parent = announceTab
    MakeRounded(sendAnnounceBtn, 10)

    sendAnnounceBtn.MouseButton1Click:Connect(function()
        local text = announceInput.Text
        if text and #text > 0 then
            SendAdminCmd("/announce", text)
            announceInput.Text = ""
        end
    end)

    -- Quick announce presets
    local presets = {
        { text = "Server restarting in 5 minutes!", color = Color3.fromRGB(220, 80, 80) },
        { text = "New update coming soon — stay tuned!", color = Color3.fromRGB(80, 180, 255) },
        { text = "Welcome to Elemental Worlds! Spin for your element!", color = Color3.fromRGB(100, 220, 100) },
    }

    for i, preset in presets do
        local pb = Instance.new("TextButton")
        pb.Size = UDim2.new(1, 0, 0, 36)
        pb.Position = UDim2.new(0, 0, 0, 140 + (i - 1) * 44)
        pb.BackgroundColor3 = preset.color
        pb.BackgroundTransparency = 0.3
        pb.Font = Enum.Font.GothamBold
        pb.TextSize = 11
        pb.TextColor3 = Color3.fromRGB(240, 238, 255)
        pb.TextXAlignment = Enum.TextXAlignment.Left
        pb.Text = "  " .. preset.text
        pb.ZIndex = 13
        pb.Parent = announceTab
        MakeRounded(pb, 8)

        local capturedPreset = preset
        pb.MouseButton1Click:Connect(function()
            announceInput.Text = capturedPreset.text
        end)
    end

    -- ==================== TAB 4: SERVER ====================
    local serverTab = Instance.new("Frame")
    serverTab.Name = "ServerTab"
    serverTab.Size = UDim2.new(1, -16, 1, -16)
    serverTab.Position = UDim2.new(0, 8, 0, 8)
    serverTab.BackgroundTransparency = 1
    serverTab.Visible = false
    serverTab.ZIndex = 12
    serverTab.Parent = contentArea

    local serverInfo = Instance.new("TextLabel")
    serverInfo.Size = UDim2.new(1, 0, 0, 100)
    serverInfo.BackgroundTransparency = 1
    serverInfo.Font = Enum.Font.GothamBold
    serverInfo.TextSize = 13
    serverInfo.TextColor3 = Color3.fromRGB(190, 188, 210)
    serverInfo.TextXAlignment = Enum.TextXAlignment.Left
    serverInfo.TextYAlignment = Enum.TextYAlignment.Top
    serverInfo.Text = string.format(
        "Server ID: %s\nPlayers: %d / 30\nOwner: coolzgamer9\nGame: Elemental Worlds",
        tostring(game.JobId):sub(1, 12) .. "...",
        #Players:GetPlayers()
    )
    serverInfo.ZIndex = 13
    serverInfo.Parent = serverTab

    local resetRngBtn = Instance.new("TextButton")
    resetRngBtn.Size = UDim2.new(0, 200, 0, 42)
    resetRngBtn.Position = UDim2.new(0, 0, 0, 110)
    resetRngBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    resetRngBtn.Font = Enum.Font.GothamBlack
    resetRngBtn.TextSize = 13
    resetRngBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetRngBtn.Text = "RESET RNG RATES"
    resetRngBtn.ZIndex = 13
    resetRngBtn.Parent = serverTab
    MakeRounded(resetRngBtn, 10)

    resetRngBtn.MouseButton1Click:Connect(function()
        SendAdminCmd("/resetrng")
    end)

    -- ==================== TAB BUILDER ====================
    local allTabs: { { name: string, content: GuiObject } } = {
        { name = "PLAYERS",    content = playersTab },
        { name = "ELEMENTS",   content = elemTab },
        { name = "ANNOUNCE",   content = announceTab },
        { name = "SERVER",     content = serverTab },
    }

    activeTabContent = playersTab

    local function SwitchTab(targetContent: GuiObject)
        for _, tabInfo in allTabs do
            tabInfo.content.Visible = (tabInfo.content == targetContent)
        end
        activeTabContent = targetContent
        if targetContent == playersTab then
            RefreshPlayerList()
        end
    end

    for i, tabInfo in allTabs do
        local tBtn = Instance.new("TextButton")
        tBtn.Size = UDim2.new(0, 120, 1, 0)
        tBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(60, 45, 100) or Color3.fromRGB(28, 24, 44)
        tBtn.Font = Enum.Font.GothamBold
        tBtn.TextSize = 12
        tBtn.TextColor3 = Color3.fromRGB(220, 218, 240)
        tBtn.Text = tabInfo.name
        tBtn.LayoutOrder = i
        tBtn.ZIndex = 12
        tBtn.Parent = tabBar
        MakeRounded(tBtn, 8)

        local capturedTabBtn = tBtn
        local capturedContent = tabInfo.content
        tBtn.MouseButton1Click:Connect(function()
            -- Deselect all tabs
            for _, tb in tabBar:GetChildren() do
                if tb:IsA("TextButton") then
                    TweenService:Create(tb, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(28, 24, 44),
                    }):Play()
                end
            end
            TweenService:Create(capturedTabBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(60, 45, 100),
            }):Play()
            SwitchTab(capturedContent)
        end)
    end

    -- ==================== TOGGLE LOGIC ====================
    local function TogglePanel()
        isPanelOpen = not isPanelOpen
        if isPanelOpen then
            mainFrame.Visible = true
            mainFrame.Size = UDim2.new(0, 0, 0, 0)
            mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 620, 0, 450),
                Position = UDim2.new(0.5, -310, 0.5, -225),
            }):Play()
            RefreshPlayerList()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            }):Play()
            task.delay(0.22, function()
                if mainFrame and not isPanelOpen then
                    mainFrame.Visible = false
                end
            end)
        end
    end

    toggleBtn.MouseButton1Click:Connect(TogglePanel)
    closeBtn.MouseButton1Click:Connect(TogglePanel)

    -- Keybind P to toggle (owner only)
    if isOwner then
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.P then
                TogglePanel()
            end
        end)
    end

    -- Initial player list
    RefreshPlayerList()
end

return table.freeze(AdminPanelController)
