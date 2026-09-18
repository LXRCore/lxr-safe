--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SAFE — Client: the safe you can see, the dial, the fuse
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local S = LXRSafe
local N = Citizen.InvokeNative
local safes, props, busy = {}, {}, false

local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end
local function citizenid() local d = LXRCore.Functions.GetPlayerData() return d and d.citizenid end
local function work(ms)
    busy = true
    local ped = PlayerPedId()
    N(0x524B54361229154F, ped, joaat(Config.Work.scenario), ms, true, false, false, false)
    Wait(ms)
    ClearPedTasks(ped)
    busy = false
end
local function ask(title, fields, cb) exports['lxr-nui']:Input({ title = title, fields = fields }, function(v) if v then cb(v) end end) end

local function despawn(id)
    local e = props[id]
    if not e then return end
    exports['lxr-interact']:Remove('lxr-safe:' .. id)
    if e ~= true and DoesEntityExist(e) then DeleteEntity(e) end
    props[id] = nil
end

local function options(s)
    local id = s.id
    local isMine = function() local c = safes[id] return c and c.owner == citizenid() end
    return {
        { label = Lang:t('ui.open'), key = 'J', canInteract = function() return not busy end, onSelect = function()
            local c = safes[id]
            if not c then return end
            if isMine() or c.broken or (c.openUntil and c.openUntil > 0) then
                local ok, err = LXR.RPC.Server('lxr-safe:open', id)
                if not ok then if err == 'locked' or err == 'wrong_code' then askCode(id) else toast('error.' .. tostring(err), 'error') end end
            else askCode(id) end
        end },
        { label = Lang:t('ui.set_code'), key = 'G', canInteract = function() return isMine() and not busy end, onSelect = function()
            ask(Lang:t('ui.set_code'), { { id = 'code', label = Lang:t('ui.code_hint'), type = 'number' } }, function(v)
                work(Config.Work.dialMs)
                local ok, err = LXR.RPC.Server('lxr-safe:manage', id, 'code', tostring(v.code or ''))
                if not ok then toast('error.' .. tostring(err), 'error') else toast('info.code_set', 'success') end
            end)
        end },
        { label = Lang:t('ui.pickup'), key = 'E', canInteract = function() return isMine() and not busy end, onSelect = function()
            local ok, err = LXR.RPC.Server('lxr-safe:manage', id, 'pickup')
            if not ok then toast('error.' .. tostring(err), 'error') else toast('info.picked_up', 'info') end
        end },
        { label = Lang:t('ui.pick'), key = 'R', item = Config.Break.pick.item, canInteract = function() local c = safes[id] return Config.Break.pick.enabled and c and not c.broken and not isMine() and not busy end, onSelect = function() TriggerServerEvent('lxr-safe:server:pick', id) end },
        { label = Lang:t('ui.blow'), key = 'X', item = Config.Break.dynamite.item, canInteract = function() local c = safes[id] return Config.Break.dynamite.enabled and c and not c.broken and not busy end, onSelect = function()
            local ok, err, extra = LXR.RPC.Server('lxr-safe:blow', id)
            if not ok then toast('error.' .. tostring(err), 'error', { label = extra }) end
        end },
    }
end
function askCode(id)
    ask(Lang:t('ui.code'), { { id = 'code', label = Lang:t('ui.code_hint'), type = 'number' } }, function(v)
        work(Config.Work.dialMs)
        local ok, err = LXR.RPC.Server('lxr-safe:open', id, tostring(v.code or ''))
        if not ok then toast('error.' .. tostring(err), 'error') end
    end)
end

local function spawn(s)
    despawn(s.id)
    local hash = joaat(Config.Safe.prop)
    local label = s.broken and Lang:t('ui.safe_broken') or Lang:t('ui.safe')
    if IsModelValid(hash) then
        RequestModel(hash)
        local t = GetGameTimer() + 3000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if HasModelLoaded(hash) then
            local e = CreateObject(hash, s.x, s.y, s.z, false, false, false)
            SetEntityHeading(e, s.heading or 0.0)
            PlaceObjectOnGroundProperly(e)
            FreezeEntityPosition(e, true)
            SetModelAsNoLongerNeeded(hash)
            props[s.id] = e
            exports['lxr-interact']:AddEntity('lxr-safe:' .. s.id, e, { label = label, distance = Config.Security.promptDistance, options = options(s) })
            return
        end
    end
    props[s.id] = true
    exports['lxr-interact']:AddPoint('lxr-safe:' .. s.id, vector3(s.x, s.y, s.z), { label = label, distance = Config.Security.promptDistance, options = options(s) })
end

RegisterNetEvent('lxr-safe:client:sync', function(list) for id in pairs(props) do despawn(id) end safes = {} for _, s in ipairs(list) do safes[s.id] = s end end)
RegisterNetEvent('lxr-safe:client:update', function(s) local old = safes[s.id] safes[s.id] = s if props[s.id] and (not old or old.broken ~= s.broken) then spawn(s) end end)
RegisterNetEvent('lxr-safe:client:remove', function(id) despawn(id) safes[id] = nil end)
RegisterNetEvent('lxr-safe:client:fuse', function(id, seconds) local s = safes[id] if s and #(GetEntityCoords(PlayerPedId()) - vector3(s.x, s.y, s.z)) < 40.0 then toast('info.fuse', 'warning', { n = seconds }) end end)
RegisterNetEvent('lxr-safe:client:blown', function(id, radius)
    local s = safes[id]
    if not s then return end
    if #(GetEntityCoords(PlayerPedId()) - vector3(s.x, s.y, s.z)) < 200.0 then AddExplosion(s.x, s.y, s.z + 0.5, 0, 1.0, true, false, 1.0) end
end)

RegisterNetEvent('lxr-safe:client:place', function()
    if busy then return end
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then return toast('error.dismount', 'error') end
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.2, 0.0)
    local ok, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    if not ok then return toast('error.invalid', 'error') end
    local spot = { x = pos.x, y = pos.y, z = z }
    local may, why = S.MayStand(spot, safes)
    if not may then return toast('error.' .. why, 'error') end
    work(Config.Work.placeMs)
    local res, err = LXR.RPC.Server('lxr-safe:place', spot.x, spot.y, spot.z, GetEntityHeading(ped))
    if not res then return toast('error.' .. tostring(err), 'error') end
    toast('info.placed', 'success')
end)

CreateThread(function()
    while GetResourceState('lxr-interact') ~= 'started' do Wait(1000) end
    while true do
        if LocalPlayer.state.isLoggedIn then
            local pos = GetEntityCoords(PlayerPedId())
            for id, s in pairs(safes) do
                local d = #(pos - vector3(s.x, s.y, s.z))
                if d <= Config.Security.propRange and not props[id] then spawn(s) elseif d > Config.Security.propRange + 20.0 and props[id] then despawn(id) end
            end
        end
        Wait(2000)
    end
end)
RegisterNetEvent('lxr:client:loaded', function() Wait(1500) TriggerServerEvent('lxr-safe:server:ready') end)
RegisterNetEvent('lxr:client:unloaded', function() for id in pairs(props) do despawn(id) end safes = {} end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for id in pairs(props) do despawn(id) end end end)
CreateThread(function() Wait(2000) if LocalPlayer.state.isLoggedIn then TriggerServerEvent('lxr-safe:server:ready') end end)
exports('Safes', function() return safes end)
