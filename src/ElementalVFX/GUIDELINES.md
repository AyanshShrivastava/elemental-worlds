# Elemental Worlds VFX

Client-side visual effects for all 36 abilities (M1 included) across 7 elements.
Animations are not included; these are visuals only. Damage, collision, cooldowns, and
movement belong to the server.

## Files

| File | Purpose |
|---|---|
| `Core.lua` | Shared helpers (parts, emitters, beams, rings, timing). |
| `Dispatcher.lua` | The one module you call: `VFX.Play(element, move, ctx)`. |
| `Aqua.lua` | Water element |
| `Fire.lua` | Fire element |
| `Earth.lua` | Earth element |
| `Light.lua` | Light element |
| `Wind.lua` | Wind element |
| `Error.lua` | Error element (secret) |
| `Time.lua` | Time element (secret) |

## Studio setup

1. In **ReplicatedStorage**, insert a **Folder** named `ElementalVFX`.
2. Insert a **ModuleScript** inside it for each file above. Name each one exactly as the file
   (`Core`, `Dispatcher`, `Aqua`, `Fire`, `Earth`, `Light`, `Wind`, `Error`, `Time`) and paste the contents.
3. Make a **LocalScript** in **StarterPlayer > StarterPlayerScripts** to test:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VFX = require(ReplicatedStorage:WaitForChild("ElementalVFX").Dispatcher)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local target = root.Position + root.CFrame.LookVector * 25 -- test point in front

VFX.Play("Aqua", "M1", { character = character, target = target })
VFX.Play("Fire", "Move1", { character = character, target = target })
```

Each call takes `{ character = ..., target = Vector3, direction = Vector3?, duration = number?, radius = number?, targetCharacter = Model?, targets = {Model}? }`.
Any field left out gets a sensible default (see `Core.context`).

## Ability list (in order)

| # | Element | Ability | Call | Notes |
|---|---|---|---|---|
| 1 | Aqua | M1 Water | `Play("Aqua","M1")` | Two compressed streams |
| 2 | Aqua | Move 1 Water Hand | `Play("Aqua","Move1")` | Gather, advance, slam |
| 3 | Aqua | Move 2 Vortex of Destruction | `Play("Aqua","Move2")` | Spinning sphere |
| 4 | Aqua | Move 3 Water Dragon | `Play("Aqua","Move3")` | **Returns handle**: `:End(hitPos)` |
| 5 | Aqua | Move 4 Limitless Punches | `Play("Aqua","Move4")` | `punches` option, default 14 |
| 6 | Fire | M1 Flame Dagger | `Play("Fire","M1")` | |
| 7 | Fire | Move 1 Scorching Fireball | `Play("Fire","Move1")` | |
| 8 | Fire | Move 2 Infernal Beast | `Play("Fire","Move2")` | **Returns handle**: `:Attack(pos)`, `:Despawn()` |
| 9 | Fire | Move 3 Flames of Fury | `Play("Fire","Move3")` | |
| 10 | Fire | Move 4 Infernal Judgement | `Play("Fire","Move4")` | Domain: `Fire.DOMAIN` (radius 16, 10s, 1s fade) |
| 11 | Earth | M1 Earth Sword | `Play("Earth","M1")` | |
| 12 | Earth | Move 1 Earthy Wall | `Play("Earth","Move1")` | **Returns handle**: `:SetHealth(0..1)`, `:Shatter()`, `:End()`. Settings in `Earth.WALL` |
| 13 | Earth | Move 2 Boulder of Destruction | `Play("Earth","Move2")` | |
| 14 | Earth | Move 3 Accelerated Earth Punch | `Play("Earth","Move3")` | |
| 15 | Earth | Move 4 The Master of Terra | `Play("Earth","Move4")` | 3-second timed sequence |
| 16 | Light | M1 Dim Light Ray | `Play("Light","M1")` | |
| 17 | Light | Move 1 Amplified Light | `Play("Light","Move1")` | |
| 18 | Light | Move 2 Mirrors of Judgement | `Play("Light","Move2")` | Five mirrors, bounce ray, slam |
| 19 | Light | Move 3 Blinding Attack | `Play("Light","Move3")` | 2s glow on the target's head, no screen flash |
| 20 | Light | Move 4 Divine Light Amplification | `Play("Light","Move4")` | 1.2s charge, then release |
| 21 | Wind | M1 Compressed Wind | `Play("Wind","M1")` | Lightning bolt projectile |
| 22 | Wind | Move 1 Airy Vortex | `Play("Wind","Move1")` | Rotating cone |
| 23 | Wind | Move 2 Cyclone of Fury | `Play("Wind","Move2")` | `radius` (default 14), `duration` (default 5) |
| 24 | Wind | Move 3 Maximum Speed | `Play("Wind","Move3")` | Rings and speed trail |
| 25 | Wind | Move 4 Wind: Death Speed | `Play("Wind","Move4")` | 4.4-second sequence, no map changes |
| 26 | Error | M1 Glitched Dash | `Play("Error","M1")` | `dashDistance` (default 18) |
| 27 | Error | Move 1 Chaotic Destruction | `Play("Error","Move1")` | |
| 28 | Error | Move 2 404 Not Found | `Play("Error","Move2")` | `radius` for the AoE shell |
| 29 | Error | Move 3 Got Glitched | `Play("Error","Move3")` | **Returns handle**: `:End()`. Client-only hide |
| 30 | Error | Move 4 Spatial Distortion | `Play("Error","Move4")` | **Returns handle**: `:End()`. `arenaCFrame` option |
| 31 | Error | Move 5 Unparalleled | `Play("Error","Move5")` | `targets` list of models |
| 32 | Time | M1 Time Punch | `Play("Time","M1")` | |
| 33 | Time | Move 1 Got Throwed | `Play("Time","Move1")` | Hold visual is 0.5s |
| 34 | Time | Move 2 Time Injection | `Play("Time","Move2")` | No graphic imagery |
| 35 | Time | Move 3 Untouchable | `Play("Time","Move3")` | **Returns handle**: `:Hit()`, `:End()`. `duration` default 4 |
| 36 | Time | Move 4 Virtual Kill | `Play("Time","Move4")` | No graphic imagery |

Error Meter (not an ability): `require(...Error).Meter(character, pct)` shows the meter above the head.

## Handles

Moves that stay alive return a table of functions. Call them with colon syntax:

```lua
local dragon = VFX.Play("Aqua", "Move3", { character = character })
-- when the server confirms a hit:
dragon:End(hitPosition)
-- if it just times out, nothing else is needed
```

## Notes

- Visuals are client-only. Have the server send the result (hit position, health change, etc.),
  then call the matching handle function on the client.
- Earth Move1 wall collision: the visual parts use `Earth.WALL.collidable`, but blocking must be
  enforced by the server too.
- Fire Move4 domain, Error Move3 invisibility, and Time Move3 shield timing are all server-enforced.
  The client only draws them.
- Test it in Studio first. These files were written without running them in Studio, so expect a small
  round of fixes on the first run.
