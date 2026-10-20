-- A rogue in stealth: a mob turns to you (spotted, flashing), your Sap on another mob
-- counts down on the buff row, and a Gouge that just broke flashes red.
SHOT = { title = "Rogue: spotted in stealth, Sap timer, broken Gouge" }
SPELLS[6770] = { name = "Sap", icon = "Interface\\Icons\\Ability_Sap" }
SPELLS[1776] = { name = "Gouge", icon = "Interface\\Icons\\Ability_Gouge" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 812, hpMax = 812, powerType = 3, power = 100, powerMax = 100 }
WORLD.stealthed = true
Boot()
local function MyAura(sub, guid, name, id)
  Log(NOW, sub, false, "Player-1", "Shadowstep", 0x511, 0, guid, name, 0xa48, 0, id, SPELLS[id].name, 1, "DEBUFF")
end
MyAura("SPELL_AURA_APPLIED", Mob(116, 1), "Defias Bandit", 6770)
Advance(12)
MyAura("SPELL_AURA_APPLIED", Mob(116, 2), "Defias Cutpurse", 1776)
Advance(1)
MyAura("SPELL_AURA_BROKEN", Mob(116, 2), "Defias Cutpurse", 1776)
local me = WORLD.units.player
Target({ name = "Defias Cutpurse", guid = Mob(116, 2), class = "ROGUE", level = 23,
  hp = 700, hpMax = 900, powerType = 3, power = 100, powerMax = 100, reaction = 2, creatureType = "Humanoid" })
WORLD.units.targettarget = me
Advance(0.7)
