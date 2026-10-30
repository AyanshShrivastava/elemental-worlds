--!strict
--[[
    Elemental Worlds: Monetization & Gamepass Service
    Integrates MarketplaceService with PlayerDataService.
    Handles Gamepasses (2x EXP, 2x Charges, Lucky Spins, VIP) and Developer Products (Spin bundles).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MonetizationService = {}

-- Check existing GamePass ownership when player joins
function MonetizationService.CheckOwnershipOnJoin(player: Player)
    for passKey, passData in ShopConfig.GAMEPASSES do
        if passData.Id and passData.Id > 0 then
            local success, ownsPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.Id)
            end)
            if success and ownsPass then
                PlayerDataService.GrantGamePass(player, passKey)
            end
        end
    end
end

-- Hook gamepass purchase finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
    if not wasPurchased then return end

    for passKey, passData in ShopConfig.GAMEPASSES do
        if passData.Id == passId then
            PlayerDataService.GrantGamePass(player, passKey)
            print(string.format("[MonetizationService] %s purchased gamepass: %s", player.Name, passData.Name))
            break
        end
    end
end)

-- Hook developer product purchases (ProcessReceipt)
MarketplaceService.ProcessReceipt = function(receiptInfo): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local productId = receiptInfo.ProductId
    for _, productData in ShopConfig.PRODUCTS do
        if productData.Id == productId then
            local profile = PlayerDataService.GetProfile(player)
            if profile then
                profile.SpinTickets += productData.SpinsAwarded
                PlayerDataService.SyncClient(player)
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(MonetizationService.CheckOwnershipOnJoin)
for _, p in Players:GetPlayers() do
    MonetizationService.CheckOwnershipOnJoin(p)
end

return table.freeze(MonetizationService)
