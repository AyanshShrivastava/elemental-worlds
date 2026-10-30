# Elemental Worlds

An anime-inspired open-world Roblox combat RPG built in high-performance, strictly typed Luau (--!strict).
Modern Blox Fruits-inspired dark aesthetic, responsive combat, multi-wave raids, and seamless monetization.

---

## Game Highlights

- **Blox Fruits Modern Dark Aesthetic**:
  - Deep obsidian-navy cards (Color3.fromRGB(12, 16, 26))
  - Dual status bars: Emerald Green Health Bar and Blox Fruits Electric Cyan Energy Bar
  - Keybind ability slots supporting [Z], [X], [C], [V] and [1], [2], [3], [4]
  - Anime Flash Step / Dash on [Q] consuming energy with visual motion lines and audio whoosh
  - Modern off-cooldown flash feedback and pop-scale damage numbers
  - Zero gold, zero rainbow loops, zero emojis

- **7 Elements & 36 Unique Abilities**:
  - **Fire**: Flame Dagger (M1), Scorching Fireball, Infernal Beast, Flames of Fury, Infernal Judgement Domain.
  - **Aqua**: Water (M1), Water Hand, Vortex of Destruction, Water Dragon Transformation, Aqua: Limitless Punches.
  - **Earth**: Earth Sword (M1), Earthy Wall, Boulder of Destruction, Accelerated Earth Punch, The Master of Terra Cinematic.
  - **Light**: Dim Light Ray (M1), Amplified Light, Mirrors of Judgement, Blinding Attack, Divine Light Amplification.
  - **Wind**: Compressed Wind (M1), Airy Vortex, The Cyclone of Fury, Maximum Speed Boost, Wind: Death Speed Cinematic.
  - **Error (Mythic Secret)**: Glitched Dash (M1), Chaotic Destruction, 404 Not Found, Got Glitched (Invulnerability), Spatial Distortion Domain (50% Meter), Unparalleled Freeze (100% Meter).
  - **Time (Mythic Secret)**: Time Punch (M1), Got Throwed, Time Injection, Untouchable (Attack Absorber), Virtual Kill (150s Instant KO).

- **Multi-Wave Elemental Raids**:
  - Portal-activated dynamic boss battles:
    - Wave 1: Corrupted Elementals
    - Wave 2: Highland Wardens
    - Wave 3: Infernal Titan with 8,000 HP and dynamic Boss Health Bar
  - Automated victory rewards: +3 Levels, +20 Charges, and +2 Spin Tickets to all participants.

- **Server-Authoritative Combat**:
  - Directional Hit Detection: Targets behind or outside the attack cone never take damage merely for being nearby.
  - Reusable spatial hitbox queries supporting nested NPC folders.
  - Additive level scaling: Damage Multiplier = 1 + 0.025 * (Level - 1). At Level 300: 8.475x multiplier.

- **RNG & Element Spin System**:
  - Standard Spin Probabilities: Fire (19.96%), Aqua (19.96%), Earth (19.96%), Light (19.96%), Wind (19.96%), Error (0.10%), Time (0.10%).
  - First 5,000 Players Special Allocation: One-time 50/50 secret claim between Error or Time tracked atomically in DataStore.
  - Mythic celebration: Void Amethyst screen pulse, camera rumble, and global announcement.

- **Creator & VIP Prestige Identity**:
  - Creator (UserId 6225357795): Modern dark obsidian overhead badge with electric indigo outline, subtle void purple body aura, and developer dashboard.
  - VIP: Sleek Royal Azure overhead badge, +200 HP, 1.2x sprint speed, priority server rank.

- **Mobile Friendly Touch HUD**:
  - Dual circular buttons on bottom right: Primary Attack (M1) and Flash Step Dash (Q).
  - Safe-area margins and clear hit targets.

---

## Repository Layout

```text
├── default.project.json    # Rojo build / sync configuration
├── ROBLOX_SETUP_GUIDE.md   # Step-by-step setup instructions for map & animations
├── src/
│   ├── shared/             # ReplicatedStorage.Shared
│   │   ├── Config/         # GameConfig, AbilityConfig, AdminConfig, ShopConfig
│   │   └── Modules/        # CombatHelper, AnimationMarkerUtil, StatusEffectTypes, VFXHelper
│   ├── server/             # ServerScriptService.ElementalWorlds
│   │   ├── ServerMain.server.luau
│   │   ├── Services/       # PlayerData, Cooldown, Hitbox, StatusEffect, RNG, Admin, Raid, Map, Monetization, CreatorPerks
│   │   └── Elements/       # Fire, Aqua, Earth, Light, Wind, Error, Time
│   └── client/             # StarterPlayer.StarterPlayerScripts
│       ├── ClientMain.client.luau
│       └── Controllers/    # CombatController, UIController, MobileController, VFXController, SpinUIController, ShopUIController, AdminPanelController, DamageNumbersController, CameraShakeController, SoundController, ProceduralAnimController
```

---

## How to Run & Sync

### Using Rojo
```bash
rojo serve
```
Connect via the Rojo plugin in Roblox Studio to sync all scripts in real time.

### Manual Setup
Refer to ROBLOX_SETUP_GUIDE.md for direct copy-paste instructions into Roblox Studio services.

---

## Credits
- Game Design, Map, VFX, Animations: coolzgamer9
- Lead Luau Systems Programming: Google Antigravity
