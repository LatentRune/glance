-- ui/RaidMarker.lua: the raid mark on you or your target (skull, cross...), beside the
-- level: left of yours, right of the target's. Hidden on the target while its mark
-- buttons show the mark instead (ui/RaidMarks.lua). Setting: "marker".

local ADDON, ns = ...

local MARKERS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

ns.Hook("create", function(f)
  f.marker = f:CreateTexture(nil, "OVERLAY")
  f.marker:SetTexture(MARKERS)
  f.marker:Hide()
end)

ns.Hook("geometry", function(f)
  local ih = math.min(ns.db[f.unit].healthHeight, ns.ICON_BASE)
  f.marker:SetSize(ih + 2, ih + 2)
end)

ns.Hook("redraw", function(f)
  local idx = ns.On(f, "marker") and GetRaidTargetIndex and GetRaidTargetIndex(f.unit)
  if not idx or (f.markBtns and f.markBtns:IsShown()) then f.marker:Hide(); return end
  SetRaidTargetIconTexture(f.marker, idx)
  local anchor = f.pvp:IsShown() and f.pvp or f.level
  f.marker:ClearAllPoints()
  if f.unit == "player" then f.marker:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
  else f.marker:SetPoint("LEFT", anchor, "RIGHT", 2, 0) end
  f.marker:Show()
end)
