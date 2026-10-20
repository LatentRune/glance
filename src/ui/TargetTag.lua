-- ui/TargetTag.lua: corner brackets around the target's bars and a small tag above their
-- outer end (left of the kill pace, ui/KillPace.lua), saying what it is: ELITE, RARE, BOSS,
-- the enemy faction, or your own faction in green for a player on your side, and PVP when
-- it's flagged. RUNNER, when it's about to flee, sits above all of that, over the bars'
-- outer end, and flashes with the brackets. The brackets take the color of the tag's first part (RUNNER's if alone). The frame and tag are made with the group (ui/Group.lua, f.classFrame).
-- From features/TargetClass.lua and Runners.lua.
-- Settings: "enemyfaction", "runner", "pvptag".

local ADDON, ns = ...

local FACTION_STYLE = { Horde = { 0.95, 0.15, 0.1, "HORDE" }, Alliance = { 0.2, 0.5, 1, "ALLIANCE" } }
local ALLY_STYLE = { Horde = { 0.3, 0.9, 0.35, "HORDE" }, Alliance = { 0.3, 0.9, 0.35, "ALLIANCE" } }  -- your own side: green
local RUNNER_STYLE = { 1, 0.35, 0.2 }
local PVP_FRIEND, PVP_FOE = { 0.3, 1, 0.3 }, { 1, 0.3, 0.3 }

-- The tag's parts and the first part's color, refilled with each redraw.
local tagParts, tagColor = {}, nil
local function AddTag(text, c)
  tagParts[#tagParts + 1] = text
  tagColor = tagColor or c
end

local function UpdateTag(f)
  local cf = f.classFrame
  for i = #tagParts, 1, -1 do tagParts[i] = nil end
  tagColor = nil
  local faction = ns.On(f, "enemyfaction")
    and (FACTION_STYLE[ns.EnemyFaction(f.unit) or ""] or ALLY_STYLE[ns.AllyFaction(f.unit) or ""])
  if faction then AddTag(faction[4], faction)
  elseif f.tagStyle then AddTag(f.tagStyle[4], f.tagStyle) end
  if f.pvpFlag and ns.On(f, "pvptag") then AddTag("PVP", UnitIsFriend("player", f.unit) and PVP_FRIEND or PVP_FOE) end
  local text, color = table.concat(tagParts, ", "), tagColor or (f.runner and RUNNER_STYLE) or nil
  -- Applied only when it changes.
  if text ~= cf.tagText or color ~= cf.tagColor then
    cf.tagText, cf.tagColor = text, color
    if color then
      for _, e in ipairs(cf.edges) do e:SetColorTexture(color[1], color[2], color[3], 1) end
      cf.tag:SetText(text)
      cf.tag:SetTextColor(color[1], color[2], color[3])
    end
  end
  local paced = f.pace and (f.pace:GetText() or "") ~= "" and f.pace:IsShown() or false
  if cf.paced ~= paced then
    cf.paced = paced
    cf.tag:ClearAllPoints()
    if paced then cf.tag:SetPoint("RIGHT", f.pace, "LEFT", -6, 0)
    else cf.tag:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4) end
  end
  ns.Vis(cf.runnerText, f.runner and true or false)
  ns.Vis(cf, text ~= "" or f.runner and true or false)
end

ns.Hook("create", function(f)
  local cf = f.classFrame
  if not cf then return end
  cf.runnerText = cf:CreateFontString(nil, "OVERLAY")
  cf.runnerText:SetFont(ns.FONT, 12, "OUTLINE")
  cf.runnerText:SetText("RUNNER")
  cf.runnerText:SetTextColor(RUNNER_STYLE[1], RUNNER_STYLE[2], RUNNER_STYLE[3])
  cf.runnerText:Hide()
end)

-- RUNNER sits over the outer end of the target's bars, above the target of target and the tag.
ns.Hook("geometry", function(f)
  local cf = f.classFrame
  if not cf then return end
  cf.runnerText:ClearAllPoints()
  cf.runnerText:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 8 + ns.SlimHeight(ns.db[f.unit]) + 5)
end)

ns.Hook("redraw", function(f)
  if f.unit == "player" then return end
  f.runner = ns.On(f, "runner") and UnitExists(f.unit) and ns.IsRunner(f.unit)
  UpdateTag(f)
end)

-- Every frame: a runner's brackets and RUNNER flash.
ns.EveryFrame("alerts", function(f)
  if not f.classFrame then return end
  if f.runner or f.edgesPulsing then
    f.edgesPulsing = f.runner
    local a = f.runner and (0.2 + 0.8 * math.abs(math.sin(GetTime() * 7))) or 1
    for _, e in ipairs(f.classFrame.edges) do ns.Alpha(e, a) end
    if f.classFrame.runnerText then ns.Alpha(f.classFrame.runnerText, a) end
  end
end)
