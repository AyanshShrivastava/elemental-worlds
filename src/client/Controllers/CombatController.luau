--!strict
--[[
    Elemental Worlds: Client Combat Controller (Blox Fruits Anime Combat)
    Features:
    - 0ms Latency Client-Side Prediction: Animations, procedural motions, UI cooldown sweeps,
      and sound triggers fire INSTANTLY without waiting for network roundtrips!
    - Input Queuing & Buffering: Rapid M1 clicks within 0.14s of cooldown recovery automatically
      queue the next hit, eliminating dropped clicks.
    - Anime RPG Keybinds: [Z], [X], [C], [V], [B] AND [1], [2], [3], [4], [5]
    - Flash Step / Anime Dash on [Q] with velocity impulse, neon trails, FOV punch, and whoosh audio.
    - 4-hit M1 combo chain with alternating punches and heavy finisher camera shake.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local AnimationMarkerUtil = require(ReplicatedStorage.Shared.Modules.AnimationMarkerUtil)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)
local ProceduralAnimController = require(script.Parent.ProceduralAnimController)
local UIController = require(script.Parent.UIController)
local VFXController = require(script.Parent.VFXController)
local VFXHelper = require(ReplicatedStorage.Shared.Modules.VFXHelper)

local localPlayer = Players.LocalPlayer

local CombatController = {}

local castAbilityEvent: RemoteEvent? = nil
local abilityEvent: RemoteEvent? = nil

-- Combat & Element Cache
local currentElement = "Fire"
local localCooldowns: { [string]: number } = {}

-- Combo State
local comboStep = 1
local lastM1Time = 0.0
local COMBO_RESET_DELAY = 1.3
local m1Queued = false

-- Dash state
local lastDashTime = 0.0
local DASH_COOLDOWN = 1.2
local DASH_ENERGY_COST = 40

local onCooldownStartedCallback: ((slot: string, duration: number) -> ())? = nil

function CombatController.SetCooldownCallback(callback: (slot: string, duration: number) -> ())
    onCooldownStartedCallback = callback
end

function CombatController.SetCurrentElement(elem: string)
    currentElement = elem
end

-- ==================== FLASH STEP / ANIME DASH ====================
local function PerformAnimeDash()
    local now = os.clock()
    if now - lastDashTime < DASH_COOLDOWN then return end

    local char = localPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or humanoid.Health <= 0 or not rootPart then return end

    -- Consume energy
    local canDash = UIController.ConsumeEnergy(DASH_ENERGY_COST)
    if not canDash then return end

    lastDashTime = now

    -- Determine dash direction (movement direction or camera facing)
    local moveDir = humanoid.MoveDirection
    local dashDir = if moveDir.Magnitude > 0.1 then moveDir else rootPart.CFrame.LookVector

    -- Instant tactile feedback: dash sound, sonic shockwave ring & FOV punch
    SoundController.PlaySound2D("Dash", 0.9)
    CameraShakeController.Shake(0.18)
    VFXHelper.CreateShockwave(rootPart.Position, 7, 0.22, currentElement)

    -- Dynamic camera FOV punch
    local cam = Workspace.CurrentCamera
    if cam then
        local origFOV = cam.FieldOfView
        TweenService:Create(cam, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = origFOV + 6 }):Play()
        task.delay(0.12, function()
            TweenService:Create(cam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = origFOV }):Play()
        end)
    end

    -- High-velocity physics impulse
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart

    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.MaxForce = 140000
    linearVelocity.VectorVelocity = dashDir * 88
    linearVelocity.Attachment0 = attachment
    linearVelocity.Parent = rootPart

    -- Visual motion trail line styled with current element palette
    local elemPalette = VFXHelper.GetPalette(currentElement)
    local trailPart = Instance.new("Part")
    trailPart.Size = Vector3.new(0.4, 0.4, (dashDir * 22).Magnitude)
    trailPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -6)
    trailPart.Color = elemPalette.Secondary
    trailPart.Material = Enum.Material.Neon
    trailPart.Transparency = 0.2
    trailPart.Anchored = true
    trailPart.CanCollide = false
    trailPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    TweenService:Create(trailPart, TweenInfo.new(0.22), { Transparency = 1, Size = Vector3.new(0.02, 0.02, 28) }):Play()
    Debris:AddItem(trailPart, 0.3)

    task.delay(0.18, function()
        linearVelocity:Destroy()
        attachment:Destroy()
    end)
end

-- ==================== CLIENT PREDICTED CAST ====================
function CombatController.Cast(slot: string)
    if slot == "Dash" then
        PerformAnimeDash()
        return
    end

    if not castAbilityEvent then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            castAbilityEvent = remotes:FindFirstChild(GameConfig.REMOTES.CAST_ABILITY) :: RemoteEvent?
        end
    end

    local now = os.clock()
    local char = localPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local ability = AbilityConfig.GetAbility(currentElement, slot)

    if slot == "M1" then
        local m1Cooldown = if comboStep == 4 then 0.75 else 0.28

        -- Check cooldown & input buffer
        if localCooldowns["M1"] and now < localCooldowns["M1"] then
            local remaining = localCooldowns["M1"] - now
            if remaining <= 0.14 and not m1Queued then
                m1Queued = true
                task.delay(remaining, function()
                    m1Queued = false
                    CombatController.Cast("M1")
                end)
            end
            return
        end

        localCooldowns["M1"] = now + m1Cooldown

        if now - lastM1Time > COMBO_RESET_DELAY then
            comboStep = 1
        end
        lastM1Time = now

        -- 1. Instantly trigger UI cooldown
        if onCooldownStartedCallback then
            onCooldownStartedCallback("M1", m1Cooldown)
        end

        -- 2. Instantly trigger character animation & procedural motion
        ProceduralAnimController.PlayProceduralPunch(comboStep)
        if ability and ability.AnimationId and ability.AnimationId ~= "" then
            AnimationMarkerUtil.PlayWithMarker(humanoid, ability.AnimationId, "Hit", 0.2, function() end)
        end

        -- 3. Instant tactile sound & screen shake
        if ability and ability.SFXId and ability.SFXId ~= "" then
            SoundController.PlayAudioId2D(ability.SFXId, 0.7)
        else
            SoundController.PlaySound2D("Punch", 0.65)
        end
        if comboStep == 4 then
            CameraShakeController.Shake(0.35)
            VFXController.TriggerImpactFrame(0.06, 1.0)
        end

        -- 4. Authoritative server dispatch
        if castAbilityEvent then
            castAbilityEvent:FireServer("M1", { ComboStep = comboStep })
        end

        comboStep = (comboStep % 4) + 1
    else
        if not ability then return end

        local cd = ability.Cooldown
        if localCooldowns[slot] and now < localCooldowns[slot] then
            return
        end

        localCooldowns[slot] = now + cd

        -- 1. Instant UI cooldown sweep
        if onCooldownStartedCallback then
            onCooldownStartedCallback(slot, cd)
        end

        -- 2. Instant procedural motion & animation
        if slot == "2" or slot == "4" then
            ProceduralAnimController.PlayHeavySlam()
        else
            ProceduralAnimController.PlayLunge()
        end

        if ability.AnimationId and ability.AnimationId ~= "" then
            AnimationMarkerUtil.PlayWithMarker(humanoid, ability.AnimationId, ability.AnimationMarker or "Hit", 0.25, function() end)
        end

        -- 3. Instant sound, camera shake & ultimate effects
        if ability.SFXId and ability.SFXId ~= "" then
            SoundController.PlayAudioId2D(ability.SFXId, 0.8)
        else
            SoundController.PlaySound2D("MagicCast", 0.75)
        end
        CameraShakeController.Shake(ability.ScreenShake or 0.25)
        if slot == "4" then
            VFXController.TriggerImpactFrame(0.08, 1.2)
            VFXHelper.CreateConvergingCharge(char:GetPivot().Position, currentElement, 0.45)
        end

        -- 4. Authoritative server dispatch
        if castAbilityEvent then
            castAbilityEvent:FireServer(slot, {})
        end
    end
end

function CombatController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY) :: RemoteEvent?
    abilityEvent = remotes:WaitForChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?

    -- Server sync listener (re-syncs if server overrides cooldown)
    if abilityEvent then
        abilityEvent.OnClientEvent:Connect(function(slot: string, cooldown: number, animId: string?, marker: string?)
            localCooldowns[slot] = os.clock() + cooldown
            if onCooldownStartedCallback then
                onCooldownStartedCallback(slot, cooldown)
            end
        end)
    end

    -- PC Keyboard & Mouse Inputs (Blox Fruits style: Z/X/C/V or 1/2/3/4, Q for Dash)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            CombatController.Cast("M1")
        elseif input.KeyCode == Enum.KeyCode.Q then
            PerformAnimeDash()
        elseif input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.One then
            CombatController.Cast("1")
        elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.Two then
            CombatController.Cast("2")
        elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.Three then
            CombatController.Cast("3")
        elseif input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.Four then
            CombatController.Cast("4")
        elseif input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.Five then
            CombatController.Cast("5")
        end
    end)
end

return table.freeze(CombatController)
