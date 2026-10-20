-- ui/TargetOfTarget.lua: who your target is attacking, in a slim bar above the spine end
-- of the target's bars, half their width. When it's you it says YOU in red, blinking for
-- a few seconds after it switches to you. Setting: "tot".

local ADDON, ns = ...

ns.Hook("create", function(f, mirrored)
  if f.unit == "player" then return end
  f.tot = ns.SlimBar(f, mirrored)
  f.tot.halfWidth = true
  f.tot:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 8)
end)

local BLINK = 3  -- seconds YOU blinks after the target turns to you

ns.Hook("geometry", function(f)
  if not f.tot then return end
  local pos = ns.db[f.unit]
  local slimH, minimal = ns.SlimHeight(pos), ns.Minimal()
  f.tot:SetHeight(slimH); f.tot.hgt = slimH; ns.SetBarFont(f.tot, math.max(pos.fontSize - 2, 6))
  f.tot:SetWidth(pos.width * 0.5); f.tot.w = pos.width * 0.5
  f.tot.showPct = not minimal; ns.Backing(f.tot, not minimal)
end)

ns.Hook("redraw", function(f)
  if f.tot then ns.UnitBar(f, f.tot, "targettarget", ns.On(f, "tot")) end
end)

ns.Hook("preview", function(f)
  if not f.tot then return end
  ns.SetBar(f.tot, 1, 1, "> Target of target", 0.3, 0.8, 0.3)
  ns.Text(f.tot.pct, "")
  f.tot:Show()
end)

ns.EveryFrame("timers", function(f, dt)
  if not (f.tot and f.exists) then return end
  ns.Animate(f.tot, dt)
  local t, label = GetTime(), f.tot.label
  if f.tot.onYou and f.tot.onYouAt and t - f.tot.onYouAt < BLINK then
    ns.Alpha(label, math.floor(t * 5) % 2 == 0 and 1 or 0.15)
  else
    ns.Alpha(label, 1)
  end
end)
