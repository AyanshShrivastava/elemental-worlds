--!strict
--[[
    Elemental Worlds: Master Sound Controller
    High-fidelity 3D spatial and 2D combat sounds, direct audio asset playback,
    and distinct UI tactile interactions with organic pitch variance.
]]

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local SoundController = {}

-- Verified Roblox Audio Asset IDs
local SFX_LIBRARY: { [string]: { string } } = {
    Punch = {
        "rbxassetid://17325540665",
        "rbxassetid://8560439519",
        "rbxassetid://9075321955",
        "rbxassetid://7346569653",
        "rbxassetid://17429233290",
    },
    SwordSlash = {
        "rbxassetid://6230938036",
        "rbxassetid://6241709963",
        "rbxassetid://536642316",
        "rbxassetid://12222216",
    },
    Explosion = {
        "rbxassetid://17150550302",
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
        "rbxassetid://17429233290",
    },
    HeavyHit = {
        "rbxassetid://17429233290",
        "rbxassetid://17150550302",
    },
    Glitch = {
        "rbxassetid://9065458112",
        "rbxassetid://9114223401",
    },
    TimeStop = {
        "rbxassetid://9114223652",
        "rbxassetid://9114224018",
    },
    Water = {
        "rbxassetid://9114221585",
        "rbxassetid://6543434968",
    },
    Wind = {
        "rbxassetid://9114222047",
        "rbxassetid://9114222513",
    },
}

-- Direct 2D Audio Playback by Asset ID
function SoundController.PlayAudioId2D(assetId: string, volume: number?, pitch: number?)
    if not assetId or assetId == "" or assetId == "rbxassetid://0" then return end

    local sound = Instance.new("Sound")
    sound.SoundId = assetId
    sound.Volume = volume or 0.7
    sound.PlaybackSpeed = (pitch or 1.0) * (0.96 + math.random() * 0.08)
    sound.Parent = SoundService

    sound:Play()
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    Debris:AddItem(sound, 5)
end

-- Direct 3D Positional Audio Playback by Asset ID
function SoundController.PlayAudioId3D(assetId: string, position: Vector3, volume: number?, pitch: number?)
    if not assetId or assetId == "" or assetId == "rbxassetid://0" then return end

    local soundPart = Instance.new("Part")
    soundPart.Name = "SFX_DirectSpatialPart"
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.CFrame = CFrame.new(position)
    soundPart.Transparency = 1
    soundPart.CanCollide = false
    soundPart.Anchored = true
    soundPart.Parent = Workspace:FindFirstChild("VFX") or Workspace

    local sound = Instance.new("Sound")
    sound.SoundId = assetId
    sound.Volume = volume or 0.85
    sound.PlaybackSpeed = (pitch or 1.0) * (0.95 + math.random() * 0.1)
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 12
    sound.RollOffMaxDistance = 140
    sound.Parent = soundPart

    sound:Play()
    sound.Ended:Once(function()
        soundPart:Destroy()
    end)
    Debris:AddItem(soundPart, 6)
end

-- Plays a 3D positional sound by category
function SoundController.PlaySound3D(soundCategory: string, position: Vector3, volume: number?)
    local sounds = SFX_LIBRARY[soundCategory]
    if not sounds or #sounds == 0 then return end

    local chosenId = sounds[math.random(1, #sounds)]
    SoundController.PlayAudioId3D(chosenId, position, volume)
end

-- Plays a 2D interface or HUD sound by category
function SoundController.PlaySound2D(soundCategory: string, volume: number?)
    local sounds = SFX_LIBRARY[soundCategory]
    if not sounds or #sounds == 0 then return end

    local chosenId = sounds[math.random(1, #sounds)]
    SoundController.PlayAudioId2D(chosenId, volume)
end

-- Tactile UI Audio Library with distinct modern sounds
local UI_SFX: { [string]: string } = {
    hover = "rbxassetid://6895079853",
    click = "rbxassetid://8560439519",
    open = "rbxassetid://6230938036",
    close = "rbxassetid://6241709963",
    success = "rbxassetid://17150550302",
    spin_start = "rbxassetid://3356359494",
}

function SoundController.PlayUI(action: string)
    local soundId = UI_SFX[action] or UI_SFX.click
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = if action == "hover" then 0.22 else 0.5
    sound.PlaybackSpeed = if action == "hover" then 1.25 else 1.0
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    Debris:AddItem(sound, 3)
end

return table.freeze(SoundController)
