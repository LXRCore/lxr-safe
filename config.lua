--[[
    ██╗     ██╗  ██╗██████╗       ███████╗ █████╗ ███████╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔════╝██╔══██╗██╔════╝██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗███████╗███████║█████╗  █████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝╚════██║██╔══██║██╔══╝  ██╔══╝
    ███████╗██╔╝ ██╗██║  ██║      ███████║██║  ██║██║     ███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝

    LXR Core - Safe

    An iron safe you put down where you want it. The owner sets the
    combination; whoever knows it opens it; whoever does not can work the
    lock with a pick (lxr-lockpick) or blow the door with dynamite — a
    blown safe is a broken safe, its contents on the ground. Safes live on
    the server and survive restarts; every one is an lxr-inventory stash.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (interact points; a 2 s range loop on the client)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ THE SAFE ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Safe = {
    item = 'safe_kit',            -- placed with the item; comes back when the owner packs it up
    prop = 'p_safe01x',           -- best guess, NOT verified against the game; a model that fails IsModelValid is skipped and the safe is still marked by its prompt
    slots = 20, weight = 60000,
    perPlayer = 2,
    spacing = 2.0,
    towns = {},                   -- add { coords, radius } here to keep safes out of towns
    code = { min = 3, max = 6 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ BREAKING IN ═══════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Break = {
    pick = { enabled = true, item = 'lockpick_fine', report = 'lxr-safe:server:picked', openMinutes = 10 },  -- a picked safe stays open to everyone this long
    dynamite = { enabled = true, item = 'weapon_thrown_dynamite', fuseSeconds = 8, radius = 3.0 },               -- blows the door: broken safe, contents dropped
    callLaw = { enabled = true, chance = 0.5, kind = 'lawcall' },                                                 -- through lxr-dispatch
}

Config.Work = { placeMs = 5000, dialMs = 2500, scenario = 'WORLD_HUMAN_CROUCH_INSPECT' }
Config.Security = { rateLimit = { windowMs = 2000, burst = 6 }, maxDistance = 3.5, promptDistance = 2.0, propRange = 120.0 }
Config.Debug = { printBanner = true, log = true }
