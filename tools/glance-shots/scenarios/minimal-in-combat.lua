-- Switching to minimal mode mid-fight: the bars slim down at once (their click areas catch
-- up when combat ends). Crossed swords and a red outline mark that you're in combat.
dofile(SIM_DIR .. "scenarios/combat.lua")
SHOT = { title = "Minimal mode switched on in combat" }
WORLD.lockdown = true
NS.SetMinimal(true)
Advance(0.3)
