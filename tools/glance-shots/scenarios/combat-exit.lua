-- Combat just ended: the red swords over your level shatter into pieces that drift
-- outward and fade while the level fades back in.
SHOT = { title = "Leaving combat: the swords shatter" }
WORLD.units.player = { name = "Aldren", guid = "Player-1", class = "PALADIN", level = 30,
  hp = 700, hpMax = 800, powerType = 0, power = 500, powerMax = 720 }
Boot()
Combat(true)
Advance(4)
Combat(false)
Advance(0.4)
