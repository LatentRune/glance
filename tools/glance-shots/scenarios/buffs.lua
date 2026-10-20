-- Short buffs share the debuff row: buffs from the left (green edge), debuffs from the right.
SHOT = { title = "Short buffs beside debuffs" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 560, hpMax = 812, powerType = 3, power = 45, powerMax = 100, combo = 2,
  auras = {
    { name = "Slice and Dice", icon = "Interface\\Icons\\Ability_Rogue_SliceDice", duration = 21, left = 14, help = true, mine = true },
    { name = "Evasion", icon = "Interface\\Icons\\Spell_Shadow_ShadowWard", duration = 15, left = 6, help = true, mine = true },
    { name = "Arcane Intellect", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", duration = 1800, left = 1500, help = true },
    { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 15, left = 9 },
    { name = "Crippling Poison", icon = "Interface\\Icons\\Ability_PoisonSting", duration = 12, left = 2.5 },
  } }
Boot()
Combat(true)
Target({ name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 25,
  hp = 900, hpMax = 1400, powerType = 1, power = 30, powerMax = 100, reaction = 2, combat = true })
Advance(1.5)
