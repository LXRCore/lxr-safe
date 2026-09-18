<img src="https://raw.githubusercontent.com/LXRCore/.github/main/profile/lxrcore-logo.png" alt="LXRCore" width="72" align="left" style="margin-right:12px">

# lxr-safe — An iron safe, for LXRCore

Use the `safe_kit` item and an iron safe stands where you put it. The
owner sets the combination; whoever knows it opens it; whoever does not
can work the lock with a pick (through lxr-lockpick) or blow the door
with dynamite — a blown safe is a broken safe, open to all. Safes live on
the server and survive restarts; every one is an lxr-inventory stash.

There is no interface of its own: the safe speaks through lxr-interact
prompts, lxr-nui dialogs (the dial), lxr-lockpick and the inventory.

## What it does

* **Place / pack up** — the owner, `perPlayer` safes, `spacing` apart, out of `towns` if listed; packing up needs it empty and not blown.
* **The dial** — `Config.Safe.code` digits; *Open* asks anyone who is not the owner for the numbers.
* **The pick** — `Config.Break.pick`: needs the item, runs the lxr-lockpick minigame, leaves the door open `openMinutes` on success; a broken pick is lost.
* **Dynamite** — `Config.Break.dynamite`: the stick is taken, a fuse runs, the door is blown; the safe stays broken (open to everyone) until the owner leaves it.
* **The law** — picks and blasts may raise a call through lxr-dispatch.
* **Not verified in game** — the safe prop name; a model that fails `IsModelValid` is skipped and the safe is marked by its prompt.
* **Events** — `lxr:safe:placed / opened / picked / blown`.

## Install

```cfg
ensure lxr-core
ensure lxr-nui
ensure lxr-inventory
ensure lxr-interact
ensure lxr-lockpick   # optional: the pick
ensure lxr-safe
```

The table `lxr_safes` is created by the core migration runner. The core catalog carries `safe_kit`.

## API

| Name | Side | Purpose |
|---|---|---|
| `Safes(citizenid?)` | server | every safe, or one owner's |
| `Remove(id)` | server | take a safe down |
| `Safes()` | client | what this client knows |

## Licence

© 2026 iBoss21 / LXRCore — All Rights Reserved. See `LICENSE`.
