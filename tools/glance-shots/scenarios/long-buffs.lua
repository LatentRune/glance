-- Long buffs: one on the row (blue edge, +N more), all of them open while it's hovered.
-- Every timed icon carries a clock sweep darkening the time already gone.
SHOT = { title = "Long buffs, hovered" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 560, hpMax = 812, powerType = 3, power = 45, powerMax = 100,
  auras = {
    { name = "Slice and Dice", icon = "Interface\\Icons\\Ability_Rogue_SliceDice", duration = 21, left = 14, help = true, mine = true },
    { name = "Arcane Intellect", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", duration = 1800, left = 1500, help = true },
    { name = "Mark of the Wild", icon = "Interface\\Icons\\Spell_Nature_Regeneration", duration = 1800, left = 400, help = true },
    { name = "Power Word: Fortitude", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", duration = 1800, left = 1100, help = true },
    { name = "Blessing of Might", icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", duration = 300, left = 210, help = true },
    { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 15, left = 9 },
  } }
Boot()
Combat(true)
Target({ name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 25,
  hp = 900, hpMax = 1400, powerType = 1, power = 30, powerMax = 100, reaction = 2, combat = true })
Advance(1.5)
HoverOver(P.longIcon)
Advance(0.2)
