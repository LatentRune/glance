-- Debuffs arriving and leaving on the target: Rend just went on and is still growing
-- in, Sunder Armor just fell off and is breaking apart.
SHOT = { title = "Debuffs growing in and breaking apart" }
WORLD.units.player = { name = "Aldren", guid = "Player-1", class = "WARRIOR", level = 30,
  hp = 700, hpMax = 800, powerType = 1, power = 40, powerMax = 100 }
Boot()
Combat(true)
local wolf = { name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 29,
  hp = 1100, hpMax = 1400, powerType = 1, power = 30, powerMax = 100, reaction = 2, combat = true,
  creatureType = "Beast", auras = {
    { name = "Sunder Armor", icon = "Interface\\Icons\\Ability_Warrior_Sunder", duration = 30, left = 1.2, mine = true },
    { name = "Hamstring", icon = "Interface\\Icons\\Ability_ShockWave", duration = 15, left = 12, mine = true },
  } }
Target(wolf)
Advance(1)
local auras = wolf.auras
table.remove(auras, 1)
auras[#auras + 1] = { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 21, left = 21, mine = true }
AurasChanged("target")
Advance(0.12)
