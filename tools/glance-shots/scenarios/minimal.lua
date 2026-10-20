-- The combat scene in minimal mode: slim bars, no backgrounds, no percentages, and only
-- the target's name left as text.
dofile(SIM_DIR .. "scenarios/combat.lua")
SHOT = { title = "Minimal mode" }
NS.SetMinimal(true)
Advance(0.3)
