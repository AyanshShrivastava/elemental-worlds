--!strict
--[[
    Elemental Worlds: Client VFX & Sound Controller
    Executes client-side effects (e.g., Blind, screen shakes, color flashes) triggered by server events.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local UIController = require(script.Parent.UIController)

local VFXController = {}

function VFXController.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then return end

    local vfxEvent = remotes:WaitForChild(GameConfig.REMOTES.VFX_TRIGGER, 5) :: RemoteEvent?
    if vfxEvent then
        vfxEvent.OnClientEvent:Connect(function(vfxType: string, data: any)
            if vfxType == "Blind" then
                local duration = (data and data.Duration) or 2.0
                UIController.TriggerBlind(duration)
            end
        end)
    end
end

return table.freeze(VFXController)
