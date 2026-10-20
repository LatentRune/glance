-- A mage jumped by an enemy rogue: Cheap Shot then two Sinister Strikes land, so three of
-- its combo points show along the top of your health, building from the middle outward.
SHOT = { title = "PvP: enemy rogue building combo points on you" }
local me = { name = "Frostwyn", guid = "Player-1", class = "MAGE", level = 30,
  hp = 690, hpMax = 1180, powerType = 0, power = 1400, powerMax = 2100 }
WORLD.units.player = me
SPELLS[1833] = { name = "Cheap Shot", icon = "Interface\\Icons\\Ability_CheapShot" }
SPELLS[1752] = { name = "Sinister Strike", icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice" }
SPELLS[2098] = { name = "Eviscerate", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" }
Boot()
Combat(true)
local rogue = { name = "Knifey", guid = "Player-2", class = "ROGUE", level = 30,
  hp = 1020, hpMax = 1100, powerType = 3, power = 40, powerMax = 100, reaction = 2, combat = true,
  isPlayer = true }
Target(rogue)
WORLD.units.targettarget = me
WORLD.threat = { tanking = true, status = 3, pct = 100 }
local HOSTILE_PLAYER = 0x548
local function Lands(sub, id, amount)
  Log(NOW, sub, false, "Player-2", "Knifey", HOSTILE_PLAYER, 0, "Player-1", "Frostwyn", 0x511, 0,
    id, SPELLS[id].name, 1, amount or 0, 0, 1, 0, 0, 0, false)
end
Lands("SPELL_AURA_APPLIED", 1833)
Advance(0.5)
Lands("SPELL_DAMAGE", 1752, 140)
Advance(0.5)
Lands("SPELL_DAMAGE", 1752, 150)
Advance(0.5)
