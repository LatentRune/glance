-- ui/KillPace.lua: how long this kind of mob usually takes you ("~12s"), and during
-- a fight how long this one has taken so far, red once it runs well past usual. Above the
-- outer end of the target's bars, right of its tag. From features/KillPace.lua.
-- Setting: "pace".

local ADDON, ns = ...

local FONT = ns.FONT

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  f.pace = f:CreateFontString(nil, "OVERLAY")
  f.pace:SetFont(FONT, 10, "OUTLINE")
  f.pace:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4)
end)

ns.Hook("geometry", function(f)
  if not f.pace then return end
  f.pace:SetShown(not ns.Minimal())
  f.pace:SetFont(FONT, math.max(ns.db[f.unit].fontSize - 2, 6) + 1, "OUTLINE")
end)

ns.Hook("redraw", function(f)
  if not f.pace then return end
  local unit, text = f.unit, ""
  local npc = ns.On(f, "pace") and UnitCanAttack("player", unit) and not UnitIsDeadOrGhost(unit) and ns.NpcID(UnitGUID(unit))
  local c = ns.FightStats(npc)
  if c and c.n >= 2 then  -- two fights before there's a usual
    local avg = c.time / c.n
    local start = ns.FightStart(UnitGUID(unit))
    if start then
      local so = GetTime() - start
      local col = so > avg * 1.5 and "ff5544" or "c0c0c0"
      text = string.format("|cff%s%ds|r |cff808080/ ~%ds|r", col, math.floor(so), math.floor(avg + 0.5))
    else
      text = string.format("|cff808080~%ds|r", math.floor(avg + 0.5))
    end
  end
  ns.Text(f.pace, text)
end)

ns.Hook("preview", function(f)
  if not f.pace then return end
  ns.Text(f.pace, "|cff808080~12s|r")
end)
