# Add a screenshot scenario

```
Read AGENTS.md and tools/glance-shots/README.md first.

Add a screenshot scenario showing: <e.g. "a warrior fighting two mobs with the target
under 20%, so the execute brackets show">.

1. Copy the closest scenario in tools/glance-shots/scenarios/ to a new file named for
   what it shows (lowercase-with-dashes.lua). Set SHOT.title to a short caption.
2. Describe the world before Boot() (WORLD.units.player, auras, bags...), then use the
   helpers in tools/glance-shots/sim.lua (Target, Combat, SetHealth, Advance, MeleeHit,
   Log, HoverOver) to get to the moment worth showing. tools/glance-shots/world.lua says
   what each WORLD field means.
3. If the scenario needs a game function world.lua doesn't answer yet, add it there the
   way the others are written, with a comment.
4. Run python3 tools/glance-shots/shoot.py <name> and look at screenshots/<name>.png.
   Make sure it shows what it's meant to and nothing reads as broken.
5. Run every scenario with --dump twice and check with compare.py that the new one comes
   out the same both times.
```
