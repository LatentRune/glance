# Check my change before I open a PR

```
Read AGENTS.md first. Review my changes against origin/main (git diff origin/main).

Check:
1. features/ draws nothing; every new file is in src/Glance.toc in a sensible place;
   events go through ns.Listen; nothing new is global.
2. Per-frame code doesn't ask the game for unit data and uses ns.Text/ns.Vis/ns.Alpha.
3. Nothing protected is moved, resized, shown or hidden in combat.
4. New features have a setting key, a checkbox and a help line.
5. It works on Lua 5.1 and on clients missing newer API (C_Spell, C_UnitAuras...).
6. Comments are true, in plain words, and the top comment of each changed file still
   describes it.
7. Run python3 tools/check.py and python3 tools/pr-shots.py; look at every screenshot
   and tell me if anything else changed that shouldn't have.

List what you'd fix, most important first, and fix the ones I agree with.
```
