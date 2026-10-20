-- A warrior with a caster mob at 14%: the gold tick marks 20%, the outline pulses for
-- Execute, and the mob's known casts sit at the right of the debuff row, Frostbolt lit
-- because it's casting it now.
SHOT = { title = "Execute zone and known casts", cursor = false }
SPELLS[5308] = { name = "Execute", icon = "Interface\\Icons\\INV_Sword_48" }
WORLD.units.player = { name = "Brakka", guid = "Player-1", class = "WARRIOR", level = 24,
  hp = 610, hpMax = 790, powerType = 1, power = 45, powerMax = 100 }
Boot()
Combat(true)
local caster = { name = "Defias Conjurer", guid = Mob(450, 2), class = "MAGE", level = 23,
  hp = 560, hpMax = 560, powerType = 0, power = 300, powerMax = 600, reaction = 2, combat = true,
  auras = { { name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", duration = 21, left = 14, mine = true },
    { name = "Sunder Armor", icon = "Interface\\Icons\\Ability_Warrior_Sunder", duration = 30, left = 24, mine = true, count = 3 } } }
Target(caster)
WORLD.units.targettarget = WORLD.units.player
-- Earlier in the fight it cast Frost Armor (can't be stopped) and Frostbolt.
caster.casting = { name = "Frost Armor", icon = "Interface\\Icons\\Spell_Frost_FrostArmor02", started = NOW, ends = NOW + 1.5, shielded = true }
Advance(0.5)
caster.casting = nil
Advance(1.5)
caster.casting = { name = "Frostbolt", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", started = NOW, ends = NOW + 3 }
Advance(0.4)
SetHealth("target", 78)
Advance(0.6)
