# Add something new

```
Read AGENTS.md and docs/ARCHITECTURE.md first and follow them.

I'd like Glance to show: <what, e.g. "a small icon when my target is immune to the
spell school I'm casting">.
Where on the bars: <e.g. "next to the target's cast bar">.
When it should show and when not: <e.g. "only in combat, only for hostile targets">.
Which classes or clients it's for: <e.g. "every class; Classic Era">.

Build it the Glance way:
1. Anything worked out from the game goes in a new features/<Name>.lua that draws
   nothing and puts its functions on ns. Drawing goes in a new ui/<Name>.lua using
   ns.Hook("create"/"geometry"/"redraw") and ns.EveryFrame for animation.
2. List the new files in src/Glance.toc: the feature with the other features, the
   ui file at the end of the ui/ list unless it has to draw under something.
3. Give it a setting key in core/Defaults.lua (labels), a checkbox in
   settings/Panel.lua, and a help line in settings/Help.lua.
4. Top comment on each new file: what it shows, its setting, the files it works with.
5. Add a screenshot scenario that shows it (prompts/add-a-screenshot-scenario.md).
6. Run python3 tools/check.py and python3 tools/pr-shots.py. Show me the screenshots,
   and confirm the scenarios that shouldn't change didn't.
7. Tell me what it does in plain words, what it costs per frame, and what to test in game.
```
