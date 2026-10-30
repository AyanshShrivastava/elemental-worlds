--!strict
--[[
    Elemental Worlds: Master Sound Controller
    Plays 3D spatial and 2D combat sounds with random pitch modulation for immersive audio feedback.
]]

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local SoundController = {}

-- Verified Roblox Audio Asset IDs
local SFX_LIBRARY = {
    Punch = {
        "rbxassetid://8560439519",
        "rbxassetid://9075321955",
        "rbxassetid://7346569653",
    },
    SwordSlash = {
        "rbxassetid://6230938036",
        "rbxassetid://6241709963",
        "rbxassetid://536642316",
    },
    Explosion = {
        "rbxassetid://6296105178",
        "rbxassetid://2042692050",
        "rbxassetid://5898090542",
    },
    MagicCast = {
        "rbxassetid://3356359494",
        "rbxassetid://1840218341",
        "rbxassetid://1839806527",
    },
    Dash = {
        "rbxassetid://6230938036",
    },
}

-- Plays a 3D positional sound in workspace with natural pitch variation
function SoundController.PlaySound3D(soundCategory: string, position: Vector3, volume: number?)
    local sounds = SFX_LIBRARY[soundCategory]
    if not sounds or #sounds == 0 then return end

    local chosenId = sounds[math.random(1, #sounds)]

    local soundPart = Instance.new("Part")
    soundPart.Name = "SFX_SpatialPart"
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.CFrame = CFrame.new(position)
    soundPart.Transparency = 1
    soundPart.CanCollide = false
    soundPart.Anchored = true
    soundPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    local sound = Instance.new("Sound")
    sound.SoundId = chosenId
    sound.Volume = volume or 0.8
    -- Subtle random pitch for organic combat variation
    sound.PlaybackSpeed = 0.94 + (math.random() * 0.12)
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 120
    sound.Parent = soundPart

    sound:Play()
    sound.Ended:Once(function()
        soundPart:Destroy()
    end)
    Debris:AddItem(soundPart, 5)
end

-- Plays a 2D interface or HUD sound
function SoundController.PlaySound2D(soundCategory: string, volume: number?)
    local sounds = SFX_LIBRARY[soundCategory]
    if not sounds or #sounds == 0 then return end

    local chosenId = sounds[math.random(1, #sounds)]
    local sound = Instance.new("Sound")
    sound.SoundId = chosenId
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = 0.96 + (math.random() * 0.08)
    sound.Parent = SoundService

    sound:Play()
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    Debris:AddItem(sound, 4)
end

return table.freeze(SoundController)
