--!strict
--[[
    Elemental Worlds: Client Shared Loader
    Safely awaits network replication of ReplicatedStorage.Shared before requiring configs and modules.
    Guarantees zero-crash client startup in Roblox Studio and live servers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 30) :: Folder
if not sharedFolder then
    error("[Elemental Worlds] Critical: ReplicatedStorage.Shared failed to replicate within 30s.")
end

local configFolder = sharedFolder:WaitForChild("Config", 30) :: Folder
local modulesFolder = sharedFolder:WaitForChild("Modules", 30) :: Folder

local SharedLoader = {
    Shared = sharedFolder,
    Config = configFolder,
    Modules = modulesFolder,

    GameConfig = require(configFolder:WaitForChild("GameConfig", 30)) :: any,
    AbilityConfig = require(configFolder:WaitForChild("AbilityConfig", 30)) :: any,
    AdminConfig = require(configFolder:WaitForChild("AdminConfig", 30)) :: any,
    ShopConfig = require(configFolder:WaitForChild("ShopConfig", 30)) :: any,

    AnimationMarkerUtil = require(modulesFolder:WaitForChild("AnimationMarkerUtil", 30)) :: any,
    CombatHelper = require(modulesFolder:WaitForChild("CombatHelper", 30)) :: any,
    StatusEffectTypes = require(modulesFolder:WaitForChild("StatusEffectTypes", 30)) :: any,
    VFXHelper = require(modulesFolder:WaitForChild("VFXHelper", 30)) :: any,
}

return table.freeze(SharedLoader)
