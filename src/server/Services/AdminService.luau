--!strict
--[[
    Elemental Worlds: Admin & Owner Command Service
    Authenticates Owner strictly by numeric UserId (6225357795).
    Resolves admin usernames to immutable UserIds.
    Prevents admins from targeting the owner or executing owner-only commands.
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local AdminConfig = require(ReplicatedStorage.Shared.Config.AdminConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RNGSystem = require(script.Parent.RNGSystem)

local AdminService = {}

-- Set of authorized admin UserIds (resolved at runtime)
local authorizedAdminUserIds: { [number]: boolean } = {}
local bannedUserIds: { [number]: boolean } = {}

-- Resolve initial admin usernames to numeric UserIds
local function ResolveInitialAdmins()
    for _, username in AdminConfig.INITIAL_ADMIN_USERNAMES do
        task.spawn(function()
            local success, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(username)
            end)
            if success and userId and userId ~= GameConfig.OWNER_USER_ID then
                authorizedAdminUserIds[userId] = true
            end
        end)
    end
end
ResolveInitialAdmins()

function AdminService.IsOwner(player: Player): boolean
    return player.UserId == GameConfig.OWNER_USER_ID
end

function AdminService.IsAdmin(player: Player): boolean
    if AdminService.IsOwner(player) then
        return true
    end
    return authorizedAdminUserIds[player.UserId] == true
end

-- Find a connected player by name fragment
local function FindPlayerByName(name: string): Player?
    name = string.lower(name)
    for _, player in Players:GetPlayers() do
        if string.lower(player.Name) == name or string.find(string.lower(player.Name), name) == 1 then
            return player
        end
    end
    return nil
end

-- Process command string from player
function AdminService.ExecuteCommand(sender: Player, message: string): boolean
    if not string.find(message, "^/") then
        return false -- Not a command
    end

    local tokens = string.split(message, " ")
    local cmd = string.lower(tokens[1])
    local isOwner = AdminService.IsOwner(sender)
    local isAdmin = AdminService.IsAdmin(sender)

    if not isAdmin then
        return false -- Unauthorized
    end

    -- Check if it is an owner-only command
    if AdminConfig.OWNER_ONLY_COMMANDS[cmd] and not isOwner then
        warn(string.format("[AdminService] %s attempted unauthorized owner command: %s", sender.Name, cmd))
        return false
    end

    -- ==================== OWNER-ONLY COMMANDS ====================
    if isOwner then
        if cmd == "/addadmin" then
            local targetName = tokens[2]
            if targetName then
                local success, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                if success and targetId and targetId ~= GameConfig.OWNER_USER_ID then
                    authorizedAdminUserIds[targetId] = true
                    print(string.format("[AdminService] Added admin: %s (%d)", targetName, targetId))
                end
            end
            return true
        elseif cmd == "/removeadmin" then
            local targetName = tokens[2]
            if targetName then
                local success, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                if success and targetId then
                    authorizedAdminUserIds[targetId] = nil
                    print(string.format("[AdminService] Removed admin: %s (%d)", targetName, targetId))
                end
            end
            return true
        elseif cmd == "/kick" then
            local target = FindPlayerByName(tokens[2] or "")
            if target and target.UserId ~= GameConfig.OWNER_USER_ID then
                target:Kick(tokens[3] or "Kicked by Owner.")
            end
            return true
        elseif cmd == "/ban" then
            local targetName = tokens[2]
            if targetName then
                local success, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                if success and targetId and targetId ~= GameConfig.OWNER_USER_ID then
                    bannedUserIds[targetId] = true
                    local target = Players:GetPlayerByUserId(targetId)
                    if target then target:Kick("Banned by Owner.") end
                end
            end
            return true
        elseif cmd == "/unban" then
            local targetName = tokens[2]
            if targetName then
                local success, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                if success and targetId then
                    bannedUserIds[targetId] = nil
                end
            end
            return true
        elseif cmd == "/setcharges" then
            local target = FindPlayerByName(tokens[2] or "")
            local amount = tonumber(tokens[3])
            if target and amount then
                PlayerDataService.SetCharges(target, amount)
            end
            return true
        elseif cmd == "/resetrng" then
            RNGSystem.ResetRates(sender)
            return true
        elseif cmd == "/kill" then
            local target = FindPlayerByName(tokens[2] or "")
            if target and target.UserId ~= GameConfig.OWNER_USER_ID and target.Character then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
            return true
        elseif cmd == "/tp" then
            local target = FindPlayerByName(tokens[2] or "")
            if target and target.Character and sender.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                local sRoot = sender.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                if tRoot and sRoot then
                    sRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                end
            end
            return true
        elseif cmd == "/bring" then
            local target = FindPlayerByName(tokens[2] or "")
            if target and target.UserId ~= GameConfig.OWNER_USER_ID and target.Character and sender.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                local sRoot = sender.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                if tRoot and sRoot then
                    tRoot.CFrame = sRoot.CFrame * CFrame.new(0, 0, -3)
                end
            end
            return true
        end
    end

    -- ==================== ADMIN & OWNER COMMANDS ====================
    if cmd == "/givelevel" then
        local target = FindPlayerByName(tokens[2] or "")
        local amount = tonumber(tokens[3]) or 1
        if target then
            PlayerDataService.AddLevel(target, amount)
        end
        return true
    elseif cmd == "/removelevel" then
        local target = FindPlayerByName(tokens[2] or "")
        local amount = tonumber(tokens[3]) or 1
        if target then
            PlayerDataService.AddLevel(target, -amount)
        end
        return true
    elseif cmd == "/setlevel" then
        local target = FindPlayerByName(tokens[2] or "")
        local level = tonumber(tokens[3])
        if target and level then
            PlayerDataService.SetLevel(target, level)
        end
        return true
    elseif cmd == "/givecharges" then
        local target = FindPlayerByName(tokens[2] or "")
        local amount = tonumber(tokens[3]) or 10
        if target then
            PlayerDataService.AddCharges(target, amount)
        end
        return true
    elseif cmd == "/removecharges" then
        local target = FindPlayerByName(tokens[2] or "")
        local amount = tonumber(tokens[3]) or 10
        if target then
            PlayerDataService.AddCharges(target, -amount)
        end
        return true
    elseif cmd == "/giveelement" then
        local target = FindPlayerByName(tokens[2] or "")
        local elemName = tokens[3]
        local validElements = { Fire = true, Aqua = true, Earth = true, Light = true, Wind = true, Error = true, Time = true }
        if target and elemName and validElements[elemName] then
            PlayerDataService.SetElement(target, elemName :: GameConfig.ElementType)
        end
        return true
    elseif cmd == "/announce" then
        local announcement = table.concat(tokens, " ", 2)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local announceEvent = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
            if announceEvent then
                announceEvent:FireAllClients(string.format("[ANNOUNCEMENT] %s", announcement))
            end
        end
        return true
    end

    return false
end

-- Check bans on player joining
Players.PlayerAdded:Connect(function(player)
    if bannedUserIds[player.UserId] and player.UserId ~= GameConfig.OWNER_USER_ID then
        player:Kick("You are banned from Elemental Worlds.")
    end
end)

return table.freeze(AdminService)
