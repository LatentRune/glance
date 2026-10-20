-- Underwater, 12 seconds of air left: the breath debuff is flashing.
SHOT = { title = "Breath running out", cursor = false }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 812, hpMax = 812, powerType = 3, power = 100, powerMax = 100,
  auras = { { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 15, left = 9 } } }
Boot()
FireEvent("MIRROR_TIMER_START", "BREATH", 60000, 60000, -1, 0, "Breath")
Advance(48)
HoverOver(P.debuffs.icons[1], -8, 8)
