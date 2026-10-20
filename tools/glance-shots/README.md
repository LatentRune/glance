# Glance screenshots without the game

`shoot.py` runs the addon's real Lua against a stand-in for the game and saves what it
draws as PNGs in `screenshots/` at the top of the repo. The addon itself is unchanged and loads exactly
as the game loads it, so a screenshot shows the code as it is now.

```
python3 shoot.py                  # every scenario
python3 shoot.py combat warlock   # just these
python3 shoot.py --html-only      # write the .html pages only (open them in any browser)
```

Needs Python with `lupa` (`pip install lupa`). For PNGs it also needs Node with the
`playwright` package and its Chromium.

## How it works

- `ui.lua` stands in for the game's widgets: frames, textures, font strings, status bars,
  sliders, check buttons and the tooltip. It keeps what the addon sets (points, sizes,
  colors, text, alpha, scale, strata, layers) and lays things out the way the game does.
  Methods it doesn't model do nothing.
- `world.lua` answers the game's API (`UnitHealth`, `UnitAura`, threat, quests, bags,
  combat log...) from a `WORLD` table a scenario fills in.
- `sim.lua` has the helpers scenarios use: `Boot()`, `Target()`, `Combat()`,
  `SetHealth()`, `Advance(seconds)` (runs every OnUpdate frame by frame, at 60 fps),
  `HoverOver(widget)` (moves the mouse there and fires OnEnter) and `MeleeHit()`/`Log()`
  for combat log lines.
- `shoot.py` turns the drawn list into HTML and `shoot.js` screenshots it with headless
  Chromium, cropped to what was drawn, at 2x.

## Adding a scenario

Copy one in `scenarios/`, change the world, and run it. The order is: describe the
player, `Boot()`, then change things and let time pass. See `combat.lua` for a busy one.

## What's approximate

- Game art can't be loaded here, so spell and item icons are colored tiles with a short
  label, sparks are soft glows, and raid marks are symbols.
- Text uses Liberation Sans squeezed to the width of Arial Narrow.
- The background is a stand-in for the game world.
- Layout, colors, alpha, sizes, text and draw order come from the addon itself.
