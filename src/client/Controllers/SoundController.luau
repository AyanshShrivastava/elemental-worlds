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

-- Verified Roblox Audio Asset IDs (Publicly Accessible)
local SFX_LIBRARY: { [string]: { string } } = {
    Punch = {
        "rbxassetid://1720389178",
        "rbxassetid://3041191430",
        "rbxassetid://5835032207",
        "rbxassetid://4612375233",
    },
    SwordSlash = {
        "rbxassetid://6760643020",
        "rbxassetid://7863855238",
        "rbxassetid://615910787",
        "rbxassetid://12222216",
    },
    Explosion = {
        "rbxassetid://3802269741",
        "rbxassetid://5898090542",
        "rbxassetid://287390954",
        "rbxassetid://138087122",
    },
    MagicCast = {
        "rbxassetid://3356359494",
        "rbxassetid://1840218341",
        "rbxassetid://1839806527",
    },
    Dash = {
        "rbxassetid://624706518",
        "rbxassetid://858508159",
    },
    HeavyHit = {
        "rbxassetid://3041191430",
        "rbxassetid://3802269741",
    },
    Glitch = {
        "rbxassetid://2767090000",
        "rbxassetid://5599818817",
        "rbxassetid://6527415891",
    },
    TimeStop = {
        "rbxassetid://4744477218",
        "rbxassetid://6148384813",
    },
    Water = {
        "rbxassetid://5850414902",
        "rbxassetid://6543434968",
    },
    Wind = {
        "rbxassetid://3484593077",
        "rbxassetid://624706518",
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
    success = "rbxasset://sounds/electronicpingshort.wav",
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
