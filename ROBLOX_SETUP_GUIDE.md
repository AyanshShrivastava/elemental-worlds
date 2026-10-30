# Elemental Worlds — Complete Development Guide

## Project Structure

```
elemental-worlds/
├── default.project.json        — Rojo project config (sync to Studio)
├── src/
│   ├── client/                 — LocalScripts (runs on each player's device)
│   │   ├── ClientMain.client.luau      — Master client entry point
│   │   └── Controllers/
│   │       ├── UIController.luau           — Anime HUD, health bar, combo, cooldowns
│   │       ├── CombatController.luau       — M1 combo, ability casting input
│   │       ├── CameraShakeController.luau  — Trauma-based camera shake
│   │       ├── MobileController.luau       — Mobile touch buttons
│   │       ├── VFXController.luau          — Client-side VFX spawner
│   │       ├── AdminPanelController.luau   — Creator/Admin panel (P key)
│   │       ├── SpinUIController.luau       — Gacha spin UI
│   │       ├── ShopUIController.luau       — Robux shop UI (passes + bundles)
│   │       ├── ProceduralAnimController.luau— Run/idle animation blending
│   │       ├── DamageNumbersController.luau — 3D floating damage numbers
│   │       └── SoundController.luau        — Audio playback helper
│   ├── server/                 — Scripts (runs on server only)
│   │   ├── ServerMain.server.luau          — Master server entry point
│   │   ├── Elements/                       — Element ability implementations
│   │   │   ├── FireElement.luau
│   │   │   ├── AquaElement.luau
│   │   │   ├── EarthElement.luau
│   │   │   ├── LightElement.luau
│   │   │   ├── WindElement.luau
│   │   │   ├── ErrorElement.luau
│   │   │   └── TimeElement.luau
│   │   └── Services/
│   │       ├── PlayerDataService.luau      — Save/Load with DataStore + auto-save
│   │       ├── CombatService.luau          — Server-side damage, hitboxes
│   │       ├── CooldownService.luau        — Server-side cooldown tracking
│   │       ├── HitboxService.luau          — Directional hitbox casting
│   │       ├── RNGSystem.luau              — Element spin RNG with weights
│   │       ├── AdminService.luau           — Slash command admin system
│   │       ├── MapService.luau             — Procedural world generation
│   │       ├── MonetizationService.luau    — Gamepass + product handling
│   │       ├── CreatorPerksService.luau    — Modern prestige badge, astral aura, VIP badge
│   │       ├── RaidService.luau            — Raid lobby and progression
│   │       └── StatusEffectService.luau    — Burn, freeze, stun management
│   ├── shared/                 — ModuleScripts accessible by both client & server
│   │   ├── Config/
│   │   │   ├── GameConfig.luau             — Central constants, RNG, world defs
│   │   │   ├── AbilityConfig.luau          — All 7 elements × 5 abilities
│   │   │   ├── AdminConfig.luau            — Admin usernames, owner-only cmds
│   │   │   └── ShopConfig.luau             — Gamepass & product definitions
│   │   └── Modules/
│   │       ├── CombatHelper.luau           — Damage calculation shared logic
│   │       ├── VFXHelper.luau              — VFX spawning patterns
│   │       ├── StatusEffectTypes.luau      — Type definitions for status effects
│   │       └── AnimationMarkerUtil.luau    — Animation event helpers
│   └── gui/                    — Static GUI assets (if any)
```

---

## Quick Setup in Roblox Studio

### Step 1: Install Rojo
1. Download Rojo plugin for Studio: https://rojo.space/
2. Install the VS Code extension or use CLI: `cargo install rojo` / download from releases

### Step 2: Sync Project
```bash
cd elemental-worlds/
rojo serve
```
Then in Studio, open the Rojo plugin and click **Connect**.

### Step 3: Configure the Place
- Open Studio > **View > Properties**
- Make sure:
  - **HttpEnabled** = ON (for API calls if needed)
  - **Studio Access to APIs** = ON for testing DataStores locally

---

## Gamepasses — REQUIRED SETUP

> The API key does not have gamepass write permissions, so passes must be created manually.

### How to Create Gamepasses:
1. Go to: https://create.roblox.com/
2. Find your experience: **Elemental Worlds**
3. Navigate to **Monetization > Game Passes**
4. Create each pass with the exact names and prices below:

| Pass Key | Display Name | Price (R$) | Benefit |
|----------|-------------|------------|---------|
| `DoubleExp` | 2x EXP Booster | 249 | All EXP gains ×2 |
| `DoubleCharges` | 2x Charges Booster | 199 | All Charge gains ×2 |
| `LuckySpins` | Lucky Element Spins | 399 | Secret element rate ×2 |
| `VIPMaster` | VIP: Element Master | 499 | +200 HP, VIP badge, Azure aura |
| `SpeedBoost` | Speed Demon | 149 | Move speed +20% |

5. After creating each pass, copy its **Pass ID** from the URL or settings page
6. Update `GameConfig.luau` → `GAMEPASS_IDS` table with the real IDs
7. Update `ShopConfig.luau` → `GAMEPASSES[passKey].Id` with the real IDs

### How to Create Developer Products (Spin Tickets):
1. Navigate to **Monetization > Developer Products**
2. Create:

| Product Key | Display Name | Price (R$) | Spins |
|-------------|-------------|------------|-------|
| `Spins_1` | 1x Element Spin | 49 | 1 |
| `Spins_5` | 5x Element Spins | 199 | 5 |
| `Spins_10` | 10x Element Spins Bundle | 349 | 10 |

3. Update `GameConfig.PRODUCT_IDS` and `ShopConfig.PRODUCTS[key].Id` with real IDs

---

## Admin Commands

> Type in chat or use the in-game Creator Panel (press **P** when logged in as coolzgamer9)

### Owner-Only Commands
| Command | Args | Description |
|---------|------|-------------|
| `/addadmin` | `<username>` | Grant admin to player |
| `/removeadmin` | `<username>` | Revoke admin |
| `/ban` | `<username>` | Permanent ban (session) |
| `/unban` | `<username>` | Unban player |
| `/kick` | `<username> [reason]` | Kick player |
| `/kill` | `<username>` | Kill player |
| `/tp` | `<username>` | Teleport to player |
| `/bring` | `<username>` | Bring player to you |
| `/setcharges` | `<username> <amount>` | Set charges |
| `/resetrng` | — | Reset RNG system |

### Admin + Owner Commands
| Command | Args | Description |
|---------|------|-------------|
| `/givelevel` | `<username> <amount>` | Add levels |
| `/removelevel` | `<username> <amount>` | Remove levels |
| `/setlevel` | `<username> <level>` | Set exact level |
| `/givecharges` | `<username> <amount>` | Add charges |
| `/removecharges` | `<username> <amount>` | Remove charges |
| `/giveelement` | `<username> <Element>` | Set element (Fire/Aqua/Earth/Light/Wind/Error/Time) |
| `/announce` | `<message>` | Global server announcement |

---

## World Fragments

Collect all 4 fragments in **Ember Highlands (World 1)** to unlock **Abyssal Depths (World 2)**:

| Fragment | Location |
|----------|----------|
| Forest Whispers | Deep in the Forest region (~-240, 6, 0) |
| Apex Peak | Summit of the Mountain (~420, 148, 0) |
| Deep Crystal | Inside the Cave (~0, 8, 460) |
| Ancient Terra | Ruins center (~-320, 6, -360) |

---

## Elements & Abilities

| Element | Slot 1 (M1) | Slot 2 (1) | Slot 3 (2) | Slot 4 (3) | Slot 5 (4) |
|---------|-------------|------------|------------|------------|------------|
| Fire | Ember Fist | Fireball | Inferno Wave | Phoenix Dash | Magma Eruption |
| Aqua | Tide Punch | Aqua Sphere | Tidal Wave | Water Prison | Tsunami |
| Earth | Stone Fist | Boulder Throw | Earthquake | Stone Fortress | Earth Titan |
| Light | Radiant Strike | Holy Beam | Flash | Blind | Divine Purge |
| Wind | Gale Punch | Wind Slash | Vacuum Burst | Storm Step | Hurricane |
| Error | Glitch Strike | Error Spike | System Crash | Data Corruption | Kernel Panic |
| Time | Chrono Punch | Timestop | Rewind | Slow Field | Temporal Collapse |

---

## Spin Drop Rates

| Element | Rate | Type |
|---------|------|------|
| Fire | 19.96% | Common |
| Aqua | 19.96% | Common |
| Earth | 19.96% | Common |
| Light | 19.96% | Common |
| Wind | 19.96% | Common |
| Error | 0.10% | Secret |
| Time | 0.10% | Secret |

**Lucky Spins gamepass doubles secret rates** to 0.20% each.

---

## Save Data Schema

Player profiles saved via `DataStoreService:GetDataStore("ElementalWorlds_PlayerData_v2")`:

```
{
    Level: number (1-300),
    Charges: number (0-10000),
    Element: ElementType,
    ClaimedSecretAllocation: boolean,
    Fragments: { [fragmentId]: boolean },
    UnlockedWorlds: { [worldId]: boolean },
    GamePasses: { [passKey]: boolean },
    SpinTickets: number,
}
```

Auto-saved every 90 seconds. Full save on player leave and server shutdown (BindToClose with 25s timeout).

---

## GitHub Repository

https://github.com/AyanshShrivastava/elemental-worlds

All source code is managed with Rojo for seamless Studio synchronization.
