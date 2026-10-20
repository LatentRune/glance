-- A warlock with a Voidwalker, soul shards and a caster target mid-cast.
SHOT = { title = "Warlock with pet vs. caster" }
local me = { name = "Morwen", guid = "Player-1", class = "WARLOCK", level = 30,
  hp = 1120, hpMax = 1240, powerType = 0, power = 1310, powerMax = 1820 }
WORLD.units.player = me
WORLD.units.pet = { name = "Voidwalker", guid = "Pet-1", class = "WARRIOR", level = 30,
  hp = 640, hpMax = 1500, powerType = 0, power = 0, powerMax = 0,
  auras = { { name = "Curse of Weakness", icon = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth", duration = 120, left = 95 } } }
WORLD.bags.shards = 7
WORLD.bags.soulBag = 20
Boot()
Combat(true)
local caster = { name = "Defias Conjurer", guid = Mob(619, 3), class = "MAGE", level = 29,
  hp = 980, hpMax = 1300, powerType = 0, power = 600, powerMax = 1100, reaction = 2, combat = true,
  creatureType = "Humanoid",
  casting = { name = "Frostbolt", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", started = NOW - 1.2, ends = NOW + 1.8 },
  auras = {
    { name = "Corruption", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", duration = 18, left = 14, mine = true },
    { name = "Curse of Agony", icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", duration = 24, left = 20, mine = true },
  } }
Target(caster)
WORLD.units.targettarget = WORLD.units.pet
WORLD.threat = { tanking = false, status = 1, pct = 46 }
Advance(1.5)
