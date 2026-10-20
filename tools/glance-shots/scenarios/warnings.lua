-- After a bad pull: worn gear, full bags and a death recap on your debuff row, with a
-- real debuff (red edge) beside them. Hovering the skull shows what killed you.
SHOT = { title = "Gear, bags and death recap", cursor = false }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 240, hpMax = 812, powerType = 3, power = 100, powerMax = 100,
  auras = { { name = "Weakened Soul", icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", duration = 60, left = 41 } } }
WORLD.gear = { [5] = { 12, 100 }, [7] = { 30, 75 } }
WORLD.bags.full = true
Boot()
local thug, mage = Mob(116, 1), Mob(450, 2)
Log(NOW, "SWING_DAMAGE", false, thug, "Defias Bandit", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 61, 0, 1, 0, 0, 0, false)
Advance(2.2)
Log(NOW, "SPELL_DAMAGE", false, mage, "Defias Conjurer", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 133, "Fireball", 4, 148, 0, 4, 0, 0, 0, false)
Advance(1.6)
Log(NOW, "SWING_DAMAGE", false, thug, "Defias Bandit", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 74, 0, 1, 0, 0, 0, false)
Advance(1.4)
Log(NOW, "SPELL_PERIODIC_DAMAGE", false, mage, "Defias Conjurer", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 133, "Fireball", 4, 21, 0, 4, 0, 0, 0, false)
Advance(0.8)
Log(NOW, "SWING_DAMAGE", false, thug, "Defias Bandit", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 88, 0, 1, 0, 0, 0, false)
Advance(0.5)
Log(NOW, "SPELL_DAMAGE", false, mage, "Defias Conjurer", 0xa48, 0, "Player-1", "Shadowstep", 0x511, 0, 143, "Fire Blast", 4, 112, 38, 4, 0, 0, 0, false)
FireEvent("PLAYER_DEAD")
Advance(7)  -- back on your feet; the mobs have left
local skull
for _, ic in ipairs(P.debuffs.icons) do if ic:IsShown() and ic.fake == "recap" then skull = ic end end
HoverOver(skull, -8, 8)
