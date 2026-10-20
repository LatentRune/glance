# Contributing to Glance

Thanks for helping. Glance gets better fastest when players who use it every day change
what bugs them, so small pull requests are welcome: a color, a size, a wording, one new
warning. You don't need to know the whole addon to change one part of it.

## The short version

1. Fork and clone the repo.
2. Change something under `src/`.
3. Run the checks and make screenshots:
   ```
   python3 tools/check.py
   python3 tools/pr-shots.py
   ```
4. Open a pull request. Paste `screenshots/pr/summary.md` into it and attach the
   pictures (CI also posts them on the PR for you).

## Setting up

You need **Python 3** with `lupa` (`pip install lupa`), and for pictures **Node** with
`playwright` (`npm install -g playwright && npx playwright install chromium`).

To try your change in the game too, link the addon folder into your AddOns folder so the
game loads your copy:

```
# macOS / Linux
ln -s "$PWD/Glance" "/path/to/World of Warcraft/_classic_era_/Interface/AddOns/Glance"
# Windows (from an admin prompt)
mklink /D "C:\...\_classic_era_\Interface\AddOns\Glance" "%CD%\Glance"
```

Then `/reload` in game after each change.

## Where things are

```
src/
  core/       the foundation: the shared table, hooks, settings, the redraw heartbeat
  features/   works things out from the game: threat, swing timer, known damage...
  ui/         draws what features/ worked out: one file per part of the bars
  settings/   the settings panel, Edit Mode, help and minimal modes, /glance
  dev/        /glance cpu and /glance debug
tools/
  glance-shots/   draws Glance without the game, for screenshots and tests
  pr-shots.py     before-and-after screenshots of your change
  check.py        the layout rules below
prompts/          ready-made prompts for AI coding assistants
docs/             how it all fits together
```

Most changes touch one file in `ui/` (how something looks) or one in `features/` (what it
works out), sometimes both. The comment at the top of each file says what it's for, which
setting switches it, and which other files it works with.
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains the whole thing.

## The rules

These keep the code easy for the next person. `tools/check.py` checks the first three.

- **features/ never draws.** No frames, textures or font strings there. It works things
  out and puts functions on `ns` for ui/ to call.
- **Every file is listed in `src/Glance.toc`.** The game only loads what's listed.
- **Events go through `ns.Listen`** (or `ns.ListenUnits`), not `RegisterEvent`, so
  `/glance cpu` can see what each part costs.
- **One part, one file.** A new part of the bars gets its own file in `ui/`, and its
  calculations their own file in `features/` if there are any.
- **The order in Glance.toc is the order things are built.** ui/ files are listed in
  the order their parts are made and stacked, and hooks run in that order. Add a new file
  where its part belongs (usually near the end) and don't reorder others without a reason.
- **Every part has a checkbox.** Add its key to `core/Defaults.lua` and a line to
  `settings/Panel.lua`, and a help line to `settings/Help.lua` if it's something players see.
- **Cheap every frame.** Code that runs every frame (`ns.EveryFrame`, `"frame"` hooks)
  reads what the last redraw stored on the group instead of asking the game, and uses
  `ns.Text`, `ns.Vis` and `ns.Alpha` so nothing is set again when it hasn't changed.
- **Comments say what and why**, in plain words a player would follow. Name the setting
  and the game behavior; skip what the code already says.

## Screenshots

`tools/glance-shots/` runs Glance's real Lua against a stand-in for the game and draws
what it built, in scenarios like "in combat as a rogue" or "a warlock with shards". It
isn't the game (icons are colored tiles, fonts are close), but layout, sizes, colors,
text and timing all come from the addon.

- `python3 tools/pr-shots.py` compares your copy with `origin/main` and saves before and
  after pictures of every scenario your change affects.
- `python3 tools/glance-shots/shoot.py combat` draws one scenario into `screenshots/`.
- If your change doesn't show in any scenario, add one: copy a file in
  `tools/glance-shots/scenarios/`, set up the world, and run it.
  [prompts/add-a-screenshot-scenario.md](prompts/add-a-screenshot-scenario.md) walks through it.

A change that only reorganizes code should draw exactly the same: `pr-shots.py` then says
nothing changed. That's the test.

## Pull requests

- Say what players will see, before and after, in plain words. Screenshots help most.
- Say how you tested: the screenshot scenarios, and if you can, in game (which client,
  class and level).
- Keep it to one change. Two small PRs get reviewed faster than one big one.
- CI runs `tools/check.py`, luacheck and every screenshot scenario, and posts your
  before-and-after pictures on the PR.

## Zips

`python3 tools/package.py` zips the whole project into `dist/` for sharing with another
contributor. `python3 tools/package.py release` builds the player zip: `src/` as the
`Glance/` folder the game expects, with the license inside, which is what a `v*` tag publishes.

## Feedback without code

Issues are just as useful: [a bug](https://github.com/LatentRune/glance/issues/new?template=bug.yml),
[how something looks](https://github.com/LatentRune/glance/issues/new?template=looks.yml),
or [an idea](https://github.com/LatentRune/glance/issues/new?template=idea.yml).
A screenshot from the game with `/glance help` on is worth a paragraph.

For a quick question, or to show off your setup, come to [Discord](https://discord.gg/wcCfAmMsFV). Bigger ideas that
need talking through belong in [Discussions](https://github.com/LatentRune/glance/discussions).

## License

By contributing you agree your contribution is released under the [MIT License](LICENSE).
