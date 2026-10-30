# Elemental Worlds ⚔️🌪️🔥

An anime-inspired open-world Roblox combat RPG built in high-performance, strictly typed **Luau** (`--!strict`).

---

## 🌟 Game Highlights

- **7 Elements & 36 Unique Abilities**:
  - **Fire**: Flame Dagger (M1), Scorching Fireball, Infernal Beast, Flames of Fury, Infernal Judgement Domain.
  - **Aqua**: Water (M1), Water Hand, Vortex of Destruction, Water Dragon Transformation, Aqua: Limitless Punches.
  - **Earth**: Earth Sword (M1), Earthy Wall, Boulder of Destruction, Accelerated Earth Punch, The Master of Terra Cinematic.
  - **Light**: Dim Light Ray (M1), Amplified Light, Mirrors of Judgement, Blinding Attack, Divine Light Amplification.
  - **Wind**: Compressed Wind (M1), Airy Vortex, The Cyclone of Fury, Maximum Speed Boost, Wind: Death Speed Cinematic.
  - **Error (Secret)**: Glitched Dash (M1), Chaotic Destruction, 404 Not Found, Got Glitched (Invulnerability), Spatial Distortion Domain (50% Meter), Unparalleled Freeze (100% Meter).
  - **Time (Secret)**: Time Punch (M1), Got Throwed, Time Injection, Untouchable (Attack Absorber), Virtual Kill (150s Instant KO).
- **Server-Authoritative Combat**:
  - **Directional Hit Detection**: Targets behind or outside the attack cone never take damage merely for being nearby.
  - Reusable spatial hitbox queries supporting nested NPC folders.
  - Additive level scaling: `Damage Multiplier = 1 + 0.025 * (Level - 1)`. At Level 300: `8.475x` multiplier.
- **RNG & Element Spin System**:
  - Standard Spin Probabilities: Fire (19.96%), Aqua (19.96%), Earth (19.96%), Light (19.96%), Wind (19.96%), Error (0.10%), Time (0.10%).
  - **First 5,000 Players Special Allocation**: One-time 50/50 secret claim between Error or Time tracked atomically in DataStore.
  - Owner-only RNG controls (`/setrng`, `/resetrng`, `/testrng`).
- **Owner & Admin Systems**:
  - Owner (`coolzgamer9`, UserId `6225357795`) authenticated strictly by numeric UserId.
  - Protected from admin kicks, bans, or demotions.
- **Mobile Friendly HUD**:
  - Responsive Top Bar (Level 1-300, Health, Charges 0-10,000).
  - Cooldown countdown overlays and active Error Meter bar.
  - Automatic touch controls with safe-area margins.

---

## 📂 Repository Layout

```text
├── default.project.json    # Rojo build / sync configuration
├── ROBLOX_SETUP_GUIDE.md   # Step-by-step setup instructions for map & animations
├── src/
│   ├── shared/             # ReplicatedStorage.Shared
│   │   ├── Config/         # GameConfig, AbilityConfig, AdminConfig
│   │   └── Modules/        # CombatHelper, AnimationMarkerUtil, StatusEffectTypes
│   ├── server/             # ServerScriptService.ElementalWorlds
│   │   ├── ServerMain.server.luau
│   │   ├── Services/       # PlayerData, Cooldown, Hitbox, StatusEffect, RNG, Admin, Raid
│   │   └── Elements/       # Fire, Aqua, Earth, Light, Wind, Error, Time
│   └── client/             # StarterPlayer.StarterPlayerScripts
│       ├── ClientMain.client.luau
│       └── Controllers/    # CombatController, UIController, MobileController, VFXController
```

---

## 🚀 How to Run & Sync

### Using Rojo
```bash
rojo serve
```
Connect via the **Rojo plugin in Roblox Studio** to sync all scripts in real time.

### Manual Setup
Refer to [ROBLOX_SETUP_GUIDE.md](ROBLOX_SETUP_GUIDE.md) for direct copy-paste instructions into Roblox Studio services.

---

## 📜 Credits
- **Game Design, Map, VFX, Animations**: `coolzgamer9`
- **Lead Luau Systems Programming**: Google Antigravity
