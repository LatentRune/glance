-- ui/ComboBar.lua: combo points as a strip of segments along the top of a health bar,
-- lit gold as they build.
--   Yours, on the target's health, built from its inner end: shown for rogues and
--   cat-form druids on a target you can fight. Counts from features/Supplies.lua.
--   An enemy's on you, on your health, built from your inner end (right to left): counted
--   by features/EnemyCombo.lua.
-- Settings: "combo" (yours), "enemycombo" (on you).
--
-- The target's strip back is made with the group (ui/Group.lua, f.combo.back); yours is
-- made here. Segments are made as needed, on the health bar itself so the name stays on top.

local ADDON, ns = ...

local GAP = 2  -- pixels between segments

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  local back = f.bars.health:CreateTexture(nil, "ARTWORK", nil, 2)  -- dark, so lit segments stand out
  back:SetPoint("TOPLEFT"); back:SetPoint("TOPRIGHT")
  back:SetColorTexture(0, 0, 0, 0.8)
  back:Hide()
  f.combo = { segs = {}, back = back, fromRight = true }
end)

-- Show `cur` of `max` points on a group's strip, or hide it.
local function DrawCombo(f, show, cur, max)
  local strip, h = f.combo, f.bars.health
  if strip.vis ~= show then
    strip.vis = show
    strip.back:SetShown(show)
    for i, t in ipairs(strip.segs) do
      t:SetShown(show and i <= (strip.max or 0)); t.edge:SetShown(t:IsShown())
    end
  end
  if not show then return end
  local w, hgt = h.w or h:GetWidth(), math.max(3, math.floor((h.hgt or h:GetHeight()) / 5))
  -- Laid out again only when the number of points or the bar's size changes.
  if strip.max ~= max or strip.w ~= w or strip.hgt ~= hgt then
    strip.max, strip.w, strip.hgt, strip.cur = max, w, hgt, nil
    strip.back:SetHeight(hgt + 1)
    local segW = (w - (max - 1) * GAP) / max
    for i = 1, math.max(max, #strip.segs) do
      local t = strip.segs[i]
      if i <= max then
        if not t then
          t = h:CreateTexture(nil, "ARTWORK", nil, 4); strip.segs[i] = t
          -- A black outline behind each point, so lit ones read on any bar color.
          t.edge = h:CreateTexture(nil, "ARTWORK", nil, 3)
          t.edge:SetColorTexture(0, 0, 0, 1)
          t.edge:SetPoint("TOPLEFT", t, -1, 1); t.edge:SetPoint("BOTTOMRIGHT", t, 1, -1)
        end
        local x = (i - 1) * (segW + GAP) + 1
        t:ClearAllPoints()
        if strip.fromRight then t:SetPoint("TOPRIGHT", h, "TOPRIGHT", -x, -1)
        else t:SetPoint("TOPLEFT", h, "TOPLEFT", x, -1) end
        t:SetSize(segW - 2, hgt - 1)
        t:Show(); t.edge:Show()
      elseif t then
        t:Hide(); t.edge:Hide()
      end
    end
  end
  if strip.cur == cur then return end
  strip.cur = cur
  for i = 1, max do
    if i <= cur then strip.segs[i]:SetColorTexture(1, 0.85, 0.1, 1)
    else strip.segs[i]:SetColorTexture(0.3, 0.27, 0.15, 0.6) end
  end
end

ns.Hook("redraw", function(f)
  if not f.combo then return end
  if f.unit == "player" then
    local n = ns.On(f, "enemycombo") and not f.dead and ns.EnemyComboOnMe() or 0
    DrawCombo(f, n > 0, n, 5)
  else
    local show = ns.UsesCombo() and ns.On(f, "combo") and UnitExists(f.unit)
      and UnitCanAttack("player", f.unit) and not UnitIsDeadOrGhost(f.unit)
    local cur, max = 0, 5
    if show then cur, max = ns.ComboPoints() end
    DrawCombo(f, show and true or false, cur, max)
  end
end)
