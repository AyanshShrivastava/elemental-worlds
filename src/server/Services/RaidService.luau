--!strict
--[[
    Elemental Worlds: Raid Progression Service
    Handles raid completion, awarding +3 Levels and +10 Charges with caps enforced.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local RaidService = {}

function RaidService.CompleteRaid(player: Player)
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return end

    -- Award +3 Levels (capped at 300)
    PlayerDataService.AddLevel(player, GameConfig.RAID_LEVEL_REWARD)

    -- Award +10 Charges (capped at 10,000)
    PlayerDataService.AddCharges(player, GameConfig.RAID_CHARGES_REWARD)

    -- Announce to client
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local announceEvent = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
        if announceEvent then
            announceEvent:FireClient(player, string.format("Raid Completed! +%d Levels, +%d Charges!", GameConfig.RAID_LEVEL_REWARD, GameConfig.RAID_CHARGES_REWARD))
        end
    end
end

return table.freeze(RaidService)
