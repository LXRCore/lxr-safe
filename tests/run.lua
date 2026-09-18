--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SAFE — Offline tests: placement, combinations, who may open, locale parity
     Usage (from the lxr-safe folder):  lua tests/run.lua
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE) os.exit(2) end
local Shim = require('tests.lib.fxshim')
for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil Locale = nil
Shim.load('shared/locale.lua') Shim.load('locales/en.lua') Shim.load('locales/ka.lua') Shim.load('config.lua') Shim.load('shared/rules.lua')
local S = LXRSafe

local passed, failed = 0, 0
local function test(name, fn) local okT, err = xpcall(fn, debug.traceback) if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-safe offline tests')
test('the items exist in the catalog', function()
    assert(LXRShared.Items[Config.Safe.item], Config.Safe.item)
    assert(LXRShared.Items[Config.Break.pick.item] and LXRShared.Items[Config.Break.dynamite.item])
end)
test('placement and combinations', function()
    assert(S.MayStand({ x = 0, y = 0, z = 0 }, {}))
    local okC, why = S.MayStand({ x = 0, y = 0, z = 0 }, { { x = 1, y = 0, z = 0 } }) assert(not okC) eq(why, 'too_close')
    eq(S.Code('12-34'), '1234') assert(S.Code('12') == nil) assert(S.Code('1234567') == nil) assert(S.Code('') == nil)
end)
test('who may open: owner, code, a picked door, a blown door', function()
    local s = { citizenid = 'A', code = '4711', open_until = 0 }
    assert(S.MayOpen(s, 'A', nil, 100)) assert(S.MayOpen(s, 'B', '4711', 100)) assert(not S.MayOpen(s, 'B', '0000', 100)) assert(not S.MayOpen(s, 'B', nil, 100))
    s.open_until = 200 assert(S.MayOpen(s, 'B', nil, 150)) assert(not S.MayOpen(s, 'B', nil, 201))
    s.broken = true assert(S.MayOpen(s, 'C', nil, 999))
    eq(S.StashId({ id = 7 }), 'safe:7')
end)
test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)
print(('%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
