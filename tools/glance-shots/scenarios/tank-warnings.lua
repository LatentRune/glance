-- A paladin tanking with Righteous Fury: Devotion Aura holds the long-buff slot, a
-- groupmate passing 70% of pulling aggro flashes a warning, and so does the last
-- player healed (Holy Light) while under half health.
SHOT = { title = "Paladin tank: aura slot, losing aggro, heal target low" }
SPELLS[465] = { name = "Devotion Aura", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" }
SPELLS[25780] = { name = "Righteous Fury", icon = "Interface\\Icons\\Spell_Holy_SealOfFury" }
SPELLS[635] = { name = "Holy Light", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" }
WORLD.units.player = { name = "Aldren", guid = "Player-1", class = "PALADIN", level = 30,
  hp = 1500, hpMax = 1700, powerType = 0, power = 900, powerMax = 1300,
  auras = {
    { name = "Blessing of Kings", icon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings", duration = 300, left = 120, help = true },
    { name = "Righteous Fury", icon = "Interface\\Icons\\Spell_Holy_SealOfFury", duration = 1800, left = 1500, help = true, mine = true },
    { name = "Devotion Aura", icon = "Interface\\Icons\\Spell_Holy_DevotionAura", duration = 0, left = 0, help = true, mine = true },
  } }
WORLD.units.party1 = { name = "Fizzbang", guid = "Player-3", class = "MAGE", level = 30,
  hp = 380, hpMax = 1000, powerType = 0, power = 500, powerMax = 1500 }
Boot()
Combat(true)
Target({ name = "Defias Pillager", guid = Mob(589, 2), class = "MAGE", level = 29,
  hp = 900, hpMax = 1200, powerType = 0, power = 600, powerMax = 1100, reaction = 2, combat = true,
  creatureType = "Humanoid" })
WORLD.units.targettarget = WORLD.units.player
WORLD.threat = { tanking = true, status = 3, pct = 100 }
Advance(0.6)
Log(NOW, "SPELL_HEAL", false, "Player-1", "Aldren", 0x511, 0, "Player-3", "Fizzbang", 0x512, 0, 635, "Holy Light", 2, 400, 0, 0, false)
WORLD.threatOf = { party1 = { pct = 82, status = 1 } }
Advance(0.65)
