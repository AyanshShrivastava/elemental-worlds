--!strict
--[[
    Elemental Worlds: VFX Broadcast Service
    Provides high-performance, safe replication of VFX events (Craters, Beams,
    Shockwaves, SlashArcs, ImpactBursts, ScreenShakes) from server to all clients or specific players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local VFXBroadcastService = {}

local vfxEvent: RemoteEvent? = nil

local function GetVFXRemote(): RemoteEvent?
    if not vfxEvent then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            vfxEvent = remotes:FindFirstChild(GameConfig.REMOTES.VFX_TRIGGER) :: RemoteEvent?
        end
    end
    return vfxEvent
end

function VFXBroadcastService.Broadcast(vfxType: string, payload: any)
    local remote = GetVFXRemote()
    if remote then
        remote:FireAllClients(vfxType, payload)
    end
end

function VFXBroadcastService.BroadcastTo(player: Player, vfxType: string, payload: any)
    local remote = GetVFXRemote()
    if remote then
        remote:FireClient(player, vfxType, payload)
    end
end

return table.freeze(VFXBroadcastService)
