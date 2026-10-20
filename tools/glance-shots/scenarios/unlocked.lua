-- /glance unlock with the settings for your bars open.
SHOT = { title = "Unlocked, settings open" }
WORLD.units.player = { name = "Shadowstep", guid = "Player-1", class = "ROGUE", level = 24,
  hp = 812, hpMax = 812, powerType = 3, power = 100, powerMax = 100 }
Boot()
SlashCmdList.GLANCE("unlock")
Advance(0.5)
P.mover:GetScript("OnMouseDown")(P.mover)
Advance(0.2)
