# Welcome to the **Nanobots3 FAQ**!

Here you'll find answers to common questions about construction nanobots, Nano Emitter ammunition, automatic defense, roboports, compatibility, and performance.

---

## Termites and Rocks

From **5.9.12**, Thermite ammunition also consumes natural rocks without returning resources. Toggle **Termites eat rocks** in **Settings → Mod Settings → Map** (enabled by default). Trees are still consumed when rock removal is disabled. Rocks marked for deconstruction are left for normal mining.

## Getting Started

### Q: What do I need to start using Nanobots?

Research the required technology, craft a **Nano Emitter**, and equip it in a weapon slot. Then load compatible nano ammunition into the corresponding ammunition slot.

Nanobots can help with construction and other supported tasks without requiring a stationary roboport network.

### Q: Do I need a roboport or construction robots?

No! The main purpose of Nanobots is to provide early automated construction without requiring a traditional logistic network.

However, some additional features, such as the Roboport Interface, work with regular construction robots.

### Q: How do I see the nanobot working area?

Press **Alt+N** to toggle the working-area visualization.

A green square will show the area where your nanobots operate.

---

## Construction, Repair & Tiles

### Q: Can I see why nanobots are waiting or limit them to repairs?

In **Mod Settings → Per Player**, turn on **Show nanobot status** to see the number of queued tasks and current blockers. Turn on **Repair and turret supply only** to pause construction, upgrades, demolition, and Thermite clearing for your character while allowing repairs and existing turret supply automation.

### Q: How do I disable automatic tile placement?

Open **Settings → Mod Settings → Map** and disable **Nanobots build tiles**. This is a shared map setting, not a Per Player setting. Regular entity construction remains available.

### Q: Do repairs require separate repair packs?

In **Factorio 2.1 / Nanobots3 5.9.9+**, no separate repair packs are needed in your inventory. Repair capacity is included in Nano Construction Bots: each nano charge provides up to 30 HP of repairs, with unused capacity carried over between repair steps and targets. Nano ammunition is still consumed.

### Q: How do the speed and range upgrades progress?

Speed and range each have four levels. Level 1 uses red science, and levels 2–4 use red and green science. The default costs per branch are 100, 150, 300 and 400 research units. Enable **Legacy Nanobots research prerequisites** under **Mod Settings → Startup** to restore the original Engine, Electric engine and Robotics requirements and costs.

---

## Nano Emitter & Ammunition

### Q: How do I switch between Nano Construction Bots and Thermite ammo?

**Factorio 2.1 / Nanobots3 5.9.5+**

Press **Alt+T**, or use the ammunition-switching button in the shortcut bar.

When Nano Construction Bots are loaded, the mod attempts to switch to Thermite ammo. When Thermite ammo is loaded, it attempts to switch back to Nano Construction Bots.

The mod checks your inventory before switching. If the required ammunition is unavailable, the current ammunition remains unchanged.

### Q: Can I load ammunition using the switch button when the ammo slot is empty?

**Yes, starting with Nanobots3 5.9.7.**

Press **Alt+T** or the shortcut-bar button while the ammunition slot is empty.

The mod checks your inventory in this order:

1. **Nano Construction Bots** — loaded first if available.
2. **Thermite ammo** — loaded if construction bots are unavailable.
3. **Neither available** — displays a message explaining that compatible ammunition was not found.

This allows you to load the Nano Emitter without manually moving ammunition into the slot.

### Q: Will switching ammunition waste my remaining charges?

No. The switching feature is designed to exchange ammunition stacks rather than destroy and recreate them.

It also preserves ammunition quality and the remaining contents of partially used magazines.

### Q: Does the ammunition switch work with every weapon?

No. The feature is intended for the **Nano Emitter** and its supported construction and Thermite ammunition types.

It does not replace Factorio's normal weapon-switching mechanics.

### Q: Why does the mod say my ammunition is running low when I still have more in my inventory?

Older versions could warn based on the currently equipped ammunition stack, even when additional ammunition was available in the inventory.

**Starting with Nanobots3 5.9.5**, low-ammunition monitoring also checks reserves in your main inventory.

The check takes ammunition type and quality into account, so unrelated ammunition does not incorrectly count toward your available reserves.

### Q: When will I receive a low-ammunition warning?

Warnings depend on your configured threshold and the available ammunition of the relevant type.

For example, with a threshold of 10:

- 5 charges equipped and none in inventory: warning.
- 5 charges equipped and 100 matching charges in inventory: no warning.
- 5 construction charges equipped and only Thermite ammo in inventory: construction ammunition may still be considered low.

You can configure warning thresholds and notification intervals in the mod settings.

### Q: What does "No nano charges! Insert ammo" mean?

The Nano Emitter is equipped, but compatible ammunition is not currently loaded.

In Nanobots3 5.9.7+, press **Alt+T** to attempt loading ammunition from your inventory.

If no supported ammunition is available, you will need to craft or obtain some first.

### Q: What does "Auto-Defense paused: Termites loaded" mean?

The automatic turret-defense system requires **Nano Construction Bots**.

When Thermite or another unsupported ammunition type is loaded in the Nano Emitter, auto-defense pauses.

Switch back to Nano Construction Bots to resume supported defense operations.

### Q: How do I disable or reduce ammunition warnings?

Open **Settings → Mod Settings → Per Player**.

Depending on the warning, you can:

- Adjust the low-ammunition threshold.
- Increase the notification interval.
- Disable low-charge warnings.
- Change the incompatible-ammunition warning interval.

Available intervals include 10 seconds, 30 seconds, 1 minute, 2 minutes, 5 minutes, and Off.

---

## Automatic Turret Defense

### Q: Why aren't my turrets being refilled automatically?

Check the following:

1. Press **Alt+G** and make sure auto-defense is enabled, or configure automatic activation during combat.
2. Press **Alt+N** and confirm that the turrets are within the green working area.
3. Make sure the Nano Emitter has the correct ammunition loaded.
4. Confirm that compatible turret ammunition is available in your inventory.
5. Check the turret-related settings under **Per Player**.

Laser turrets do not use ammunition and therefore do not require ammunition deliveries.

### Q: I just placed a turret. Why is it still empty?

Empty turrets should be eligible for automatic refilling when the feature is enabled and all requirements are met.

The default refill threshold is 5 rounds.

Nanobots processes a limited number of turrets during each scan. If you place many turrets at once, it may take several cycles to service them all.

### Q: Why does the mod deliver legendary ammo instead of normal ammo?

Check:

**Settings → Per Player → Ammo Quality Priority**

- **Best Quality First:** prioritize higher-quality ammunition.
- **Worst Quality First:** prioritize lower-quality ammunition and conserve premium supplies.

### Q: Why does it use uranium magazines when I have regular magazines?

Check:

**Settings → Per Player → Ammo Type Priority**

- **Best Damage First:** prioritize the strongest compatible ammunition.
- **Worst Damage First:** prioritize weaker ammunition to conserve expensive supplies.

### Q: What is Combat Priority Mode?

Combat Priority Mode changes which ammunition the automation prioritizes.

During combat, it favors stronger ammunition. Outside combat, it follows your configured ammunition preferences.

### Q: What is Auto-Enable on Combat?

Auto-Enable on Combat controls whether automatic defense activates based on enemy presence.

The distinction is:

- **Combat Priority Mode:** determines ammunition priorities.
- **Auto-Enable on Combat:** determines when the defense system is active.

Both features can be used together or independently.

### Q: Why aren't artillery turrets being refilled?

Artillery uses separate configuration settings.

Check **Settings → Per Player → Artillery** and verify the refill threshold and available compatible ammunition.

The default artillery refill threshold is 1.

### Q: Can automatic defense affect game performance?

It can, particularly when many turrets need processing.

You can reduce the processing load through the global settings:

- Increase the scan interval.
- Reduce the maximum number of turrets processed per scan.
- Enable adaptive scanning where available.

---

## Nanobots & Roboports

### Q: Why do my nanobots stop working when regular construction robots are available?

Check the global setting:

**Disable Nanobots in Logistic Networks**

When enabled, Nanobots may defer construction tasks to the regular construction-robot system under the relevant network conditions.

This prevents unnecessary duplication of work.

Disable the setting if you prefer your nanobots to remain active alongside regular construction robots.

### Q: Can I use nanobots while wearing personal roboport equipment?

Yes, but behavior depends on the logistic-network setting and whether your personal roboport is enabled.

Try toggling your personal roboport off using Factorio's normal control or shortcut-bar button.

You can also adjust the setting that disables nanobots when regular construction robots are available.

### Q: What happens near stationary roboports?

When the option to disable nanobots in logistic networks is active, the mod may leave eligible construction tasks to regular network robots.

If you want nanobots to operate independently in those areas, review that setting.

### Q: How are Nanobots different from regular construction robots?

**Nanobots:**

- Designed for early-game construction.
- Operate around your character.
- Do not require a stationary roboport network for their main functions.
- Consume supported nano ammunition.
- Offer additional automation features.

**Regular construction robots:**

- Use personal or stationary roboport infrastructure.
- Depend on the normal construction-robot and network systems.
- Do not consume nano ammunition.

Both systems can be useful at different stages of the game.

---

## Roboport Interface

### Q: What is the Roboport Interface?

The Roboport Interface, also called the **Logistic Network Interface**, is a special combinator that allows you to automate tasks using circuit signals and regular construction robots.

Supported operations include:

- Chopping trees.
- Collecting items from the ground.
- Placing tiles.
- Deconstructing depleted mining drills.
- Collecting fish.

Connect the interface to the relevant logistic network and configure signals for the desired operations.

### Q: What does "Reserve Robots %" mean?

This setting controls how many regular construction robots are reserved for normal logistic-network tasks.

Examples:

- **0%:** the interface may use all available eligible robots.
- **50%:** approximately half are reserved.
- **100%:** all robots are reserved, effectively preventing interface operations.

This setting applies to regular construction robots, not Nano Emitter ammunition.

### Q: Does the Roboport Interface require a regular logistic network?

Yes. Unlike the portable Nano Emitter, this feature operates through a regular construction-robot network.

### Q: What should I do if the Roboport Interface produces a Lua API error?

First, confirm that you are using the appropriate Nanobots3 release for your Factorio version.

Previous compatibility updates addressed changes to Factorio's circuit-network and combinator APIs.

If the issue persists, report the exact error, Factorio version, Nanobots3 version, and a list of relevant mods.

---

## Remote View, Space Age & Mod Compatibility

### Q: Do nanobots continue working while I use Remote View?

Nanobots3 uses the character's physical position and surface when using remote-view functionality.

This allows character-based automation to continue operating around the player rather than following the remote camera.

**For Factorio 2.1, update to Nanobots3 5.9.10 or newer.** Version 5.9.10 fixes additional vehicle-inventory handling and prevents the AFK timeout from pausing construction merely because the remote camera is inactive. Nanobots work around your physical character; Remote View does not let them build at the camera location.

### Q: Why were replaced belts or inserters missing after upgrading from map view in a vehicle?

This was a bug in how fast replacement used the remote player controller. It is fixed in **Nanobots3 5.9.10 for Factorio 2.1**. The mod now uses the physical character for the replacement so the old entity's item is returned. Construction also checks the physical vehicle and connected cargo-wagon inventories for materials.

Update through Factorio's mod manager or the [Downloads page](https://mods.factorio.com/mod/Nanobots3/downloads). The fix prevents new losses; it does not automatically restore items already lost in an earlier version.

The fix passed nine automated checks in Factorio 2.1.24, including cars, spidertrons, stationary trains, trunk/cargo materials and the remote-view AFK timeout. If the issue persists, report your versions, vehicle, material inventory and reproduction steps in Discussion.

### Q: Why doesn't the working-area visualization follow my remote-view camera?

This is intentional.

The green square represents the nanobots' physical working area around your character, not the location currently displayed through Remote View.

### Q: Does Nanobots3 work with Space Age planets and space platforms?

Nanobots3 is designed to support Space Age environments and multiple surfaces.

Actual behavior can depend on character availability, the current surface, and the restrictions of specific game environments.

If you encounter a reproducible issue on a particular planet or platform, please report it.

### Q: Is Nanobots3 compatible with Space Exploration?

Nanobots3 includes physical-character remote-view handling.

Compatibility with a particular Space Exploration release also depends on the Factorio version and the other installed mods.

### Q: Does Nanobots3 work with overhaul modpacks such as Pyanodons?

Nanobots3 is intended to work with many modded environments.

However, large overhaul packs may introduce unusual entities, ammunition prototypes, recipes, or interactions.

Compatibility cannot be guaranteed for every possible mod combination.

Please report reproducible issues with your mod list and relevant logs.

---

## Versions & Dependencies

### Q: Which Nanobots3 version should I install?

Use the latest **5.9.x release for Factorio 2.1**. This is the maintained branch.

**Factorio 2.0 / Nanobots3 5.8.x is archived and no longer maintained.** Existing releases remain in Downloads for legacy saves; new fixes and features are not being backported. Upgrade Factorio to use current releases.

### Q: Do I need stdlib2?

No separate stdlib2 installation is required for the maintained **5.9.x branch**; the required components are bundled. Legacy 5.8.x archives used an external stdlib2 dependency.

### Q: Why are some features missing from my Factorio 2.0 installation?

Factorio 2.0 uses the archived 5.8.x releases. That branch is no longer maintained and does not receive current fixes or features. Upgrade to Factorio 2.1 and the latest Nanobots3 5.9.x release.

---

## Visualization & Quality

### Q: Why is the nanobot working area square instead of circular?

The mod uses square-area searches for its nanobot operations.

The green visualization reflects this processing area rather than displaying an approximate circular radius.

### Q: Does ammunition quality affect nanobot range?

Yes. Supported nano ammunition can have quality-dependent range behavior.

Higher-quality ammunition can provide increased working range, depending on the ammunition type and configuration.

### Q: Does ammunition quality affect automatic defense?

Yes. The automatic-defense system includes ammunition-quality prioritization.

You can configure whether to use higher-quality ammunition first or conserve it for later.

---

## Multiplayer & Performance

### Q: Is Nanobots3 multiplayer compatible?

Yes. Nanobots3 supports multiplayer and dedicated servers.

Player-specific automation settings and activity are handled separately where applicable.

### Q: Does Nanobots3 support dedicated Linux servers?

Yes, the mod is designed to operate in headless server environments.

If you encounter repeating Lua warnings or unusual behavior, please provide the server log and mod list so the issue can be investigated.

### Q: How much does Nanobots3 affect UPS?

Nanobots3 includes several performance optimizations, including:

- Consolidated tick processing.
- Filtered entity searches.
- Cached settings.
- Efficient lookup structures.
- Adaptive scanning.
- Multiplayer-aware processing.

Actual performance depends on factory size, active automation, mod configuration, and server hardware.

### Q: What can I do if Nanobots3 causes lag?

Try adjusting the global performance settings, particularly the scan interval and maximum number of entities processed per scan.

If performance problems persist, provide a Factorio profiler report or a reproducible save along with your mod list.

---

## Troubleshooting & Bug Reports

### Q: I updated Nanobots3 but still receive an error. What should I do?

First, verify that the installed version matches your Factorio version.

Then check whether the error occurs with only Nanobots3 and its required dependencies enabled.

If the issue persists, please create or update a discussion thread and include:

1. Factorio version.
2. Nanobots3 version.
3. Installed modpack or relevant mods.
4. Exact error message or log excerpt.
5. Steps to reproduce the issue.
6. Whether the problem occurs in a fresh world.

Screenshots and server logs are welcome.

### Q: Where can I report bugs or suggest improvements?

Use the **Discussion** section on the Nanobots3 Mod Portal page.

Feature suggestions, detailed bug reports, and testing feedback are always appreciated.

---

## Credits & License

**Original Nanobots mod by Nexela.**

Nanobots3 continues the project with compatibility updates, automation features, performance improvements, and maintenance.

**License:** MIT.

Thanks to everyone who reports issues, tests updates, and contributes ideas!
