-- ui/widgets/AuraIcon.lua: one icon on a debuff or buff row: the texture, a colored
-- edge, a clock sweep that darkens the part of its time already gone, with a bright hand
-- (once around over the aura's whole duration), a countdown in the middle and a stack count in the corner.
--
-- Besides real auras, a row carries reminders that aren't auras: warnings
-- (features/Warnings.lua) and a few kinds of their own (breath, loot, a mob's known
-- casts). Those set ic.fake to their key, and their tooltip and right-click come from
-- ns.warningsByKey or ns.iconKinds below.

local ADDON, ns = ...

local FONT = ns.FONT

-- Real debuffs get a red edge, as in the game's own frames; reminders have their own colors.
ns.RED_EDGE = { 0.75, 0.1, 0.1, 1 }

-- Icons that aren't auras or warnings, by ic.fake: { tip = fun(tooltip, icon),
-- dismiss = fun() (optional: right-click hides it) }.
ns.iconKinds = {}

---The kind behind a reminder icon (a warning or an ns.iconKinds entry), or nil for a
---real aura.
function ns.IconKind(fake)
  return fake and (ns.warningsByKey[fake] or ns.iconKinds[fake])
end

---Run an icon's clock for an aura lasting `duration` seconds that ends at `expires`, or
---stop it (no duration).
function ns.SetClock(ic, duration, expires)
  local clock = ic.clock
  if duration and duration > 0 and expires and clock.SetCooldown then
    if ic.clockEnd ~= expires or ic.clockDur ~= duration then
      ic.clockEnd, ic.clockDur = expires, duration
      clock:SetCooldown(expires - duration, duration)
    end
    if not clock:IsShown() then
      clock:Show()
      clock:SetCooldown(expires - duration, duration)  -- a hidden clock may have dropped it
    end
  elseif ic.clockEnd then
    ic.clockEnd, ic.clockDur = nil, nil
    if clock.Clear then clock:Clear() end
    clock:Hide()
  end
end

---The i-th icon of a row, made the first time it's needed. Icons are kept and reused.
function ns.AuraIcon(row, i)
  local ic = row.icons[i]
  if ic then return ic end
  ic = CreateFrame("Frame", nil, row)
  ic.tex = ic:CreateTexture(nil, "ARTWORK")
  ic.tex:SetPoint("TOPLEFT", 1, -1); ic.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim the icon's own border
  local RED = ns.RED_EDGE
  local bg = ic:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(); bg:SetColorTexture(RED[1], RED[2], RED[3], RED[4])
  ic.bg, ic.edge = bg, RED
  -- The clock: reversed, so what's dark is the time that has passed, with a bright hand
  -- on its leading edge.
  local clock = CreateFrame("Cooldown", nil, ic, "CooldownFrameTemplate")
  clock:SetPoint("TOPLEFT", 1, -1); clock:SetPoint("BOTTOMRIGHT", -1, 1)
  if clock.SetReverse then clock:SetReverse(true) end
  if clock.SetDrawSwipe then clock:SetDrawSwipe(true) end
  if clock.SetSwipeTexture then clock:SetSwipeTexture(ns.TEX) end
  if clock.SetSwipeColor then clock:SetSwipeColor(0, 0, 0, 0.8) end
  if clock.SetEdgeTexture then clock:SetEdgeTexture("Interface\\Cooldown\\edge") end
  if clock.SetDrawEdge then clock:SetDrawEdge(true) end
  if clock.SetDrawBling then clock:SetDrawBling(false) end
  if clock.SetHideCountdownNumbers then clock:SetHideCountdownNumbers(true) end  -- ours is below
  clock.noCooldownCount = true  -- and not a cooldown-count addon's
  if clock.EnableMouse then clock:EnableMouse(false) end
  clock:Hide()
  ic.clock = clock
  -- The countdown and stack count ride above the clock.
  local over = CreateFrame("Frame", nil, ic)
  over:SetAllPoints()
  over:SetFrameLevel(ic:GetFrameLevel() + 3)
  ic.time = over:CreateFontString(nil, "OVERLAY")
  ic.time:SetFont(FONT, 10, "OUTLINE")
  ic.time:SetPoint("CENTER", 0, 0)
  ic.count = over:CreateFontString(nil, "OVERLAY")
  ic.count:SetFont(FONT, 9, "OUTLINE")
  ic.count:SetPoint("BOTTOMRIGHT", -1, 1)
  -- Hover for the debuff's tooltip; clicks still fall through to the camera.
  ic:EnableMouse(true)
  if ic.SetMouseClickEnabled then ic:SetMouseClickEnabled(false) end
  ic:SetScript("OnEnter", function(self)
    if self.tip then  -- an icon with a tooltip of its own (a crowd control timer, a totem)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
      self.tip(GameTooltip, self)
      GameTooltip:Show()
      return
    end
    local kind = ns.IconKind(self.fake)
    if kind then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
      kind.tip(GameTooltip, self)
      GameTooltip:Show()
      return
    end
    if not self.index or not UnitExists(self.unit) then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnitAura(self.unit, self.index, self.filter)
    GameTooltip:Show()
  end)
  ic:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- Only reminders you can dismiss take clicks (right-click hides them); see ui/DebuffRow.lua.
  ic:SetScript("OnMouseUp", function(self, button)
    if button ~= "RightButton" then return end
    local kind = ns.IconKind(self.fake)
    if not (kind and kind.dismiss) then return end
    kind.dismiss()
    GameTooltip:Hide()
    local f = ns.groups.player
    if f and ns.RedrawDebuffs then ns.RedrawDebuffs(f) end
  end)
  row.icons[i] = ic
  return ic
end
