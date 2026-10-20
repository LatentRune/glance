-- A shaman's totems counting down on the buff row; one just destroyed flashes red.
SHOT = { title = "Shaman totems" }
WORLD.units.player = { name = "Tuskar", guid = "Player-1", class = "SHAMAN", level = 30,
  hp = 1300, hpMax = 1400, powerType = 0, power = 900, powerMax = 1500 }
WORLD.totems = {
  { name = "Searing Totem", start = NOW, duration = 55, icon = "Interface\\Icons\\Spell_Fire_SearingTotem" },
  { name = "Stoneskin Totem", start = NOW, duration = 120, icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem" },
  { name = "Healing Stream Totem", start = NOW, duration = 60, icon = "Interface\\Icons\\INV_Spear_04" },
  { name = "Windfury Totem", start = NOW, duration = 120, icon = "Interface\\Icons\\Spell_Nature_Windfury" },
}
Boot()
Combat(true)
Target({ name = "Rabid Dire Wolf", guid = Mob(1922, 7), class = "WARRIOR", level = 29,
  hp = 900, hpMax = 1400, powerType = 1, power = 30, powerMax = 100, reaction = 2, combat = true })
FireEvent("PLAYER_TOTEM_UPDATE")
Advance(20)
WORLD.totems[1] = nil  -- the Searing Totem is destroyed
FireEvent("PLAYER_TOTEM_UPDATE")
Advance(0.6)
