-- Resting in an inn, nothing targeted: your bars rest faded, the Zzz above your level
-- stays solid.
SHOT = { title = "Resting at an inn" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 812, hpMax = 812, powerType = 3, power = 100, powerMax = 100 }
WORLD.resting = true
Boot()
Advance(1.2)
