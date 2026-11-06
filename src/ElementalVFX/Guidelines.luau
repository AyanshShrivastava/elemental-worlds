--!strict
--[[
    ===========================================================================
    ELEMENTAL WORLDS — VFX ARCHITECTURE & IMPLEMENTATION GUIDELINES
    ===========================================================================
    Client-side visual effects for all 36 abilities (M1 included) across 7 elements.
    Animations are visual only. Damage, collision, cooldowns, and movement belong to server.

    STRUCTURE:
    ReplicatedStorage
      └─ ElementalVFX
           ├─ Core            (Shared math, parts, emitters, beams, rings, timing)
           ├─ Dispatcher      (Unified entry: VFX.Play(element, move, ctx))
           ├─ Aqua            (5 abilities: M1, Move1..Move4)
           ├─ Fire            (5 abilities: M1, Move1..Move4)
           ├─ Earth           (5 abilities: M1, Move1..Move4)
           ├─ Light           (5 abilities: M1, Move1..Move4)
           ├─ Wind            (5 abilities: M1, Move1..Move4)
           ├─ Error           (6 abilities: M1, Move1..Move5)
           ├─ Time            (5 abilities: M1, Move1..Move4)
           └─ Guidelines      (This documentation module)

    API USAGE:
        local VFX = require(ReplicatedStorage.ElementalVFX.Dispatcher)
        local handle = VFX.Play("Aqua", "Move3", {
            character = character,
            target = targetPosition,
            direction = directionVector,
            duration = 5,
        })

    LIFECYCLE HANDLES:
    Moves that persist in world space return a lifecycle handle table:
    1. Aqua Move3 (Water Dragon):
       handle:End(hitPos)  -- bursts droplets at hitPos
       handle:End()        -- gracefully dissolves
    2. Fire Move2 (Infernal Beast):
       handle:Attack(targetPos) -- creature dashes and strikes
       handle:Despawn()         -- creature disperses into ash
    3. Earth Move1 (Earthy Wall):
       handle:SetHealth(0..1)   -- fractures wall progressively
       handle:Shatter()         -- explodes into rock fragments
       handle:End()             -- sinks into ground
    4. Error Move3 (Got Glitched):
       handle:End()             -- reappears and restores transparency
    5. Error Move4 (Spatial Distortion):
       handle:End()             -- collapses glitch domain
    6. Time Move3 (Untouchable):
       handle:Hit()             -- ripple wave when hit
       handle:End()             -- dissolves time barrier

    TOTAL ABILITIES: 36
    ---------------------------------------------------------------------------
    AQUA (5):
      - M1: Water (Two compressed forward streams)
      - Move1: Water Hand (Summon translucent hand, advance, ground slam)
      - Move2: Vortex of Destruction (High-speed spinning water sphere)
      - Move3: Water Dragon (Dragon wrap; returns handle :End(hitPos))
      - Move4: Aqua Limitless Punches (14 rapid water strikes with afterimages)

    FIRE (5):
      - M1: Flame Dagger (Short-range flaming dagger slash with ember arc)
      - Move1: Scorching Fireball (Rotating flame core projectile with impact burst)
      - Move2: Infernal Beast (Fire NPC summon; returns handle :Attack(), :Despawn())
      - Move3: Flames of Fury (Teleport behind target + concentrated fire beam)
      - Move4: Infernal Judgement (Domain boundary, rising flame pillars)

    EARTH (5):
      - M1: Earth Sword (Rocky blade slash with stone debris)
      - Move1: Earthy Wall (Summons 3-pillar wall; returns handle :SetHealth(), :Shatter(), :End())
      - Move2: Boulder of Destruction (Massive rotating boulder launch)
      - Move3: Accelerated Earth Punch (Rock gauntlet dash + ground crater)
      - Move4: The Master of Terra (3-stage tectonic cataclysm sequence)

    LIGHT (5):
      - M1: Dim Light Ray (High-speed laser beam with lens flare)
      - Move1: Amplified Light (Concentrated solar blast)
      - Move2: Mirrors of Judgement (5 pentagonal mirrors, bouncing ray, orbital strike)
      - Move3: Blinding Attack (Radiant flash + target halo)
      - Move4: Divine Light Amplification (Ascension charge + divine orbital bombardment)

    WIND (5):
      - M1: Compressed Wind (Piercing aerodynamic lightning bolt)
      - Move1: Airy Vortex (Expanding swirling wind cone)
      - Move2: The Cyclone of Fury (Updraft whirlwind tornado)
      - Move3: Maximum Speed (Aero condensation rings + high-speed dash trails)
      - Move4: Wind Death Speed (Multi-angle supersonic slash blitz)

    ERROR (6):
      - M1: Glitched Dash (Chromatic aberration jitter teleport)
      - Move1: Chaotic Destruction (RGB split energy sphere explosion)
      - Move2: 404 Not Found (Corrupted data dome + matrix rain)
      - Move3: Got Glitched (Stealth digital desync; returns handle :End())
      - Move4: Spatial Distortion (Domain expansion; returns handle :End())
      - Move5: Unparalleled (Multi-target digital slash execution)

    TIME (5):
      - M1: Time Punch (Clock dial burst + temporal delay impact)
      - Move1: Got Throwed (Temporal stasis suspension + accelerated launch)
      - Move2: Time Injection (Chronos needle barrage + delayed explosion)
      - Move3: Untouchable (Time dilation barrier; returns handle :Hit(), :End())
      - Move4: Virtual Kill (Monochrome world stop + shattered timeline climax)
    ---------------------------------------------------------------------------
]]

local Guidelines = {
    Version = "2.0.0",
    TotalAbilities = 36,
    Elements = {
        "Aqua", "Fire", "Earth", "Light", "Wind", "Error", "Time"
    },
    AbilityMap = {
        Aqua = { "M1", "Move1", "Move2", "Move3", "Move4" },
        Fire = { "M1", "Move1", "Move2", "Move3", "Move4" },
        Earth = { "M1", "Move1", "Move2", "Move3", "Move4" },
        Light = { "M1", "Move1", "Move2", "Move3", "Move4" },
        Wind = { "M1", "Move1", "Move2", "Move3", "Move4" },
        Error = { "M1", "Move1", "Move2", "Move3", "Move4", "Move5" },
        Time = { "M1", "Move1", "Move2", "Move3", "Move4" },
    },
    Handles = {
        ["Aqua.Move3"] = { "End(hitPos)" },
        ["Fire.Move2"] = { "Attack(targetPos)", "Despawn()" },
        ["Earth.Move1"] = { "SetHealth(fraction)", "Shatter()", "End()" },
        ["Error.Move3"] = { "End()" },
        ["Error.Move4"] = { "End()" },
        ["Time.Move3"] = { "Hit()", "End()" },
    }
}

function Guidelines.GetSummary(): string
    return string.format("Elemental Worlds VFX System: %d Elements, %d Abilities fully registered.", #Guidelines.Elements, Guidelines.TotalAbilities)
end

return table.freeze(Guidelines)
