--!strict
--[[
    Elemental Worlds: Shop & Monetization Configuration
    Defines GamePasses and Developer Products with descriptions, icon IDs, and in-game perks.
]]

export type GamePassData = {
    Id: number,
    Name: string,
    Price: number, -- Robux guide price
    Description: string,
    PerkType: "DoubleExp" | "DoubleCharges" | "LuckySpins" | "VIPMaster",
    Icon: string,
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
            Id = 0, -- Replace with real Gamepass ID from Creator Hub
            Name = "2x EXP & Leveling",
            Price = 249,
            Description = "Permanently doubles all Level experience gains from raids and combat.",
            PerkType = "DoubleExp",
            Icon = "rbxassetid://1840218341",
        },
        DoubleCharges = {
            Id = 0, -- Replace with real Gamepass ID
            Name = "2x Charges Booster",
            Price = 199,
            Description = "Earn double Charges (+20 per raid instead of +10) up to 10,000 cap.",
            PerkType = "DoubleCharges",
            Icon = "rbxassetid://3356359494",
        },
        LuckySpins = {
            Id = 0, -- Replace with real Gamepass ID
            Name = "Lucky Element Spins",
            Price = 399,
            Description = "Doubles the chance of rolling secret elements (Error & Time) on every spin!",
            PerkType = "LuckySpins",
            Icon = "rbxassetid://1839806527",
        },
        VIPMaster = {
            Id = 0, -- Replace with real Gamepass ID
            Name = "VIP: Element Master",
            Price = 499,
            Description = "Exclusive golden chat tag, +200 starting health bonus, and VIP ambient aura.",
            PerkType = "VIPMaster",
            Icon = "rbxassetid://6296105178",
        },
    } :: { [string]: GamePassData },

    PRODUCTS = {
        Spins_1 = {
            Id = 0,
            Name = "1x Element Spin",
            Price = 49,
            Description = "Grants 1 instant element spin ticket.",
            SpinsAwarded = 1,
            Icon = "rbxassetid://1840218341",
        },
        Spins_5 = {
            Id = 0,
            Name = "5x Element Spins",
            Price = 199,
            Description = "Grants 5 instant element spin tickets (20% bonus value).",
            SpinsAwarded = 5,
            Icon = "rbxassetid://1839806527",
        },
        Spins_10 = {
            Id = 0,
            Name = "10x Element Spins Bundle",
            Price = 349,
            Description = "Grants 10 instant element spin tickets (Mega bundle).",
            SpinsAwarded = 10,
            Icon = "rbxassetid://6296105178",
        },
    } :: { [string]: DevProductData },
}

return table.freeze(ShopConfig)
