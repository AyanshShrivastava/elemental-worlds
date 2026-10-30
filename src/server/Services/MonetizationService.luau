--!strict
--[[
    Elemental Worlds: Monetization & Gamepass Service
    Integrates MarketplaceService with PlayerDataService.
    Handles: GamePasses (2x EXP, 2x Charges, Lucky Spins, VIP, Speed), and Developer Products (Spin bundles).

    HOW TO ACTIVATE:
    1. Create your passes in Creator Hub > Monetization > Game Passes
    2. Update GameConfig.GAMEPASS_IDS with the real IDs
    3. Create Developer Products and update GameConfig.PRODUCT_IDS
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MonetizationService = {}

-- Internal pass key reverse lookup by Id
local function BuildPassKeyMap(): { [number]: string }
    local map: { [number]: string } = {}
    for passKey, passData in ShopConfig.GAMEPASSES do
        if passData.Id and passData.Id > 0 then
            map[passData.Id] = passKey
        end
    end
    return map
end

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

-- Prompt purchase helper
function MonetizationService.PromptGamePass(player: Player, passKey: string)
    local passData = ShopConfig.GAMEPASSES[passKey]
    if not passData then return end
    if passData.Id <= 0 then
        -- Pass not yet configured in Creator Hub, inform via print
        warn(string.format("[MonetizationService] Gamepass '%s' has no real ID yet. Create it in Creator Hub.", passKey))
        return
    end
    MarketplaceService:PromptGamePassPurchase(player, passData.Id)
end

function MonetizationService.PromptProduct(player: Player, productKey: string)
    local productData = ShopConfig.PRODUCTS[productKey]
    if not productData then return end
    if productData.Id <= 0 then
        warn(string.format("[MonetizationService] Product '%s' has no real ID yet. Create it in Creator Hub.", productKey))
        return
    end
    MarketplaceService:PromptProductPurchase(player, productData.Id)
end

-- Hook gamepass purchase finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
    if not wasPurchased then return end

    for passKey, passData in ShopConfig.GAMEPASSES do
        if passData.Id == passId then
            PlayerDataService.GrantGamePass(player, passKey)

            -- Apply immediate effects
            if passKey == "SpeedBoost" then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.WalkSpeed = 19
                        hum.JumpPower = 54
                    end
                end
            end

            -- Notify player
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local announce = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
                if announce then
                    announce:FireClient(player, string.format("Purchased gamepass: %s! Enjoy your perks.", passData.Name))
                end
            end

            print(string.format("[MonetizationService] %s purchased gamepass: %s", player.Name, passData.Name))
            break
        end
    end
end)

-- Hook developer product purchases (ProcessReceipt)
-- IMPORTANT: Only one ProcessReceipt can be set per server. If you use other services, merge them here.
MarketplaceService.ProcessReceipt = function(receiptInfo): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- Player may have left. Return NotProcessedYet so Roblox retries later.
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local productId = receiptInfo.ProductId
    for _, productData in ShopConfig.PRODUCTS do
        if productData.Id == productId and productData.Id > 0 then
            local profile = PlayerDataService.GetProfile(player)
            if not profile then
                return Enum.ProductPurchaseDecision.NotProcessedYet
            end
            PlayerDataService.AddSpinTickets(player, productData.SpinsAwarded)

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local announce = remotes:FindFirstChild(GameConfig.REMOTES.GLOBAL_ANNOUNCEMENT) :: RemoteEvent?
                if announce then
                    announce:FireClient(player, string.format("Purchased %s! Tickets added to your account.", productData.Name))
                end
            end

            print(string.format("[MonetizationService] %s purchased product: %s (+%d spins)", player.Name, productData.Name, productData.SpinsAwarded))
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    -- Unrecognized product — grant to avoid duplicate charges
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

return table.freeze(MonetizationService)
