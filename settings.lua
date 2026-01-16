data:extend{
{
    type = "bool-setting",
    name = "nanobots-nanobots-auto",
    setting_type = "runtime-global",
    default_value = true,
    order = "nanobots-aa[auto-bots-roll-out]"
},
{
    type = "bool-setting",
    name = "nanobots-active-emitter-mode",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "nanobots-aa[mode]"
},
{
    type = "bool-setting",
    name = "nanobots-equipment-auto",
    setting_type = "runtime-global",
    default_value = true,
    order = "nanobots-ab[poll-rate]"
},
{
    type = "bool-setting",
    name = "nanobots-nano-build-tiles",
    setting_type = "runtime-global",
    default_value = true,
    order = "nanobots-ba[build-tiles]"
},
{
    type = "bool-setting",
    name = "nanobots-nano-fullfill-requests",
    setting_type = "runtime-global",
    default_value = true,
    order = "nanobots-bb"
},
{
    type = "bool-setting",
    name = "nanobots-network-limits",
    setting_type = "runtime-global",
    default_value = true,
    order = "nanobots-ca[check-networks]"
},
{
    name = "nanobots-afk-time",
    type = "int-setting",
    setting_type = "runtime-global",
    default_value = 4,
    maximum_value = 6060,
    minimum_value = 0,
    order = "nanobots-da",
},
{
    type = "int-setting",
    name = "nanobots-nano-poll-rate",
    setting_type = "runtime-global",
    default_value = 60,
    maximum_value = 6060,
    minimum_value = 1,
    order = "nanobots-ea[nano-poll-rate]"
},
{
    type = "int-setting",
    name = "nanobots-nano-queue-per-cycle",
    setting_type = "runtime-global",
    default_value = 100,
    maximum_value = 800,
    minimum_value = 1,
    order = "nanobots-eb[nano-queue-rate]"
},
{
    type = "int-setting",
    name = "nanobots-nano-queue-rate",
    setting_type = "runtime-global",
    default_value = 12,
    maximum_value = 6060,
    minimum_value = 4,
    order = "nanobots-ec[nano-queue-rate]"
},
{
    type = "int-setting",
    name = "nanobots-cell-queue-rate",
    setting_type = "runtime-global",
    default_value = 5,
    maximum_value = 6060,
    minimum_value = 1,
    order = "nanobots-fa[cell-queue-rate]"
},
{
    type = "int-setting",
    name = "nanobots-free-bots-per",
    setting_type = "runtime-global",
    default_value = 50,
    maximum_value = 100,
    minimum_value = 1,
    order = "nanobots-fb[free-bots-per]"
},
{
    type = "string-setting",
    name = "nanobots-log-level",
    setting_type = "runtime-global",
    default_value = "off",
    allowed_values = {"off", "standard", "debug"},
    order = "nanobots-zz[log-level]"
},
{
    type = "bool-setting",
    name = "nanobots-nano-repair",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]"
},

-- ──────────────────────────────────────────────────────────────────────────
-- 4.7.0: Repair improvements settings
-- ──────────────────────────────────────────────────────────────────────────

{
    type = "string-setting",
    name = "nanobots-repair-start-threshold",
    setting_type = "runtime-global",
    default_value = "1.00",
    allowed_values = {"1.00","0.95","0.90","0.85","0.80","0.75","0.70","0.65","0.60","0.55","0.50"},
    order = "a[nanobots]-r[repair]-a[threshold]"
},
{
    type = "int-setting",
    name = "nanobots-repair-max-sessions",
    setting_type = "runtime-global",
    default_value = 15,
    minimum_value = 1,
    maximum_value = 200,
    order = "a[nanobots]-r[repair]-b[max-sessions]"
},
{
    type = "int-setting",
    name = "nanobots-repair-hp-per-action",
    setting_type = "runtime-global",
    default_value = 20,
    minimum_value = 1,
    maximum_value = 300,
    order = "a[nanobots]-r[repair]-c[hp-per-action]"
},
{
    type = "int-setting",
    name = "nanobots-repair-requeue-delay",
    setting_type = "runtime-global",
    default_value = 20,
    minimum_value = 1,
    maximum_value = 180,
    order = "a[nanobots]-r[repair]-d[requeue-delay]"
},
{
    type = "int-setting",
    name = "nanobots-repair-throttle-ticks",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 0,
    maximum_value = 3600,
    order = "a[nanobots]-r[repair]-e[throttle]"
},
{
    type = "bool-setting",
    name = "nanobots-repair-combat-important-only",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]-f[combat-important-only]"
},
{
    type = "int-setting",
    name = "nanobots-repair-combat-enemy-radius",
    setting_type = "runtime-global",
    default_value = 32,
    minimum_value = 0,
    maximum_value = 256,
    order = "a[nanobots]-r[repair]-g[combat-enemy-radius]"
},
{
    type = "int-setting",
    name = "nanobots-repair-combat-recent-damage-seconds",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 600,
    order = "a[nanobots]-r[repair]-h[combat-recent-damage]"
},

-- Категории ремонта (галочки)
{
    type = "bool-setting",
    name = "nanobots-repair-cat-defense",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]-i[cat]-a[defense]"
},
{
    type = "bool-setting",
    name = "nanobots-repair-cat-transport",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]-i[cat]-b[transport]"
},
{
    type = "bool-setting",
    name = "nanobots-repair-cat-power",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]-i[cat]-c[power]"
},
{
    type = "bool-setting",
    name = "nanobots-repair-cat-production",
    setting_type = "runtime-global",
    default_value = true,
    order = "a[nanobots]-r[repair]-i[cat]-d[production]"
},
{
    type = "bool-setting",
    name = "nanobots-repair-cat-other",
    setting_type = "runtime-global",
    default_value = false,
    order = "a[nanobots]-r[repair]-i[cat]-e[other]"
}
}