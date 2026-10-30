--!strict
--[[
    Elemental Worlds: Status Effect Definitions
]]

export type StatusEffectName = 
    | "Stunned"          -- Movement and normal attack locked
    | "Untouchable"      -- Invulnerable to incoming hits (Time Move 3)
    | "GotGlitched"      -- Invisible and immune to damage and stuns (Error Move 3)
    | "TimeStopped"      -- Complete animation and physics pause (Time Moves 1 & 2)
    | "Blinded"          -- Screen obscured (Light Move 3)
    | "WaterDragon"      -- Temporary transformation (Aqua Move 3)
    | "DomainTrapped"    -- Trapped in circular domain (Fire Move 4 / Error Move 4)
    | "SpeedBoost"       -- Increased walkspeed (Wind Move 3)
    | "UnparalleledStun" -- Error Move 5 total freeze

export type ActiveEffect = {
    Name: StatusEffectName,
    StartTime: number,
    Duration: number,
    EndTime: number,
    SourcePlayer: Player?,
    Data: { [string]: any }?,
}

return {}
