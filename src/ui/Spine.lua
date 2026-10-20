-- ui/Spine.lua: the gap between your bars and the target's, where what you share with
-- the target sits: the track (shown in combat, ui/CombatMarker.lua) and the threat flame
-- that climbs it (ui/ThreatMeter.lua), and here, under the track, the count of mobs on
-- you: a red diamond with the number, once there's more than one, flashing above two. The count comes from
-- features/Attackers.lua. Setting: "adds".

local ADDON, ns = ...

local FONT = ns.FONT
local SPINE_DEFAULT, SPINE_MAX = 12, 30  -- half the gap, in pixels
-- The spine's track: from above the bars (level with the target of target) to below them.
local TRACK_ABOVE, TRACK_BELOW = 18, 18
-- Its color: the same as a bar's empty part, so the threat fill reads like any other bar.
ns.TRACK = { 0.07, 0.07, 0.08, 0.92 }

---Where the spine's track runs on your group: its x from your bars' inner edge, its top
---above them, and its length (all in your group's pixels).
---@return number x, number top, number length
function ns.SpineTrack()
  local p = ns.groups.player
  local h = p.contentHeight or p:GetHeight()
  return p.spineX or 0, TRACK_ABOVE, h + TRACK_ABOVE + TRACK_BELOW
end

---Half the gap between the two groups, in screen pixels (or a default while the
---target's bars are hidden), capped so far-apart bars keep these close by. Also returns
---the whole gap when there is one.
---@return number half, number|nil gap
function ns.SpineHalf()
  local p, t = ns.groups.player, ns.groups.target
  if p and t and t:IsShown() then
    local pr, tl = p:GetRight(), t:GetLeft()
    if pr and tl then
      local gap = tl * t:GetEffectiveScale() - pr * p:GetEffectiveScale()
      if gap >= 8 then return math.min(gap / 2, SPINE_MAX * p:GetEffectiveScale()), gap end
    end
  end
  return SPINE_DEFAULT * (p and p:GetEffectiveScale() or 1)
end

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  local ag = CreateFrame("Frame", nil, f)
  ag:SetSize(24, 24)
  ag.edge = ag:CreateTexture(nil, "BORDER")
  ag.edge:SetPoint("CENTER"); ag.edge:SetSize(19, 19)
  ag.edge:SetColorTexture(1, 0.25, 0.2, 1)
  ag.fill = ag:CreateTexture(nil, "ARTWORK")
  ag.fill:SetPoint("CENTER"); ag.fill:SetSize(15, 15)
  ag.fill:SetColorTexture(0.35, 0.05, 0.05, 1)
  for _, t in ipairs({ ag.edge, ag.fill }) do if t.SetRotation then t:SetRotation(math.pi / 4) end end  -- squares turned into diamonds
  ag.count = ag:CreateFontString(nil, "OVERLAY")
  ag.count:SetFont(FONT, 15, "OUTLINE")
  ag.count:SetPoint("CENTER", 0, 0)
  ag:Hide()
  f.aggroBadge = ag
end)

ns.Hook("redraw", function(f)
  if f.unit == "player" then f.aggro = ns.On(f, "adds") and ns.AttackerCount() or 0 end
end)

-- Every frame: kept centered in the gap as the bars slide or are moved.
local function UpdateSpine(f)
  local half = ns.SpineHalf()
  local sx = math.floor(half / f:GetEffectiveScale() + 0.5)
  local h = f.contentHeight or f:GetHeight()
  local ag = f.aggroBadge
  local n = ns.On(f, "adds") and f.aggro or 0
  if ns.Vis(ag, n >= 2) or ag.aggro ~= n then ag.aggro = n; ns.Text(ag.count, n) end
  if f.spineX == sx and f.spineH == h then return end
  f.spineX, f.spineH = sx, h
  f.spineGlow:ClearAllPoints()
  f.spineGlow:SetPoint("TOP", f, "TOPRIGHT", sx, TRACK_ABOVE)
  f.spineGlow:SetHeight(h + TRACK_ABOVE + TRACK_BELOW)
  ag:ClearAllPoints()
  ag:SetPoint("TOP", f, "TOPRIGHT", sx, -h - TRACK_BELOW - 3)  -- just under the track
end

ns.EveryFrame("timers", function(f)
  if f.unit ~= "player" then return end
  UpdateSpine(f)
  -- The count flashes above 2, faster with each mob beyond that.
  local ag = f.aggroBadge
  if ag.vis then
    local over = (ag.aggro or 0) - 2
    ns.Alpha(ag, over > 0 and (0.35 + 0.65 * math.abs(math.cos(GetTime() * (2 + 2.5 * over)))) or 1)
  end
end)
