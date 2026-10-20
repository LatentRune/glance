-- ui/ExecuteZone.lua: for warriors (Execute) and paladins (Hammer of Wrath), a gold tick
-- at 20% on the target's health, and orange corner brackets pulsing around the bar once
-- it's below: the kill-shot reticle. Whether you can is features/Execute.lua.
-- Setting: "execute".

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  local hb = f.bars.health
  local x = {}
  x.tick = hb:CreateTexture(nil, "OVERLAY", nil, 5)
  x.tick:SetColorTexture(1, 0.85, 0.3, 0.9)
  x.tick:SetWidth(1)
  x.edges = ns.Brackets(hb, hb, 2, "OVERLAY", 6, 1, 0.35, 0.1)
  for _, t in ipairs(x.edges) do ns.Vis(t, false) end
  ns.Vis(x.tick, false)
  hb.exec = x
end)

-- With each redraw: where the tick goes and whether the target is in the zone.
ns.Hook("redraw", function(f)
  local x = f.bars.health.exec
  if not x then return end
  local show = ns.On(f, "execute") and ns.CanExecute() and f.exists and not f.dead
    and (f.hpMax or 0) > 0 and UnitCanAttack("player", f.unit) or false
  f.inExecute = show and f.hp / f.hpMax <= ns.EXECUTE_AT or false
  if ns.Vis(x.tick, show) or show then
    local hb = f.bars.health
    local w = hb.w or hb:GetWidth()
    local at = math.floor(w * ns.EXECUTE_AT + 0.5)
    if x.at ~= at or x.rev ~= hb.reversed then
      x.at, x.rev = at, hb.reversed
      x.tick:ClearAllPoints()
      if hb.reversed then x.tick:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -at, 0); x.tick:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", -at, 0)
      else x.tick:SetPoint("TOPLEFT", hb, "TOPLEFT", at, 0); x.tick:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", at, 0) end
    end
  end
end)

-- Every frame: the brackets pulse while the target is in the zone.
ns.EveryFrame("timers", function(f)
  local x = f.exists and f.bars.health.exec
  if not x then return end
  local a = f.inExecute and (0.35 + 0.65 * math.abs(math.sin(GetTime() * 5))) or nil
  for _, t in ipairs(x.edges) do
    ns.Vis(t, a ~= nil)
    if a then ns.Alpha(t, a) end
  end
end)
