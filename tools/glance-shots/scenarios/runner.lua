-- A humanoid about to flee: RUNNER flashes with the brackets. You've just pulled aggro
-- off your pet, so the threat meter flashes red.
SHOT = { title = "Runner, and pulling aggro" }
WORLD.units.player = { name = "Morwen", guid = "Player-1", class = "WARLOCK", level = 30,
  hp = 1120, hpMax = 1240, powerType = 0, power = 1310, powerMax = 1820 }
WORLD.units.pet = { name = "Voidwalker", guid = "Pet-1", class = "WARRIOR", level = 30,
  hp = 900, hpMax = 1500, powerType = 0, power = 0, powerMax = 0 }
Boot()
Combat(true)
local mob = { name = "Defias Pillager", guid = Mob(589, 2), class = "MAGE", level = 29,
  hp = 300, hpMax = 1200, powerType = 0, power = 600, powerMax = 1100, reaction = 2, combat = true,
  creatureType = "Humanoid", classification = "elite" }
Target(mob)
WORLD.units.targettarget = WORLD.units.pet
WORLD.threat = { tanking = false, status = 1, pct = 80 }
Advance(1)
WORLD.units.targettarget = WORLD.units.player
WORLD.threat = { tanking = true, status = 3, pct = 100 }
Advance(0.55)
