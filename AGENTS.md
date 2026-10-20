# Working on Glance (for AI coding assistants)

Glance is a World of Warcraft Classic addon in Lua 5.1 (the game's Lua). The addon is
`src/` (installed into the game as `AddOns/Glance/`); everything else is tooling and docs. Read `docs/ARCHITECTURE.md` before a
change that touches more than one file.

## Layout

- `src/core/`: shared table, hooks (`ns.Hook`, `ns.Listen`, `ns.EveryFrame`), saved
  settings and defaults, the redraw heartbeat.
- `src/features/`: reads the game and works things out. **Never creates frames,
  textures or font strings, and never draws.**
- `src/ui/`: draws. One file per part of the bars. `ui/widgets/` holds the shared
  building blocks.
- `src/settings/`: settings panel, Edit Mode, help mode, minimal mode, `/glance`.
- `src/dev/`: `/glance cpu` and `/glance debug`.
- `src/Glance.toc`: load order. Every .lua file must be listed. ui/ files are listed
  in the order their parts are built and drawn: append new ones, don't reorder.

## Rules

- Every file starts with `local ADDON, ns = ...` and a top comment saying what it's for,
  its setting key, and the files it works with. Keep that comment true when you change
  the file.
- Share through `ns` only. No new globals (the few the game needs are in the .luacheckrc).
- Listen to events with `ns.Listen` / `ns.ListenUnits` under one of the existing
  handler names (`"bars"`, `"timers"`, `"alerts"`, `"fight history"`, `"damage model"`)
  or `nil`. Don't create new handler names without a reason: each is a row in
  `/glance debug`.
- Per-frame code (`ns.EveryFrame`, `ns.Hook("frame", ...)`) must not call the game for
  unit data; read the fields the redraw stores (`f.hp`, `f.hpMax`, `f.exists`, `f.guid`,
  `f.dead`, `f.castInfo`...). Use `ns.Text`, `ns.Vis`, `ns.Alpha` instead of
  SetText/SetShown/SetAlpha on anything updated often.
- Protected frames (the groups, the pet button) can't be moved, resized, shown or hidden
  in combat. Check `InCombatLockdown()` and use `ns.GeometryLater()`.
- A new feature gets a key in `core/Defaults.lua` (`labels`), a checkbox in
  `settings/Panel.lua`, and a help line in `settings/Help.lua` if players see it.
- The game's Lua is 5.1: no `goto`, no integer division `//`, no `utf8`. Some clients
  lack newer API: go through `core/Compat.lua` or check the function exists first.
- Comments: plain words a player would follow, saying what and why. Don't narrate code.

## Commands to run

```
python3 tools/check.py                         # layout rules and .toc listing
python3 tools/glance-shots/shoot.py --dump=/tmp/after   # every scenario as data
python3 tools/glance-shots/compare.py /tmp/before /tmp/after
python3 tools/pr-shots.py                      # before/after PNGs vs origin/main
```

Needs `pip install lupa`; PNGs also need Node with `playwright`.

- **A refactor must dump identically** to the code before it. Make a `--dump` before your
  change and compare after. "same, reordered" means the same things in a different draw
  order: render the PNGs and look, since order matters where things overlap.
- **A visible change** should show in some scenario. If none covers it, add one in
  `tools/glance-shots/scenarios/` (see `prompts/add-a-screenshot-scenario.md`).
- Look at the PNGs you made before saying a change looks right.

## Pull requests

Use `.github/PULL_REQUEST_TEMPLATE.md`. Lead with what players will see before and
after, attach `screenshots/pr/summary.md` and its images, and say how it was tested.
