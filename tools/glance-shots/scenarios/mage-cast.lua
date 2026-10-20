-- A mage casting Frostbolt at a trivial mob that's out of range: the pale strip on the
-- mana bar is what the cast will spend, "Frostbolt xN" is how many more mana covers,
-- and the target's level stays solid while its bars fade.
SHOT = { title = "Mage casting, target out of range" }
SPELLS[116] = { name = "Frostbolt", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", cost = 65, cast = 2500 }
WORLD.units.player = { name = "Frostwyn", guid = "Player-1", class = "MAGE", level = 24,
  hp = 690, hpMax = 690, powerType = 0, power = 520, powerMax = 1150 }
Boot()
Target({ name = "Kobold Vermin", guid = Mob(6, 2), class = "WARRIOR", level = 14,
  hp = 180, hpMax = 180, powerType = 0, power = 0, powerMax = 0, reaction = 2 })
WORLD.outOfRange = true
Advance(1)
WORLD.units.player.casting = { name = "Frostbolt", started = NOW, ends = NOW + 2.5 }
FireEvent("UNIT_SPELLCAST_START", "player", "cast-1", 116)
Advance(1)
