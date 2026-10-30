--!strict
--[[
    Elemental Worlds: Client Combat Controller (Blox Fruits Modern Design)
    Features:
    - Anime RPG Keybinds: [Z], [X], [C], [V], [B] AND [1], [2], [3], [4], [5]
    - Flash Step / Anime Dash on [Q] consuming Energy
    - 4-hit M1 combo chain with procedural punch animations, hit sounds, and camera shakes
    - Automatic integration with UI cooldown sweep
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AnimationMarkerUtil = require(ReplicatedStorage.Shared.Modules.AnimationMarkerUtil)
local SoundController = require(script.Parent.SoundController)
local CameraShakeController = require(script.Parent.CameraShakeController)
local ProceduralAnimController = require(script.Parent.ProceduralAnimController)
local UIController = require(script.Parent.UIController)

local localPlayer = Players.LocalPlayer

local CombatController = {}

local castAbilityEvent: RemoteEvent? = nil
local abilityEvent: RemoteEvent? = nil

-- Combo State
local comboStep = 1
local lastM1Time = 0.0
local COMBO_RESET_DELAY = 1.3

-- Dash cooldown state
local lastDashTime = 0.0
local DASH_COOLDOWN = 1.2
local DASH_ENERGY_COST = 40

local onCooldownStartedCallback: ((slot: string, duration: number) -> ())? = nil

function CombatController.SetCooldownCallback(callback: (slot: string, duration: number) -> ())
    onCooldownStartedCallback = callback
end

-- Anime Flash Step / Dash forward
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

    -- Determine dash direction (movement vector or camera facing)
    local moveDir = humanoid.MoveDirection
    local dashDir = if moveDir.Magnitude > 0.1 then moveDir else rootPart.CFrame.LookVector

    -- Play whoosh audio and camera punch
    SoundController.PlaySound2D("MagicCast", 0.8)
    CameraShakeController.Shake(0.18)

    -- Temporary high-velocity impulse
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart

    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.MaxForce = 120000
    linearVelocity.VectorVelocity = dashDir * 85
    linearVelocity.Attachment0 = attachment
    linearVelocity.Parent = rootPart

    -- Visual trail line part
    local trailPart = Instance.new("Part")
    trailPart.Size = Vector3.new(0.4, 0.4, (dashDir * 20).Magnitude)
    trailPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -5)
    trailPart.Color = Color3.fromRGB(0, 180, 255)
    trailPart.Material = Enum.Material.Neon
    trailPart.Transparency = 0.3
    trailPart.Anchored = true
    trailPart.CanCollide = false
    trailPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    TweenService:Create(trailPart, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.05, 0.05, 25) }):Play()
    Debris:AddItem(trailPart, 0.3)

    task.delay(0.18, function()
        linearVelocity:Destroy()
        attachment:Destroy()
    end)
end

-- Cast ability
function CombatController.Cast(slot: string)
    if not castAbilityEvent then
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY, 5) :: RemoteEvent?
        end
    end

    if not castAbilityEvent then return end

    if slot == "Dash" then
        PerformAnimeDash()
        return
    end

    if slot == "M1" then
        local now = os.clock()
        if now - lastM1Time > COMBO_RESET_DELAY then
            comboStep = 1
        end
        lastM1Time = now

        -- Procedural punch animation & sound
        ProceduralAnimController.PlayProceduralPunch(comboStep)
        SoundController.PlaySound2D("Punch", 0.6)

        -- Finisher camera shake
        if comboStep == 4 then
            CameraShakeController.Shake(0.35)
        end

        castAbilityEvent:FireServer(slot, { ComboStep = comboStep })
        comboStep = (comboStep % 4) + 1
    else
        -- Heavy cast motion
        ProceduralAnimController.PlayCastRecoil()
        SoundController.PlaySound2D("MagicCast", 0.7)
        CameraShakeController.Shake(0.2)
        castAbilityEvent:FireServer(slot, {})
    end
end

function CombatController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    castAbilityEvent = remotes:WaitForChild(GameConfig.REMOTES.CAST_ABILITY) :: RemoteEvent?
    abilityEvent = remotes:WaitForChild(GameConfig.REMOTES.ABILITY_EVENT) :: RemoteEvent?

    -- Server ability execution listener
    if abilityEvent then
        abilityEvent.OnClientEvent:Connect(function(slot: string, cooldown: number, animId: string?, marker: string?)
            if onCooldownStartedCallback then
                onCooldownStartedCallback(slot, cooldown)
            end

            local character = localPlayer.Character
            if character and animId and animId ~= "" and animId ~= "rbxassetid://0" then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    AnimationMarkerUtil.PlayWithMarker(humanoid, animId, marker or "Hit", 0.3, function() end)
                end
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
