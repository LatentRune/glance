# Change how something looks

```
Read AGENTS.md first and follow it.

I want to change how this part of Glance looks: <the part, e.g. "the target's cast bar">.
What I want: <e.g. "make the interrupt glow thicker and a little darker blue">.
Why (what's hard to read now): <e.g. "on a blue-ish background it's easy to miss">.

1. Find the ui/ file that draws it (the top comments say what each file draws) and make
   the smallest change that does what I asked. Don't touch features/ unless the look
   needs a new number from it.
2. Run python3 tools/check.py.
3. Run python3 tools/pr-shots.py and show me the before and after screenshots it made.
   If no scenario shows this part, add one (see prompts/add-a-screenshot-scenario.md).
4. Tell me what changed in one or two sentences a player would understand, and anything
   I should check in game.
```
