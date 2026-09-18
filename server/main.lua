--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SAFE — Server: the safes live here
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRSafe
local RES = GetCurrentResourceName()
local safes, buckets = {}, {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function near(src, p)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - vector3(p.x, p.y, p.z)) <= Config.Security.maxDistance
end
local function lawOnDuty()
    for _, P in pairs(LXRCore.Players) do local def = LXRShared.Jobs[P.PlayerData.job.name] if def and (def.type == 'leo' or def.type == 'federal') and P.PlayerData.job.onduty then return true end end
    return false
end
local function public(s, cid) return { id = s.id, x = s.x, y = s.y, z = s.z, heading = s.heading, mine = s.citizenid == cid, broken = s.broken == true, hasCode = s.code ~= nil, openUntil = s.open_until } end
local function save(s) LXRCore.DB.UpdateAsync('UPDATE lxr_safes SET code = ?, broken = ?, open_until = ? WHERE id = ?', { s.code, s.broken and 1 or 0, s.open_until or 0, s.id }) end
local function broadcast(s) TriggerClientEvent('lxr-safe:client:update', -1, { id = s.id, x = s.x, y = s.y, z = s.z, heading = s.heading, owner = s.citizenid, broken = s.broken == true, hasCode = s.code ~= nil, openUntil = s.open_until }) end
local function remove(id, why)
    local s = safes[id]
    if not s then return end
    safes[id] = nil
    LXRCore.DB.UpdateAsync('DELETE FROM lxr_safes WHERE id = ?', { id })
    TriggerClientEvent('lxr-safe:client:remove', -1, id, why)
end
local function mine(cid) local n = 0 for _, s in pairs(safes) do if s.citizenid == cid then n = n + 1 end end return n end
local function stashOpts(s) return { label = Lang:t('ui.safe'), slots = Config.Safe.slots, weight = Config.Safe.weight } end

LXRCore.DB.RegisterMigration(RES, '0001_safes', [[
CREATE TABLE IF NOT EXISTS `lxr_safes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL, `heading` FLOAT NOT NULL DEFAULT 0,
  `code` VARCHAR(8) NULL,
  `broken` TINYINT(1) NOT NULL DEFAULT 0,
  `open_until` INT NOT NULL DEFAULT 0,
  `placed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

CreateThread(function()
    Wait(1000)
    local rows = LXRCore.DB.Query('SELECT id, citizenid, x, y, z, heading, code, broken, open_until FROM lxr_safes') or {}
    for _, r in ipairs(rows) do safes[r.id] = { id = r.id, citizenid = r.citizenid, x = r.x, y = r.y, z = r.z, heading = r.heading, code = r.code, broken = r.broken == 1, open_until = r.open_until } end
    if Config.Debug.printBanner then print(('^1[lxr-safe]^7 v%s — %d safes standing'):format(GetResourceMetadata(RES, 'version', 0), #rows)) end
end)

LXRCore.Items.RegisterUsable(Config.Safe.item, function(src) TriggerClientEvent('lxr-safe:client:place', src) end)

LXR.RPC.Register('lxr-safe:place', function(src, x, y, z, heading)
    if limited(src) then return false, 'rate' end
    local P = player(src)
    if not P or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return false, 'invalid' end
    local pos = { x = x, y = y, z = z }
    if not near(src, pos) then return false, 'too_far' end
    local okS, why = S.MayStand(pos, safes)
    if not okS then return false, why end
    if mine(P.PlayerData.citizenid) >= Config.Safe.perPlayer then return false, 'too_many' end
    if not P.Functions.RemoveItem(Config.Safe.item, 1, nil, 'safe:place') then return false, 'no_kit' end
    local id = LXRCore.DB.Insert('INSERT INTO lxr_safes (citizenid, x, y, z, heading) VALUES (?, ?, ?, ?, ?)', { P.PlayerData.citizenid, x, y, z, tonumber(heading) or 0.0 })
    local s = { id = id, citizenid = P.PlayerData.citizenid, x = x, y = y, z = z, heading = tonumber(heading) or 0.0, broken = false, open_until = 0 }
    safes[id] = s
    broadcast(s)
    LXRCore.Emit('lxr:safe:placed', nil, src, id)
    return true, id
end)

LXR.RPC.Register('lxr-safe:open', function(src, id, code)
    if limited(src) then return false, 'rate' end
    local P, s = player(src), safes[tonumber(id) or 0]
    if not P or not s then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    local may, how = S.MayOpen(s, P.PlayerData.citizenid, code, os.time())
    if not may then return false, s.code and 'wrong_code' or 'locked' end
    if GetResourceState('lxr-inventory') ~= 'started' then return false, 'invalid' end
    exports['lxr-inventory']:OpenInventory(src, 'stash', S.StashId(s), stashOpts(s))
    LXRCore.Emit('lxr:safe:opened', nil, src, id, how)
    return true
end)

LXR.RPC.Register('lxr-safe:manage', function(src, id, what, arg)
    if limited(src) then return false, 'rate' end
    local P, s = player(src), safes[tonumber(id) or 0]
    if not P or not s then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if s.citizenid ~= P.PlayerData.citizenid then return false, 'not_yours' end
    if what == 'code' then
        if arg == '' or arg == nil then s.code = nil else local c = S.Code(arg) if not c then return false, 'bad_code' end s.code = c end
        save(s) broadcast(s)
    elseif what == 'pickup' then
        if s.broken then return false, 'broken' end
        local items = GetResourceState('lxr-inventory') == 'started' and exports['lxr-inventory']:GetStashItems(S.StashId(s)) or {}
        if #items > 0 then return false, 'not_empty' end
        if not LXRCore.Inventory.CanCarry(src, Config.Safe.item, 1) then return false, 'too_heavy' end
        P.Functions.AddItem(Config.Safe.item, 1, nil, nil, 'safe:pickup')
        remove(s.id, 'pickup')
    else return false, 'invalid' end
    return true
end)

-- the pick: lxr-lockpick reports here
RegisterNetEvent('lxr-safe:server:pick', function(id)
    local src = source
    if limited(src) or not Config.Break.pick.enabled then return end
    local P, s = player(src), safes[tonumber(id) or 0]
    if not P or not s or s.broken then return end
    if not near(src, s) then return end
    if s.citizenid == P.PlayerData.citizenid then return end
    if LXRCore.Inventory.GetItemCount(src, Config.Break.pick.item) < 1 then return LXRCore.Notify(src, Lang:t('error.no_pick', { label = LXRShared.Items[Config.Break.pick.item].label }), 'error') end
    TriggerClientEvent('lxr-lockpick:client:start', src, { door = 'safe:' .. s.id, label = Lang:t('ui.safe'), report = Config.Break.pick.report })
end)
RegisterNetEvent(Config.Break.pick.report, function(door, broke)
    local src = source
    local id = tonumber(tostring(door):match('^safe:(%d+)$') or '')
    local P, s = player(src), id and safes[id]
    if not P or not s then return end
    if not near(src, s) then return end
    if broke then
        P.Functions.RemoveItem(Config.Break.pick.item, 1, nil, 'safe:pick broke')
        return LXRCore.Notify(src, Lang:t('error.pick_broke'), 'warning')
    end
    s.open_until = os.time() + Config.Break.pick.openMinutes * 60
    save(s) broadcast(s)
    LXRCore.Log.info('safe', ('safe %d picked'):format(s.id), { source = src, owner = s.citizenid })
    LXRCore.Emit('lxr:safe:picked', nil, src, s.id, s.citizenid)
    if Config.Break.callLaw.enabled and math.random() < Config.Break.callLaw.chance and GetResourceState('lxr-dispatch') == 'started' and lawOnDuty() then
        exports['lxr-dispatch']:Raise({ kind = Config.Break.callLaw.kind, coords = vector3(s.x, s.y, s.z), title = Lang:t('call.safe'), message = Lang:t('call.safe_msg') })
    end
    LXRCore.Notify(src, Lang:t('info.picked', { n = Config.Break.pick.openMinutes }), 'success')
end)

-- dynamite: the client lights it; the server takes the stick, waits the fuse, breaks the safe and dumps it
LXR.RPC.Register('lxr-safe:blow', function(src, id)
    if limited(src) or not Config.Break.dynamite.enabled then return false, 'invalid' end
    local P, s = player(src), safes[tonumber(id) or 0]
    if not P or not s or s.broken then return false, 'invalid' end
    if not near(src, s) then return false, 'too_far' end
    if not P.Functions.RemoveItem(Config.Break.dynamite.item, 1, nil, 'safe:dynamite') then return false, 'no_dynamite', LXRShared.Items[Config.Break.dynamite.item].label end
    TriggerClientEvent('lxr-safe:client:fuse', -1, s.id, Config.Break.dynamite.fuseSeconds)
    SetTimeout(Config.Break.dynamite.fuseSeconds * 1000, function()
        local cur = safes[s.id]
        if not cur then return end
        cur.broken = true cur.code = nil
        save(cur) broadcast(cur)
        TriggerClientEvent('lxr-safe:client:blown', -1, cur.id, Config.Break.dynamite.radius)
        LXRCore.Log.info('safe', ('safe %d blown'):format(cur.id), { source = src, owner = cur.citizenid })
        LXRCore.Emit('lxr:safe:blown', nil, src, cur.id, cur.citizenid)
        if Config.Break.callLaw.enabled and GetResourceState('lxr-dispatch') == 'started' and lawOnDuty() then
            exports['lxr-dispatch']:Raise({ kind = Config.Break.callLaw.kind, coords = vector3(cur.x, cur.y, cur.z), title = Lang:t('call.blast'), message = Lang:t('call.blast_msg') })
        end
    end)
    return true
end)

RegisterNetEvent('lxr-safe:server:ready', function()
    local src = source
    local list = {}
    for _, s in pairs(safes) do list[#list + 1] = { id = s.id, x = s.x, y = s.y, z = s.z, heading = s.heading, owner = s.citizenid, broken = s.broken == true, hasCode = s.code ~= nil, openUntil = s.open_until } end
    TriggerClientEvent('lxr-safe:client:sync', src, list)
end)

AddEventHandler('playerDropped', function() buckets[source] = nil end)
exports('Safes', function(cid) local out = {} for _, s in pairs(safes) do if not cid or s.citizenid == cid then out[#out + 1] = public(s, cid) end end return out end)
exports('Remove', function(id) remove(tonumber(id), 'export') end)
