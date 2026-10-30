--!strict
--[[
    Elemental Worlds: Master Game Configuration
    Contains central constants, progression scaling, RNG weights, and owner credentials.
]]

export type ElementType = "Fire" | "Aqua" | "Earth" | "Light" | "Wind" | "Error" | "Time"

local GameConfig = {
    -- Owner Authorization
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

    -- Special First 5,000 Secret Roll Allocation
    SECRET_ALLOCATION_MAX_PLAYERS = 5000 :: number,

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
    },

    -- Safe Map Folders
    FOLDERS = {
        NPCS = "NPCs",
        VFX = "VFX",
        SPAWNS = "SpawnLocations",
        MAP = "Map",
    }
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
