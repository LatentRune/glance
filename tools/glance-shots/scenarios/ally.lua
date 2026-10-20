-- A player of your own faction targeted: green corner brackets and their faction, not a
-- green edge all around. Your pet's bar sits above the inner end of your bars.
SHOT = { title = "Ally targeted, pet by the spine" }
WORLD.units.player = { name = "Morwen", guid = "Player-1", class = "WARLOCK", level = 30,
  hp = 1120, hpMax = 1240, powerType = 0, power = 1310, powerMax = 1820, faction = "Alliance", player = true }
WORLD.units.pet = { name = "Voidwalker", guid = "Pet-1", class = "WARRIOR", level = 30,
  hp = 900, hpMax = 1500, powerType = 0, power = 0, powerMax = 0 }
Boot()
Target({ name = "Brightblade", guid = "Player-7", class = "PALADIN", level = 31, player = true,
  faction = "Alliance", reaction = 5, hp = 1500, hpMax = 1800, powerType = 0, power = 700, powerMax = 1200 })
Advance(1.5)
