--!strict
--[[
    Elemental Worlds: Camera Shake Controller
    Non-intrusive 6D Perlin noise camera shake based on trauma decay.
    NEVER locks or overrides the player's camera control.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

local CameraShakeController = {}

local trauma = 0.0
local shakeFrequency = 24.0
local maxPitch = 4.0   -- Max degrees
local maxYaw = 4.0     -- Max degrees
local maxRoll = 3.0    -- Max degrees

function CameraShakeController.Shake(intensity: number)
    -- Clamp trauma up to 1.0
    trauma = math.clamp(trauma + intensity, 0, 1.0)
end

function CameraShakeController.Init()
    camera = Workspace.CurrentCamera

    RunService.RenderStepped:Connect(function(deltaTime)
        if trauma <= 0 then return end

        -- Exponential trauma decay
        trauma = math.max(0, trauma - (deltaTime * 1.8))
        local shakeAmount = trauma * trauma -- Quadratic falloff gives crisp snap and smooth fade

        local time = os.clock() * shakeFrequency
        local yawOffset = (math.noise(time, 0, 0) - 0.5) * 2 * maxYaw * shakeAmount
        local pitchOffset = (math.noise(0, time, 0) - 0.5) * 2 * maxPitch * shakeAmount
        local rollOffset = (math.noise(0, 0, time) - 0.5) * 2 * maxRoll * shakeAmount

        local shakeCFrame = CFrame.Angles(math.rad(pitchOffset), math.rad(yawOffset), math.rad(rollOffset))
        camera.CFrame = camera.CFrame * shakeCFrame
    end)
end

return table.freeze(CameraShakeController)
