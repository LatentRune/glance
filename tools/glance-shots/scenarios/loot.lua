-- After a fight: two of your kills still have loot.
SHOT = { title = "Loot reminder", cursor = false }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 640, hpMax = 812, powerType = 3, power = 80, powerMax = 100 }
Boot()
WORLD.loot = {}
Combat(true)
for i = 1, 2 do
  local g = Mob(1922, i)
  Log(NOW, "SWING_DAMAGE", false, "Player-1", "You", 0x511, 0, g, "Wolf", 0xa48, 0, 90, 0, 1, 0, 0, 0, false)
  Log(NOW, "UNIT_DIED", false, "", "", 0, 0, g, "Wolf", 0xa48, 0)
  WORLD.loot[g] = true
end
Combat(false)
Advance(2)  -- the game is asked about loot a second after the kill
HoverOver(P.debuffs.icons[1], -8, 8)
