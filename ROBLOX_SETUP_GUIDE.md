# Elemental Worlds — Roblox Studio Setup & Designer Guide

Welcome to the **Elemental Worlds** codebase! This guide is written specifically for you (the game designer) so you can easily link your maps, animations, sound effects, and VFX to the programming systems without needing to write complex Luau code.

---

## 1. Project Structure in Roblox Studio

When you sync with **Rojo** or place the files manually in Roblox Studio, they map to the following services:

```text
ReplicatedStorage/
  └── Shared/
        ├── Config/
        │     ├── GameConfig.luau        (Level caps, formulas, RNG rates, owner ID)
        │     ├── AbilityConfig.luau     (All 36 abilities, cooldowns, damage, animation IDs)
        │     └── AdminConfig.luau       (Owner & Admin command permissions)
        └── Modules/
              ├── CombatHelper.luau      (Directional cone math, aim check, damage scaling)
              ├── AnimationMarkerUtil.luau (Animation marker & fallback player)
              └── StatusEffectTypes.luau (Invulnerability, stuns, domains)

ServerScriptService/
  └── ElementalWorlds/
        ├── ServerMain.server.luau       (Master server script)
        ├── Services/
        │     ├── PlayerDataService.luau (Level 1-300, health scaling, charges, saving)
        │     ├── CooldownService.luau   (Server-authoritative cooldown timer)
        │     ├── HitboxService.luau     (Directional hit detection, nested NPC support)
        │     ├── StatusEffectService.luau (Untouchable, GotGlitched, stuns, domains)
        │     ├── RNGSystem.luau         (19.96% / 0.10% spins, 5k secret allocation)
        │     ├── CombatService.luau     (Validates casts, checks Error meter & stuns)
        │     ├── AdminService.luau      (Commands: /givelevel, /ban, /setrng, etc.)
        │     └── RaidService.luau       (+3 Levels, +10 Charges on raid clear)
        └── Elements/
              ├── FireElement.luau       (Flame Dagger, Fireball, Infernal Beast, Fury, Domain)
              ├── AquaElement.luau       (Water, Water Hand, Vortex, Dragon, Limitless Punches)
              ├── EarthElement.luau      (Earth Sword, Earth Wall, Boulder, Earth Punch, Terra)
              ├── LightElement.luau      (Dim Ray, Amplified, Mirrors, Blind, Divine Amplification)
              ├── WindElement.luau       (Compressed Wind, Airy Vortex, Cyclone, Speed, Death Speed)
              ├── ErrorElement.luau      (Glitched Dash, Chaotic, 404, Got Glitched, Spatial, Unparalleled)
              └── TimeElement.luau       (Time Punch, Got Throwed, Injection, Untouchable, Virtual Kill)

StarterPlayer/
  └── StarterPlayerScripts/
        └── ElementalWorldsClient/
              ├── ClientMain.client.luau (Master client loader)
              └── Controllers/
                    ├── CombatController.luau (Input handling: Mouse, Keys 1-5, Touch)
                    ├── UIController.luau     (Top HUD, Cooldown countdowns, Error Meter)
                    ├── MobileController.luau (Right-side touch attack buttons)
                    └── VFXController.luau    (Client-side screen shakes & Blind effects)

Workspace/
  ├── Map/               (Your build: Village, Forest, Mountains, Caves, Ruins)
  ├── NPCs/              (All enemy NPCs, can be in nested folders!)
  ├── VFX/               (Domain barriers, temporary visual models)
  └── SpawnLocations/    (Player spawn points)
```

---

## 2. How to Add Your Animations

Open `ReplicatedStorage/Shared/Config/AbilityConfig.luau`.
Every ability has an entry like this:

```lua
["1"] = {
    Id = "Fire_1",
    Name = "Scorching Fireball",
    Element = "Fire",
    Slot = "1",
    BaseDamage = 35,
    Cooldown = 6.0,
    Range = 60,
    ConeAngle = 60,
    AnimationId = "rbxassetid://YOUR_ANIMATION_ID_HERE", -- <-- Paste your Animation Asset ID
    AnimationMarker = "Launch",                          -- <-- Name of Keyframe marker in Animation
},
```

> **Safety Fallback**: If you leave `AnimationId = "rbxassetid://0"` or your marker name isn't reached, the system will **automatically trigger the fallback timer** so the attack still executes smoothly and never gets stuck!

---

## 3. Map Placement & Folder Setup

Create the following folders inside `Workspace`:
- `Workspace/Map`
  - Put all map geometry, buildings, roads, and landscape here.
  - Can have subfolders: `Village`, `Forest`, `Mountains`, `Caves`, `Ruins`.
- `Workspace/NPCs`
  - Put your enemy and boss models here.
  - Subfolders are **fully supported** (e.g. `Workspace/NPCs/ForestEnemies/Goblin`).
  - Each NPC just needs a `Humanoid` and a `HumanoidRootPart`.
- `Workspace/VFX`
  - Holds temporary domain spheres and visual effects.

---

## 4. Owner & Admin Commands

Your account (**coolzgamer9**, UserId **6225357795**) is hardcoded as the **Immutable Owner**:
- You cannot be kicked, banned, or demoted by admins.
- Type these in the in-game chat bar:

### Owner-Only Commands:
- `/setrng Fire 0.1` — Adjust spin rates in real-time.
- `/resetrng` — Reset spin rates to standard 19.96% / 0.10%.
- `/addadmin [username]` — Grant admin powers to a player.
- `/removeadmin [username]` — Revoke admin powers.
- `/ban [username]` — Ban a player from the game.
- `/unban [username]` — Lift a player's ban.
- `/kick [username]` — Kick a player from the server.
- `/kill [username]` — Eliminate a player.
- `/tp [username]` — Teleport to a player.
- `/bring [username]` — Teleport a player to you.
- `/setcharges [username] [amount]` — Set player charges (0 - 10,000).

### Admin Commands (Admins & Owner):
- `/givelevel [username] [amount]` — Add levels (+1 to +300).
- `/removelevel [username] [amount]` — Deduct levels.
- `/setlevel [username] [level]` — Set exact level.
- `/givecharges [username] [amount]` — Add charges.
- `/removecharges [username] [amount]` — Deduct charges.
- `/giveelement [username] [Element]` — Give element (`Fire`, `Aqua`, `Earth`, `Light`, `Wind`, `Error`, `Time`).
- `/announce [message]` — Broadcast a global banner announcement to all players.

---

## 5. Mobile & Tablet Controls
The UI automatically detects touch screens:
- Shows a dedicated **Mobile Attack (M1)** button on the right side.
- Ability buttons in the hotbar (M1, 1, 2, 3, 4, 5) are large touch targets.
- Cooldowns display live countdown numbers over each button.
