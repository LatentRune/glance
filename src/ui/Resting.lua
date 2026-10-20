-- ui/Resting.lua: while you're resting (an inn or a city) and still earning rested
-- experience, a softly pulsing "Zzz" sits above your level. It stays solid while your
-- idle bars are faded (ui/Fade.lua), since resting is exactly when they fade.
-- Setting: "resting".

local ADDON, ns = ...

local COLOR = { 0.45, 0.65, 1 }  -- the game's rested-experience blue

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.resting = f:CreateFontString(nil, "OVERLAY")
  f.resting:SetFont(ns.FONT, 11, "OUTLINE")
  f.resting:SetPoint("BOTTOM", f.level, "TOP", 0, 2)
  f.resting:SetText("Zzz")
  f.resting:SetTextColor(COLOR[1], COLOR[2], COLOR[3])
  if f.resting.SetIgnoreParentAlpha then f.resting:SetIgnoreParentAlpha(true) end
  ns.Vis(f.resting, false)
end)

-- Rested experience stops at the level cap, so the Zzz does too.
local function EarningRest()
  if not (IsResting and IsResting()) then return false end
  local cap = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
  return (UnitLevel("player") or 0) < cap
end

ns.Hook("redraw", function(f)
  if f.unit ~= "player" then return end
  ns.Vis(f.resting, ns.On(f, "resting") and EarningRest() and not ns.Minimal())
end)

ns.EveryFrame("alerts", function(f)
  if f.unit ~= "player" or not f.resting.vis then return end
  ns.Alpha(f.resting, 0.55 + 0.45 * math.abs(math.sin(GetTime() * 1.5)))
end)
