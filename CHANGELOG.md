# Changelog

## Unreleased

- Glance is ready the moment you log in: on first run the bars start just below the
  middle of the screen instead of copying where Blizzard's frames sat (the top left
  corner on the default UI). Bars that were placed that way move to the middle once;
  bars you dragged yourself stay put. `/glance reset` puts them back in the middle too.
- For contributors: the addon's code moved from `Glance/` to `src/` in the repository.
  Installed, it's still the `AddOns/Glance/` folder.

## 0.67.1

- Stronger bar shading: a brighter top and a darker bottom.

## 0.67.0

- New buffs and debuffs start 40% bigger and invisible, then shrink into place as they
  fade in. When one ends it breaks apart into pieces of its own icon that scatter and
  fade. Switching targets doesn't set it off. Setting: "Buffs grow in, break apart".
- The combat swords shrink in from 140% as they fade in when combat starts.
- The bars' light top and dark bottom are now smooth gradients instead of two hard bands.

## 0.66.1

- After their 3 seconds of red flashing, the combat swords go back to their normal color.
- The shatter when combat ends is much bigger: the swords swell to over twice their
  size, a flash goes off, and the pieces fly several icon-widths out over a second and a
  half. The pieces stay bright even while your bars fade out.

## 0.66.0

- The combat swords over your level are red now and flash for 3 seconds when combat
  starts. When combat ends they shatter into pieces that drift outward and fade while
  your level fades back in.

## 0.65.0

- The blinking chevron is gone. When the target's target becomes you, YOU blinks for a
  few seconds instead, and it's a stronger red.
- New: crowd control you cast shows in your buff row as a purple timer for the mob, so
  you can see it after switching targets. Fears assume the full duration. When it ends
  or breaks it turns into a red flashing icon for 3 seconds. Setting: "Crowd control timers".
- New: shaman totems show the same way in teal, flashing red for 3 seconds when they
  expire or are destroyed. Setting: "Totem timers".
- Paladins always get their aura in the long-buff slot, and hunters their aspect.
- New: a flashing "!" for 3 seconds when a mob turns on you while you're stealthed.
  Setting: "Spotted in stealth".
- New, tanks only (warriors, bear druids, paladins with Righteous Fury): a flashing
  warning for 3 seconds when a groupmate passes 70% of the threat needed to pull your
  target. Setting: "Losing aggro (tanks)".
- New: if the last player you healed directly drops under 50% health, a warning flashes
  until they're back over 50%. Group heals and HoTs don't count. Setting: "Heal target low".

## 0.64.0

- Kill pace drops the word "kill": just "~12s" before a fight.
- RUNNER sits over the outer end of the target's bars.
- While your bars rest faded (out of combat, nothing targeted), a plain click on them
  targets you and brings them back; otherwise clicks still need Shift, Ctrl or Alt.
- New: a pulsing blue "Zzz" above your level while you're resting and earning rested
  experience. It stays solid while your bars are faded. Setting: "Resting indicator".

## 0.63.1

- RUNNER moves above everything over the target's bars, centered and larger.
- The clock sweep on buffs and debuffs is darker and has a bright hand on its edge. It
  restarts if the game drops it while hidden, and cooldown-count addons leave it alone.

## 0.63.0

- Your pet's bar moves above the inner end of your bars, by the spine, mirroring the
  target of target.
- One long buff on your buff row (blue edge, the one running out soonest, +N for how many
  more). Hover it and all your long buffs open below it, each with its own tooltip.
- Buffs and debuffs carry a clock sweep: once around over the aura's whole duration,
  darkening the time already gone.
- A player of your own faction gets green corner brackets and their faction name instead
  of a green edge all around. The setting is now "Faction corners".
- The mob count on the spine is bigger.
- RUNNER sits on its own beside the tag and flashes with the brackets.
- The threat meter flashes red for two seconds when you pull aggro.

## 0.62.0

- The threat flame climbs the whole spine: a dark track, the color of a bar's empty part,
  from level with the target of target down past the bars, shown in combat. It replaces
  the red combat line. The threat number sits left of the flame.
- The mob count sits just under the track.
- "Frostbolt x8" (casts your mana covers) moves to the left end of the mana bar.
- The target's raid-mark skull moves beside its debuff row; its level goes back beside
  the bars, where the skull was.
- Kill pace moves above the outer end of the target's bars, with the ELITE/RARE tag to
  its left.
- New: when an enemy rogue or cat druid builds combo points on you, they show along the
  top of your health bar, filling from the middle outward. Counted from the combat log
  (crit bonus points aren't seen). Setting: "Enemy combo points on you".

## 0.61.0

- Open source under the MIT license, at https://github.com/LatentRune/glance.
- The code is reorganized by job: `core/` (the foundation), `features/` (what Glance works
  out), `ui/` (what it draws, one file per part), `settings/` and `dev/`. Nothing changes
  in game: every screenshot scenario draws exactly as 0.60 did.
- `/glance` is the only command; the old alias is gone.
- Fixed: unlocking the bars with nothing targeted could leave the target's blue box tucked
  under yours instead of where you placed it.
- Tools for contributors: screenshots without the game, before-and-after pictures for
  pull requests, a layout checker, and prompts for AI coding assistants.
