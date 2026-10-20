-- Help mode on, hovering the target's health bar.
SHOT = { title = "Help mode tooltip" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 812, hpMax = 812, powerType = 3, power = 100, powerMax = 100, combo = 0 }
Boot({ help = true })
Target({ name = "Plainstrider", guid = Mob(3244, 1), class = "WARRIOR", level = 22,
  hp = 320, hpMax = 440, powerType = 0, power = 0, powerMax = 0, reaction = 2 })
Advance(1)
HoverOver(T.bars.health, 40, 0)
Advance(0.3)
