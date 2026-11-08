# Nanobots: Early Bots 3.0

**Your personal construction, repair, and defense assistant — no roboport network required!**

Why wait for a full robotics network?

Nanobots bring automated construction, repairs, and factory maintenance to the early game. Equip your **Nano Emitter**, load it with nano ammunition, and let your tiny helpers take care of repetitive tasks while you focus on expanding your factory.

Nanobots3 builds on the original Nanobots concept with enhanced automation, intelligent ammunition management, quality support, multiplayer improvements, and performance optimizations.

---

## Latest Update — 5.9.12 (Factorio 2.1)

Thermite ammunition can now consume natural rocks without returning resources. Disable **Termites eat rocks** in **Settings → Mod Settings → Map** to preserve rocks while continuing to clear trees. Enabled by default; rocks marked for deconstruction are preserved.

### Upgrade Fixes — 5.9.10

- Fixed missing returned items when upgrading buildings from remote/map view, including while seated in a vehicle.
- Construction uses your physical character and vehicle inventories, including connected cargo wagons, rather than the remote camera.
- Remote camera inactivity no longer pauses construction through the AFK check.

The upgrade fix passed nine automated checks in Factorio 2.1.24, covering red-to-blue belts, fast-to-bulk inserters, cars, spidertrons, stationary trains, vehicle materials, and the remote-view AFK timeout.

## Key Features

### Construction & Repair

- Automatically build ghost entities and blueprints
- Repair damaged structures using Nano Construction Bots; no separate repair packs are required in inventory in Factorio 2.1, v5.9.9+
- Automate tile placement (toggle **Nanobots build tiles** in **Settings → Mod Settings → Map**)
- Work without a roboport or logistic network
- Use portable nanobots wherever your character goes
- Quality-aware item handling

### Nano Emitter & Ammunition

- Use different nano ammunition types for different tasks
- **Quick Ammo Switching (Alt+T)** — switch between Nano Construction Bots and Thermite ammo
- Automatically load Nano Construction Bots into an empty ammo slot, or Thermite ammo if construction bots are unavailable
- Check your inventory before switching ammunition
- Preserve ammunition quality and partially used magazines when switching
- Display a message when compatible ammunition is unavailable

**Smarter Low-Ammo Warnings**

Nanobots3 checks your available ammunition reserves instead of relying only on the currently equipped magazine.

- Counts matching ammunition in your inventory
- Avoids unnecessary warnings when additional ammunition is available
- Keeps different ammunition types and qualities separate
- Provides configurable visual and audio alerts

*Quick switching and inventory-aware ammunition warnings are available in the Factorio 2.1 branch, starting with Nanobots3 5.9.5, with further fixes in later releases.*

### Vehicle Automation

- Automatically refuel vehicles
- Manage vehicle ammunition
- Install modules where applicable
- Reduce repetitive inventory management

### Automatic Turret Defense

Keep your defenses supplied without constant manual intervention.

- Automatically deliver ammunition to turrets
- Support gun turrets and artillery
- Configure refill thresholds and delivery amounts
- Prioritize ammunition by damage and quality
- Choose between powerful ammunition and economical alternatives
- Receive warnings about incompatible ammunition
- Optional delivery sounds and visual feedback

### Intelligent Combat Automation

**Combat Priority Mode**

Use stronger ammunition when enemies are nearby and conserve valuable ammunition during peaceful periods.

**Automatic Defense Activation**

Automatically enable or disable supported defense automation based on enemy presence.

**Adaptive Scanning**

Adjust scanning activity according to combat conditions to reduce unnecessary processing.

**Statistics Dashboard (Alt+H)**

Track automation activity through a dedicated interface, including session and lifetime statistics and ammunition-related information.

---

## Quick Start

1. Research the required Nanobots technology.
2. Craft a **Nano Emitter**.
3. Craft **Nano Construction Bots** or other supported nano ammunition.
4. Equip the Nano Emitter in a weapon slot.
5. Load your ammunition into the corresponding ammo slot.
6. Start building — your nanobots will help automatically!

Use **Alt+N** to visualize the working area.

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **Alt+N** | Toggle working-area visualization |
| **Alt+G** | Toggle automatic defense |
| **Alt+H** | Open/close the statistics dashboard |
| **Alt+T** | Switch Nano Construction Bots / Thermite ammo (Factorio 2.1, v5.9.5+) |

A quick-access toolbar button is also available for ammunition switching in supported versions.

---

## Configuration

Nanobots3 includes configurable settings to match your playstyle and factory requirements.

### Per-Player Settings

- Turret refill thresholds
- Ammunition delivery quantities
- Ammunition damage priority
- Ammunition quality priority
- Combat Priority Mode
- Automatic defense activation
- Low-ammunition warning thresholds
- Warning sounds and notification intervals

### Global Settings

- Scanning frequency and performance settings
- Maximum turrets processed per scan
- Nanobot behavior inside logistic networks
- Debug logging options

---

## Performance & Multiplayer

Nanobots3 includes several optimizations designed to reduce scripting overhead in large factories.

- Consolidated tick processing
- Reduced logging in frequently executed operations
- Filtered entity searches
- Cached configuration values
- Optimized lookup structures
- Adaptive scanning intervals
- Multiplayer-aware task distribution

The mod is intended for both single-player factories and multiplayer servers, including large modded environments.

---

## Factorio Version Compatibility

**Factorio 2.1 — Nanobots3 5.9.x**

The actively developed branch, including the latest automation improvements and Nano Emitter ammunition switching.

- Factorio 2.1 compatibility
- Embedded stdlib components — no separate stdlib2 dependency required
- Quality system support
- Space Age compatibility
- Continued bug fixes and feature improvements

**Legacy Factorio 2.0 releases (5.8.x) are archived and no longer maintained.** They remain in Downloads for existing saves. Current fixes and features are released for **Factorio 2.1 / Nanobots3 5.9.x**. Upgrade Factorio to use the maintained branch.

### Additional Compatibility

- Space Age DLC
- Multiplayer and dedicated servers
- Quality system
- Compatible turret mods
- Space Exploration compatibility depends on its Factorio 2.1 version and the installed modpack
- English and Russian localization

Compatibility with large overhaul modpacks may vary depending on their specific versions and configuration. Please report reproducible issues on the Discussion page.

---

## Troubleshooting & Bug Reports

Found a bug or unexpected behavior?

Please report it in the **Discussion** section and include:

- Factorio version
- Nanobots3 version
- Other relevant mods or modpack
- Exact error message or relevant log excerpt
- Steps to reproduce the issue, if possible

Detailed reports and testing feedback help improve compatibility and stability.

For commonly asked questions, see the [FAQ page](https://mods.factorio.com/mod/Nanobots3/faq).

---

## Credits

**Original Nanobots mod created by Nexela.**

Nanobots3 continues the project with compatibility updates, new automation features, additional configuration options, and ongoing maintenance.

Thanks to the Factorio community for bug reports, testing, suggestions, and contributions that help keep the mod improving!

**Build smarter. Repair faster. Defend automatically.**
