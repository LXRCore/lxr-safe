--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SAFE — Shared rules
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRSafe = LXRSafe or {}
local S = LXRSafe

local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2) end

---May a safe stand here? Returns false, reason when not.
function S.MayStand(pos, safes)
    for _, t in ipairs(Config.Safe.towns or {}) do if dist(pos, t.coords) <= t.radius then return false, 'town' end end
    for _, s in pairs(safes or {}) do if dist(pos, s) < Config.Safe.spacing then return false, 'too_close' end end
    return true
end

---A clean combination or nil.
function S.Code(code)
    code = tostring(code or ''):gsub('%D', '')
    if #code < Config.Safe.code.min or #code > Config.Safe.code.max then return nil end
    return code
end

---Who may open: owner, the right combination, or a safe still open from a pick.
function S.MayOpen(safe, citizenid, code, now)
    if safe.citizenid == citizenid then return true, 'owner' end
    if safe.broken then return true, 'broken' end
    if safe.open_until and now <= safe.open_until then return true, 'picked' end
    if safe.code and code and tostring(code) == safe.code then return true, 'code' end
    return false
end

function S.StashId(safe) return ('safe:%d'):format(safe.id) end
