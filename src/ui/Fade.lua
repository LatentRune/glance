-- ui/Fade.lua: your bars dim while you're idle (full health and power, no target, out of
-- combat); the target's dim while it's out of range. The target's level stays solid.
-- What counts as idle or in range comes from features/Range.lua.
-- Settings: "fade" (yours), "range" (the target's).

local ADDON, ns = ...

ns.Hook("create", function(f, mirrored)
  f.fade = 1           -- 0..1, eased toward f.fadeGoal every frame
  f.mirrored = mirrored
end)

-- How faded a group should be, worked out with each redraw.
local function FadeGoal(f)
  if f.unit == "player" then
    if ns.On(f, "fade") and ns.Idle() then return 0.35 end
  elseif ns.On(f, "range") and UnitExists(f.unit) and f.inRange == false then
    return 0.45
  end
  return 1
end

ns.Hook("redraw", function(f)
  -- The goal uses the range read on the previous redraw, so it's read after.
  f.fadeGoal = FadeGoal(f)
  if f.unit ~= "player" then f.inRange = ns.InRange(f.unit) end
end)

ns.EveryFrame("timers", function(f, dt)
  if f.unit ~= "player" and f.level.SetIgnoreParentAlpha then
    if not f.levelSolid then f.levelSolid = true; f.level:SetIgnoreParentAlpha(true) end
    ns.Alpha(f.level, ns.db[f.unit].alpha)
  end
  local goal = f.unlocked and 1 or f.fadeGoal or 1
  if f.fade == goal and f.glanceAlpha then return end
  f.fade = f.fade + (goal - f.fade) * math.min(1, dt * 6)
  if math.abs(goal - f.fade) < 0.01 then f.fade = goal end
  ns.Alpha(f, ns.db[f.unit].alpha * f.fade)
end)
