# How Glance fits together

This is the map for changing Glance. Each file's own top comment has the detail.

## Layers

```
core/      shared table, helpers, hooks, settings, heartbeat     (everything uses it)
features/  reads the game and works things out                    (uses core)
ui/        draws what features worked out                         (uses core, features)
settings/  panel, Edit Mode, help, minimal, /glance               (uses all of the above)
dev/       /glance cpu and /glance debug                          (uses all of the above)
```

A feature usually has two files with the same name: `features/SwingTimer.lua` works out
when your next swing lands; `ui/SwingTimer.lua` draws the bar. Some have only one side:
`features/Threat.lua` is drawn by `ui/ThreatMeter.lua`, and `ui/Fade.lua` uses
`features/Range.lua`. Parts that need nothing worked out (the low-health flash, the
stack under the bars) live only in ui/.

`tools/check.py` enforces the line between them: features/ makes no frames and draws
nothing.

## The shared table

Every file starts with `local ADDON, ns = ...`. The game hands each file of an addon its
name and one shared table; whatever a file puts on `ns` the files after it can use.
Everything else stays local to the file. The load order is `src/Glance.toc`.

What's on `ns`, by where it comes from:

- `core/Namespace.lua`: constants (`ns.FONT`, `ns.TEX`, power types, `ns.CLASS`,
  `ns.CLASSIC`), `ns.groups` (the two groups, by unit), `ns.cadence`, and `ns.On(f, key)`,
  whether a feature's checkbox is on for a group.
- `core/Util.lua`: `ns.Text`, `ns.Vis`, `ns.Alpha` (set only when changed), `ns.Pct`,
  `ns.Deep` (deep colors), `ns.NpcID`, `ns.Say`.
- `core/Compat.lua`: one name for API calls that differ between clients.
- `core/Defaults.lua`: `ns.db` (shared by your characters) and `ns.char` (this
  character), loaded at login.
- Each features/ file: the functions its top comment lists (`ns.Threat(unit)`,
  `ns.swing`, `ns.KnownDamage(unit)`...).
- ui/widgets/: the building blocks (`ns.NewBar`, `ns.SetBar`, `ns.Segment`,
  `ns.AuraIcon`...).

## Life of a group

Glance draws two **groups**: yours (`ns.groups.player`) and the target's
(`ns.groups.target`). A group is a secure click-to-target button holding a stack of bars
(`ui/Group.lua`), with every other part hung on it by the ui/ files.

Parts plug in with **hooks** (`core/Hooks.lua`), not by wrapping each other:

| Stage | When | Given | What a hook does there |
|---|---|---|---|
| `login` | once, settings loaded | | make things that need settings (ui/Group.lua makes the groups here) |
| `create` | a group was made | `f, mirrored` | make your widgets on `f` |
| `geometry` | sizes or settings changed | `f` | size and place your widgets |
| `redraw` | 5–10 times a second | `f` | ask the game, update what you show |
| `preview` | instead of redraw while unlocked with nothing targeted | `f` | show a sample |
| `frame` | every frame, once | `dt` | animation that isn't per group |
| `minimal` | minimal mode switched | `on` | follow it |

And two more ways in:

- `ns.Listen(name, events, fn)` / `ns.ListenUnits(...)`: game events.
- `ns.EveryFrame(name, fn)`: every frame, for each group on screen. Keep it cheap: read
  what the last redraw stored on the group (`f.hp`, `f.exists`, `f.guid`...).

The `name` is one of a few **handler names**: `"bars"`, `"timers"`, `"alerts"`,
`"fight history"`, `"damage model"`. Each is one line in `/glance cpu` and `/glance
debug`, so the cost of every part is counted somewhere. A listener too cheap to be worth
a line can pass `nil`; it then isn't counted.

### Order matters

Hooks of a stage run in the order they were added, which is the order of the files in
Glance.toc. The ui/ files are listed in the order their parts are built, because:

- what's made later draws on top of what's made earlier at the same layer;
- a redraw hook can rely on the ones before it (the stack under the bars is laid out
  after everything in it has decided whether to show);
- per-frame work runs in a fixed order, which keeps the screenshot tests exact.

So add a new part where it belongs in the list (usually at the end of ui/) and leave the
others where they are unless you mean to change what draws over what.

## The heartbeat

`core/Loop.lua` decides when things happen:

- every frame: the `"frame"` hooks (the bars glide toward their values, the bars slide);
- every 0.2 s (0.1 s while your or your target's health or power changes): each shown
  group is redrawn, which runs every `"redraw"` hook;
- every frame, for each group on screen: the `ns.EveryFrame` functions (casts, threat
  flame, fades, timers...).

## Combat lockdown

The game won't let addons move, resize, show or hide click-to-target frames in combat.
So:

- `ns.ApplyGeometry(f)` does nothing in combat; `ns.ApplyGeometry(f, true)` changes only
  what isn't protected (bar heights, fonts), and the group keeps its old height until
  combat ends. The difference is `f.slack`; the stack under the bars follows the bars.
- Anything that needs the rest asks with `ns.GeometryLater()`, and it happens when
  combat ends.
- Click-through and the target's show/hide use secure state drivers, which the game runs
  itself, so they keep working in combat.

## Under the bars

What hangs under a group is listed in `f.below` (`ui/Stack.lua`) and restacked with
`ns.ChainBelow(f)` whenever something in it shows or hides. Cast lanes count while
reserved, so a cast starting or ending moves nothing.

## Settings

Each group has its own sizes and a checkbox per feature in `ns.db.player.labels` and
`ns.db.target.labels` (`core/Defaults.lua`). `ns.On(f, key)` reads one. A new feature
needs its key there (true = on by default), a line in `settings/Panel.lua`, and if
players see it, a help line in `settings/Help.lua`.

Saved variables: `GlanceDB` is shared by all your characters (sizes, positions, what's
learned about mobs: drops, health, runners, casts); `GlanceCharDB` is this character's
(buffs you keep up, your spells' damage, your kill times). Migrations from older
versions are in `ns.LoadSettings`.

## Screenshots without the game

`tools/glance-shots/` loads the addon exactly as the game does (Glance.toc order) into a
stand-in for the game's widgets (`ui.lua`) and API (`world.lua`), runs a scenario, and
draws what Glance built. `--dump=DIR` writes what was drawn as JSON instead, and
`compare.py` diffs two dumps; `tools/pr-shots.py` does both sides of a change and renders
what differs. A refactor that changes nothing on screen dumps identically.

The stand-in runs every OnUpdate at 60 fps and fires events to frames in the order they
were made, as the game does. With `--dump`, time and random numbers are fixed so two
runs of the same code match exactly.
