-- ui/SwingTimer.lua: a thin bar under yours filling to your next melee swing (white) or
-- ranged shot (green), shown in combat. Timing comes from features/SwingTimer.lua.
-- Setting: "swing".

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.swing = CreateFrame("StatusBar", nil, f)
  f.swing:SetStatusBarTexture(ns.TEX)
  f.swing:SetMinMaxValues(0, 1)
  local sb = f.swing:CreateTexture(nil, "BACKGROUND")
  sb:SetPoint("TOPLEFT", -1, 1); sb:SetPoint("BOTTOMRIGHT", 1, -1)
  sb:SetColorTexture(0, 0, 0, 0.85)
  ns.Vis(f.swing, false)
end)

ns.Hook("geometry", function(f)
  if f.unit == "player" then f.swing:SetHeight(4) end
end)

ns.EveryFrame("timers", function(f)
  if f.unit ~= "player" then return end
  local bar, swing, t = f.swing, ns.swing, GetTime()
  local show = ns.On(f, "swing") and swing.at and swing.speed and swing.speed > 0
    and ns.inCombat and t - swing.at < swing.speed + 1
  if not show then
    if ns.Vis(bar, false) then ns.ChainBelow(f) end
    return
  end
  bar:SetValue(math.min((t - swing.at) / swing.speed, 1))
  if bar.ranged ~= swing.ranged then
    bar.ranged = swing.ranged
    if swing.ranged then bar:SetStatusBarColor(0.4, 0.9, 0.4) else bar:SetStatusBarColor(0.9, 0.9, 0.9) end
  end
  if ns.Vis(bar, true) then ns.ChainBelow(f) end
end)
