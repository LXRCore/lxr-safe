--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SAFE — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    error = { rate = 'Slow down.', invalid = 'Not here.', too_far = 'Get closer.', town = 'Not in town.', too_close = 'Too close to another safe.', too_many = 'You have enough safes standing.', no_kit = 'You have no safe.', not_yours = 'Not your safe.', bad_code = 'A combination is three to six digits.', broken = 'The door is blown off; nothing to pack.', not_empty = 'Empty it first.', too_heavy = 'You cannot carry a safe right now.', locked = 'Locked.', wrong_code = 'The dial does not give.', no_pick = 'You need %{label}.', pick_broke = 'The pick snapped.', no_dynamite = 'You need %{label}.', dismount = 'Get down first.' },
    info = { placed = 'The safe stands.', code_set = 'The dial is set.', picked_up = 'You pack the safe up.', picked = 'The lock gives. The door stays open %{n} minutes.', fuse = 'A fuse is burning — %{n} seconds.' },
    call = { safe = 'Safe-cracking', safe_msg = 'Someone working a safe lock.', blast = 'Explosion', blast_msg = 'Dynamite. A safe, most likely.' },
    ui = { safe = 'Iron safe', safe_broken = 'Blown safe', open = 'Open', set_code = 'Set the combination', code = 'Combination', code_hint = '3–6 digits (empty removes it)', pickup = 'Pack the safe up', pick = 'Work the lock', blow = 'Set dynamite' },
})
