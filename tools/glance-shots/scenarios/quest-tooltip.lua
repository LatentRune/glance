-- Hovering a quest task under the target.
SHOT = { title = "Quest task tooltip" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 12,
  hp = 380, hpMax = 380, powerType = 3, power = 100, powerMax = 100 }
WORLD.quests = { { title = "Plainstrider Menace", level = 11, id = 844,
  text = "Bring 7 Plainstrider Beaks to Sergra Darkthorn in the Crossroads.",
  description = "The plainstriders have been raiding our stores. Thin their numbers, and bring back their beaks as proof.",
  objectives = { { text = "Plainstrider Beak: 3/7", type = "item", finished = false } } } }
Boot()
Target({ name = "Plainstrider", guid = Mob(3244, 1), class = "WARRIOR", level = 11,
  hp = 210, hpMax = 210, powerType = 0, power = 0, powerMax = 0, reaction = 2, creatureType = "Beast" })
Advance(1)
HoverOver(T.quest.bars[1], 30, 0)
