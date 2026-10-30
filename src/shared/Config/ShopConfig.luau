--!strict
--[[
    Elemental Worlds: Shop & Monetization Configuration
    Defines GamePasses and Developer Products.
    IMPORTANT: After creating passes in Creator Hub, update the IDs in GameConfig.GAMEPASS_IDS and PRODUCT_IDS,
    then replace the Id = 0 values below with the real IDs.
]]

export type GamePassData = {
    Id: number,
    Name: string,
    Price: number,
    Description: string,
    PerkType: "DoubleExp" | "DoubleCharges" | "LuckySpins" | "VIPMaster" | "SpeedBoost",
    Icon: string,
    PerkDetail: string,
}

export type DevProductData = {
    Id: number,
    Name: string,
    Price: number,
    Description: string,
    SpinsAwarded: number,
    Icon: string,
}

local ShopConfig = {
    GAMEPASSES = {
        DoubleExp = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "2x EXP Booster",
            Price = 249,
            Description = "Permanently doubles all Level experience gains from raids and combat.",
            PerkType = "DoubleExp",
            Icon = "rbxassetid://1840218341",
            PerkDetail = "All EXP gains x2",
        },
        DoubleCharges = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "2x Charges Booster",
            Price = 199,
            Description = "Earn double Charges — up to 10,000 cap — from all activities.",
            PerkType = "DoubleCharges",
            Icon = "rbxassetid://3356359494",
            PerkDetail = "All Charge gains x2",
        },
        LuckySpins = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "Lucky Element Spins",
            Price = 399,
            Description = "Doubles the chance of rolling secret elements (Error and Time) on every spin.",
            PerkType = "LuckySpins",
            Icon = "rbxassetid://1839806527",
            PerkDetail = "Secret roll chance x2",
        },
        VIPMaster = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "VIP: Element Master",
            Price = 499,
            Description = "Exclusive VIP prestige badge, +200 max health, Royal Azure ambient aura, and priority server slots.",
            PerkType = "VIPMaster",
            Icon = "rbxassetid://6296105178",
            PerkDetail = "+200 HP + VIP Badge + Azure Aura",
        },
        SpeedBoost = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "Speed Demon",
            Price = 149,
            Description = "Permanently increases your walk speed and sprint speed by 20%.",
            PerkType = "SpeedBoost",
            Icon = "rbxassetid://3356359494",
            PerkDetail = "Move Speed +20%",
        },
    } :: { [string]: GamePassData },

    PRODUCTS = {
        Spins_1 = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "1x Element Spin",
            Price = 49,
            Description = "Grants 1 instant element spin ticket. Try your luck!",
            SpinsAwarded = 1,
            Icon = "rbxassetid://1840218341",
        },
        Spins_5 = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "5x Element Spins",
            Price = 199,
            Description = "Grants 5 instant element spin tickets. Better odds at secrets!",
            SpinsAwarded = 5,
            Icon = "rbxassetid://1839806527",
        },
        Spins_10 = {
            Id = 0,  -- Set after creating in Creator Hub
            Name = "10x Element Spins Bundle",
            Price = 349,
            Description = "Grants 10 instant element spin tickets. Best value bundle!",
            SpinsAwarded = 10,
            Icon = "rbxassetid://6296105178",
        },
    } :: { [string]: DevProductData },
}

--[[
    HOW TO ACTIVATE GAMEPASSES:
    1. Open Roblox Creator Hub: https://create.roblox.com/
    2. Navigate to your experience > Monetization > Game Passes
    3. Create each pass with the exact names above and the listed prices
    4. After creation, copy the Pass ID from the URL or pass settings page
    5. Update GameConfig.GAMEPASS_IDS with the real IDs
    6. Also update the Id = 0 values in this file with the real IDs
    7. Repeat for Developer Products > Monetization > Developer Products

    GAME PASSES TO CREATE:
    - "2x EXP Booster" — 249 Robux
    - "2x Charges Booster" — 199 Robux
    - "Lucky Element Spins" — 399 Robux
    - "VIP: Element Master" — 499 Robux
    - "Speed Demon" — 149 Robux

    DEVELOPER PRODUCTS TO CREATE:
    - "1x Element Spin" — 49 Robux
    - "5x Element Spins" — 199 Robux
    - "10x Element Spins Bundle" — 349 Robux
]]

return table.freeze(ShopConfig)
