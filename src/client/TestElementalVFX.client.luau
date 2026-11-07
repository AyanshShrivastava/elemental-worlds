--!strict
--[[
    ===========================================================================
    ELEMENTAL WORLDS — CLIENT VFX TEST & SHOWCASE HARNESS
    ===========================================================================
    Location: StarterPlayer.StarterPlayerScripts.TestElementalVFX
    Demonstrates and tests all 36 ability visual effects from ReplicatedStorage.ElementalVFX.

    CONTROLS:
    - [T]: Cycle selected test element (Fire -> Aqua -> Earth -> Light -> Wind -> Error -> Time)
    - [M] / [F]: Cast M1
    - [1]: Cast Move 1
    - [2]: Cast Move 2
    - [3]: Cast Move 3 (handles auto-cycled/ended if persistent)
    - [4]: Cast Move 4
    - [5]: Cast Move 5 (Error only)
    - [P]: Run Automatic Showcase Demo across all 7 elements & 36 abilities!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local function triggerCameraShake(duration, intensity)
    local startTime = tick()
    local connection
    
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed < duration then
            -- Generate random shake offset that decays over time
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

-- Safe UIController hook
local UIController = nil
pcall(function()
    local sp = game:GetService("StarterPlayer")
    local sps = sp:FindFirstChild("StarterPlayerScripts")
    if sps then
        local ewClient = sps:FindFirstChild("ElementalWorldsClient")
        if ewClient then
            local controllers = ewClient:FindFirstChild("Controllers")
            if controllers then
                local uiMod = controllers:FindFirstChild("UIController")
                if uiMod then
                    UIController = require(uiMod)
                end
            end
        end
    end
end)

local ELEMENTS = { "Fire", "Aqua", "Earth", "Light", "Wind", "Error", "Time" }
local currentElementIndex = 1
local activeHandles = {}
local comboCount = 0

-- Initialize Master HUD if available
if UIController then
    task.spawn(function()
        task.wait(0.2)
        UIController.CreateHUD()
        UIController.UpdateStats({
            Element = "Fire",
            Level = 100,
            MaxHealth = 1000,
            Charges = 500,
            ErrorMeter = 0,
        })
        UIController.SetHealth(1000, 1000)
    end)
end

local function GetContext()
    local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return nil end
    local targetPos = root.Position + root.CFrame.LookVector * 28
    return {
        character = character,
        target = targetPos,
        origin = root.Position,
        direction = root.CFrame.LookVector,
        duration = 5,
        radius = 16,
    }
end

local function PlayMove(element: string, move: string)
    local ctx = GetContext()
    if not ctx then return end

    print(string.format("[VFX Test] Playing %s %s...", element, move))
    local handle = VFX.Play(element, move, ctx)

    -- Trigger Camera Shake on impact/cast
    triggerCameraShake(0.15, 1.5)

    -- Trigger HUD feedback
    if UIController then
        comboCount = comboCount + 1
        UIController.RegisterComboHit(comboCount)
        local slotMap = { M1 = "M1", Move1 = "1", Move2 = "2", Move3 = "3", Move4 = "4", Move5 = "5" }
        local slot = slotMap[move]
        if slot then
            UIController.StartCooldown(slot, slot == "M1" and 1.0 or 4.0)
        end
    end

    if handle then
        print(string.format("[VFX Test] %s %s returned active handle.", element, move))
        table.insert(activeHandles, {
            element = element,
            move = move,
            handle = handle,
            time = os.clock(),
        })

        -- Auto-demonstrate handle methods after delay
        task.delay(2.5, function()
            if handle.Hit then
                pcall(function() handle:Hit() end)
            end
            if handle.SetHealth then
                pcall(function() handle:SetHealth(0.4) end)
            end
            if handle.Attack then
                pcall(function() handle:Attack(ctx.target) end)
            end
        end)

        task.delay(4.5, function()
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

-- Automatic Showcase
local isShowcaseRunning = false
local function RunShowcase()
    if isShowcaseRunning then return end
    isShowcaseRunning = true
    print("==================================================")
    print("STARTING COMPLETE 36-ABILITY VFX SHOWCASE DEMO...")
    print("==================================================")

    task.spawn(function()
        for _, elem in ipairs(ELEMENTS) do
            local moves = { "M1", "Move1", "Move2", "Move3", "Move4" }
            if elem == "Error" then
                table.insert(moves, "Move5")
            end

            for _, mv in ipairs(moves) do
                PlayMove(elem, mv)
                task.wait(1.4)
            end
            task.wait(0.8)
        end
        print("==================================================")
        print("VFX SHOWCASE DEMO COMPLETED!")
        print("==================================================")
        isShowcaseRunning = false
    end)
end

-- Keybind listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.T then
        currentElementIndex = (currentElementIndex % #ELEMENTS) + 1
        local selected = ELEMENTS[currentElementIndex]
        print(string.format("[VFX Test] Selected Element: %s (Press M/1/2/3/4/5 or P for Showcase)", selected))
        if UIController then
            UIController.UpdateStats({
                Element = selected,
                Level = 100,
                MaxHealth = 1000,
                Charges = 500,
                ErrorMeter = (selected == "Error" and 75 or 0),
            })
            UIController.ShowAnnouncement("Switched Element: " .. selected)
        end

    elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.F then
        PlayMove(ELEMENTS[currentElementIndex], "M1")

    elseif input.KeyCode == Enum.KeyCode.One then
        PlayMove(ELEMENTS[currentElementIndex], "Move1")

    elseif input.KeyCode == Enum.KeyCode.Two then
        PlayMove(ELEMENTS[currentElementIndex], "Move2")

    elseif input.KeyCode == Enum.KeyCode.Three then
        PlayMove(ELEMENTS[currentElementIndex], "Move3")

    elseif input.KeyCode == Enum.KeyCode.Four then
        PlayMove(ELEMENTS[currentElementIndex], "Move4")

    elseif input.KeyCode == Enum.KeyCode.Five then
        if ELEMENTS[currentElementIndex] == "Error" then
            PlayMove("Error", "Move5")
        end

    elseif input.KeyCode == Enum.KeyCode.P then
        RunShowcase()
    end
end)

print("[Elemental Worlds VFX] Test Harness loaded! Press 'T' to switch element, 'M'/'1'-'4' to cast, 'P' for showcase.")
