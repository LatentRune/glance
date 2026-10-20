-- /glance debug: the performance panel under your bars.
SHOT = { title = "Debug panel" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 700, hpMax = 812, powerType = 3, power = 55, powerMax = 100, combo = 2 }
Boot()
Combat(true)
Target({ name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 25,
  hp = 900, hpMax = 1400, powerType = 1, power = 30, powerMax = 100, reaction = 2, combat = true })
SlashCmdList.GLANCE("debug")
Advance(3.2)
