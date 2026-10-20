# Fix something that's wrong

```
Read AGENTS.md first and follow it.

What's wrong: <e.g. "the swing timer stays up after combat ends when I'm a hunter">.
What should happen instead: <...>.
When it happens: <class, level, client (Classic Era / Season / ...), what you were doing>.
Lua error, if any (from /console scriptErrors 1 or BugSack): <paste it>.

1. Find the cause. The top comment of each file says what it's for; features/ works
   things out and ui/ draws, so a wrong number is usually in features/ and a wrong look
   in ui/.
2. If you can, first make a screenshot scenario that shows the bug
   (prompts/add-a-screenshot-scenario.md), so the fix can be seen and stays fixed.
3. Fix it with the smallest change that does it.
4. Run python3 tools/check.py and python3 tools/pr-shots.py. Show me before and after,
   and confirm the other scenarios didn't change.
5. Explain the cause and the fix in a couple of sentences.
```
