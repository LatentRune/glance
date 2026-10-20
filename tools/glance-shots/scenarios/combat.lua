-- A rogue mid-fight with an elite wolf and two of its friends: aggro count, hit flash,
-- threat ember, debuffs, quest progress, target of target and the wolf's cast.
SHOT = { title = "Combat: rogue vs. elite wolf" }
local me = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 498, hpMax = 812, powerType = 3, power = 65, powerMax = 100, combo = 3,
  auras = { { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 15, left = 9 } } }
WORLD.units.player = me
SPELLS[1752] = { name = "Sinister Strike", icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice" }
WORLD.quests = { { title = "Wolves at the Gate", level = 23, id = 101, text = "Kill 8 Rabid Dire Wolves.",
  description = "The wolves have been harrying the farms for weeks.",
  objectives = { { text = "Rabid Dire Wolf slain: 5/8", type = "monster", finished = false } } } }
Boot()
Combat(true)
local wolf = { name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 25,
  classification = "elite", hp = 1400, hpMax = 1400, powerType = 1, power = 30, powerMax = 100,
  reaction = 2, mark = 8, combat = true, creatureType = "Beast", family = "Wolf",
  auras = {
    { name = "Garrote", icon = "Interface\\Icons\\Ability_Rogue_Garrote", duration = 18, left = 11, mine = true },
    { name = "Expose Armor", icon = "Interface\\Icons\\Ability_Warrior_Riposte", duration = 30, left = 2.4, mine = true },
  } }
Target(wolf)
WORLD.units.targettarget = me
WORLD.threat = { tanking = false, status = 2, pct = 88 }
Advance(1.5)
-- Three wolves on you.
for i = 1, 3 do MeleeHit(Mob(1922, i + 6), "Player-1", 40) end
-- A Sinister Strike lands: 1400 -> 860, caught early in its flash.
SetHealth("target", 860)
Advance(0.2)
