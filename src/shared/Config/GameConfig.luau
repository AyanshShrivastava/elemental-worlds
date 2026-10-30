--!strict
--[[
    Elemental Worlds: Master Game Configuration
    Contains central constants, progression scaling, RNG weights, and owner credentials.
]]

export type ElementType = "Fire" | "Aqua" | "Earth" | "Light" | "Wind" | "Error" | "Time"

local GameConfig = {
    -- Owner Authorization (coolzgamer9)
    OWNER_USER_ID = 6225357795 :: number,
    OWNER_USERNAME = "coolzgamer9" :: string,

    -- Progression Limits
    MAX_LEVEL = 300 :: number,
    MAX_CHARGES = 10000 :: number,

    -- Scaling Formulas
    BASE_HEALTH = 100 :: number,
    HEALTH_PER_LEVEL = 10 :: number,
    ATTACK_PER_LEVEL = 10 :: number,

    -- Multiplier Formula: 1 + 0.025 * (Level - 1)
    DAMAGE_MULTIPLIER_RATE = 0.025 :: number,

    -- Raid Progression
    RAID_LEVEL_REWARD = 3 :: number,
    RAID_CHARGES_REWARD = 10 :: number,

    -- Combat Settings
    M1_COMBO_WINDOW = 1.2 :: number,       -- Seconds between M1 hits to keep combo
    M1_COMBO_MAX = 4 :: number,             -- Max M1 hits per combo
    M1_ENDLAG = 0.25 :: number,             -- Endlag after M1 combo finishes
    HITBOX_DURATION = 0.15 :: number,       -- How long melee hitboxes stay active

    -- Normal Element RNG Weights (Total = 1.0 or 100%)
    SPIN_RATES = {
        Fire = 0.1996,   -- 19.96%
        Aqua = 0.1996,   -- 19.96%
        Earth = 0.1996,  -- 19.96%
        Light = 0.1996,  -- 19.96%
        Wind = 0.1996,   -- 19.96%
        Error = 0.0010,  -- 0.10% (Secret)
        Time = 0.0010,   -- 0.10% (Secret)
    } :: { [ElementType]: number },

    -- Lucky Spins doubles secret rates
    LUCKY_SPIN_MULTIPLIER = 2.0 :: number,

    -- Special First 5,000 Secret Roll Allocation
    SECRET_ALLOCATION_MAX_PLAYERS = 5000 :: number,

    -- Auto-save interval (seconds)
    AUTO_SAVE_INTERVAL = 90 :: number,

    -- Remote Event Names
    REMOTES = {
        CAST_ABILITY = "CastAbility",
        ABILITY_EVENT = "AbilityEvent",
        UPDATE_STATS = "UpdateStats",
        ROLL_ELEMENT = "RollElement",
        ELEMENT_ROLLED = "ElementRolled",
        GLOBAL_ANNOUNCEMENT = "GlobalAnnouncement",
        VFX_TRIGGER = "VFXTrigger",
        SOUND_TRIGGER = "SoundTrigger",
        ADMIN_COMMAND = "AdminCommand",
        OPEN_SHOP = "OpenShop",
        PURCHASE_ITEM = "PurchaseItem",
        MAP_TELEPORT = "MapTeleport",
        FRAGMENT_COLLECTED = "FragmentCollected",
    },

    -- Safe Map Folders
    FOLDERS = {
        NPCS = "NPCs",
        VFX = "VFX",
        SPAWNS = "SpawnLocations",
        MAP = "Map",
    },

    -- World definitions
    WORLDS = {
        {
            Id = "World1",
            Name = "Ember Highlands",
            Unlocked = true,
            RequiredFragments = 0,
            Description = "The starting world — a vast anime-styled highland filled with ancient ruins and rival warriors.",
        },
        {
            Id = "World2",
            Name = "Abyssal Depths",
            Unlocked = false,
            RequiredFragments = 4,
            Description = "A sunken underwater world glowing with bioluminescent life and powerful ocean-element enemies.",
        },
        {
            Id = "World3",
            Name = "Celestial Void",
            Unlocked = false,
            RequiredFragments = 8,
            Description = "A space between dimensions where time bends and Error-element entities roam.",
        },
    },

    -- Gamepass IDs (fill in after creating in Creator Hub)
    GAMEPASS_IDS = {
        DoubleExp     = 0,  -- Replace with real ID from Creator Hub
        DoubleCharges = 0,  -- Replace with real ID from Creator Hub
        LuckySpins    = 0,  -- Replace with real ID from Creator Hub
        VIPMaster     = 0,  -- Replace with real ID from Creator Hub
        SpeedBoost    = 0,  -- Replace with real ID from Creator Hub
    },

    -- Developer Product IDs (fill in after creating in Creator Hub)
    PRODUCT_IDS = {
        Spins_1  = 0,
        Spins_5  = 0,
        Spins_10 = 0,
    },
}

-- Calculate max health for a given level
function GameConfig.GetMaxHealth(level: number): number
    local clampedLevel = math.clamp(level, 1, GameConfig.MAX_LEVEL)
    return GameConfig.BASE_HEALTH + ((clampedLevel - 1) * GameConfig.HEALTH_PER_LEVEL)
end

-- Calculate damage multiplier: 1 + 0.025 * (Level - 1)
function GameConfig.GetDamageMultiplier(level: number): number
    local clampedLevel = math.clamp(level, 1, GameConfig.MAX_LEVEL)
    return 1 + (GameConfig.DAMAGE_MULTIPLIER_RATE * (clampedLevel - 1))
end

-- Final damage = BaseDamage * multiplier
function GameConfig.CalculateDamage(baseDamage: number, level: number): number
    local mult = GameConfig.GetDamageMultiplier(level)
    return math.round(baseDamage * mult)
end

return table.freeze(GameConfig)
