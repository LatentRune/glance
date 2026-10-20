-- ui/AlertsRow.lua: the row of alerts under your debuffs, from the right: a potion or
-- healthstone that's ready when you're below 30% (pulsing), buffs you usually keep up
-- that dropped (desaturated, red edge; right-click one to dismiss it), then text:
-- "+2 INCOMING" for mobs heading your way, and for hunters TOO CLOSE and ammo warnings.
--
-- From features/Consumables.lua, BuffMemory.lua, Attackers.lua and Hunter.lua.
-- Settings: "potion", "buffs", "addwarn", "hunter".

local ADDON, ns = ...

local FONT = ns.FONT
local MAX_ICONS = 5

local UpdateAlerts  -- below

local function pulse(speed) return math.abs(math.sin(GetTime() * (speed or 6))) end

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.alerts = CreateFrame("Frame", nil, f)
  f.alerts.icons = {}
  f.alerts.text = f.alerts:CreateFontString(nil, "OVERLAY")
  f.alerts.text:SetFont(FONT, 11, "OUTLINE")
  f.alerts:Hide()
  f.below[#f.below + 1] = f.alerts  -- under the debuffs (ui/Stack.lua)
end)

ns.Hook("geometry", function(f)
  if f.unit ~= "player" then return end
  local pos = ns.db.player
  f.alerts.size = math.min(pos.healthHeight, ns.ICON_BASE) + 2
  f.alerts:SetHeight(f.alerts.size)
  f.alerts.text:SetFont(FONT, math.max(pos.fontSize, 8), "OUTLINE")
end)

local function AlertIcon(row, i)
  local ic = row.icons[i]
  if ic then return ic end
  ic = CreateFrame("Frame", nil, row)
  local border = ic:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  ic.border = border
  ic.tex = ic:CreateTexture(nil, "ARTWORK")
  ic.tex:SetPoint("TOPLEFT", 1, -1); ic.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  ic.count = ic:CreateFontString(nil, "OVERLAY")
  ic.count:SetFont(FONT, 9, "OUTLINE")
  ic.count:SetPoint("BOTTOMRIGHT", -1, 1)
  -- Hover for what it is. Right-click a buff reminder to dismiss it; left clicks and drags
  -- still fall through to the camera.
  ic:EnableMouse(true)
  local rightOnly = ic.SetPassThroughButtons and pcall(ic.SetPassThroughButtons, ic, "LeftButton")
  if not rightOnly and ic.SetMouseClickEnabled then ic:SetMouseClickEnabled(false) end
  ic:SetScript("OnMouseUp", function(self, button)
    if button ~= "RightButton" or not self.buff then return end
    ns.DismissBuff(self.buff)
    GameTooltip:Hide()
    UpdateAlerts(ns.groups.player)
  end)
  ic:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    local b = self.buff and ns.BuffHistory(self.buff)
    if self.itemID then
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:AddLine("Ready to use: you're below 30% health.", 0.3, 1, 0.3, true)
    elseif b then
      GameTooltip:SetText(self.buff, 1, 0.82, 0)
      GameTooltip:AddLine(string.format("Missing. You've had it up in %d of your last %d fights.",
        math.floor(b.up + 0.5), b.total), 1, 0.3, 0.3, true)
      GameTooltip:AddLine("Right-click to dismiss until you die or log out.", 0.6, 0.6, 0.6, true)
    end
    GameTooltip:Show()
  end)
  ic:SetScript("OnLeave", function() GameTooltip:Hide() end)
  row.icons[i] = ic
  return ic
end

-- One alert icon, the n-th from the right; returns the new count.
local function PutAlert(row, size, n, icon, count, potion, itemID, buff)
  n = n + 1
  local ic = AlertIcon(row, n)
  if ic.placedAt ~= size then
    ic.placedAt = size
    ic:SetSize(size, size)
    ic:ClearAllPoints()
    ic:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(n - 1) * (size + 2), 0)
  end
  if ic.icon ~= icon or ic.potion ~= potion then
    ic.icon = icon
    ic.tex:SetTexture(icon)
    ic.tex:SetDesaturated(not potion)  -- a missing buff shows gray
    if potion then ic.border:SetColorTexture(0.3, 1, 0.3, 1) else ic.border:SetColorTexture(1, 0.2, 0.2, 1) end
  end
  ns.Text(ic.count, (count or 0) > 1 and count or "")
  ic.potion, ic.itemID, ic.buff = potion, itemID, buff
  if potion then row.potionIcon = ic else ns.Alpha(ic, 1) end
  if not ic:IsShown() then ic:Show() end
  return n
end

UpdateAlerts = function(f)
  local row = f.alerts
  local size = row.size or 18
  local n = 0
  if row.potionIcon then ns.Alpha(row.potionIcon, 1); row.potionIcon = nil end
  local max = UnitHealthMax("player") or 0
  if ns.On(f, "potion") and max > 0 and UnitHealth("player") / max < 0.3 and not UnitIsDeadOrGhost("player") then
    local id = ns.ReadyHeal()
    if id then n = PutAlert(row, size, n, ns.ItemIcon(id), GetItemCount(id), true, id) end
  end
  if ns.On(f, "buffs") then
    for _, name in ipairs(ns.MissingBuffs()) do
      if n < MAX_ICONS then n = PutAlert(row, size, n, ns.BuffHistory(name).icon, nil, nil, nil, name) end
    end
  end
  for i = n + 1, #row.icons do if row.icons[i]:IsShown() then row.icons[i]:Hide() end end
  local icons = n

  -- The text, left of the icons. Kept in one reused list: this runs on every redraw.
  local lines = row.lines or {}
  row.lines = lines
  for i = #lines, 1, -1 do lines[i] = nil end
  local coming = ns.On(f, "addwarn") and ns.IncomingCount() or 0
  if coming > 0 then
    local a = math.floor((0.45 + 0.55 * pulse(8)) * 255)
    lines[#lines + 1] = string.format("|c%02xff7020+%d INCOMING|r", a, coming)
  end
  if ns.CLASS == "HUNTER" and ns.On(f, "hunter") then
    if ns.DeadZone() then lines[#lines + 1] = "|cffff4433TOO CLOSE|r" end
    lines[#lines + 1] = ns.AmmoAlert()
  end
  local x = -(icons * (size + 2) + (icons > 0 and 2 or 0))
  if row.textX ~= x or row.textSize ~= size then
    row.textX, row.textSize = x, size
    row.text:ClearAllPoints()
    row.text:SetPoint("RIGHT", row, "TOPRIGHT", x, -size / 2)
  end
  ns.Text(row.text, table.concat(lines, "  "))

  local want = icons > 0 or #lines > 0
  if want ~= row:IsShown() then row:SetShown(want); ns.ChainBelow(f) end
end

ns.Hook("redraw", function(f)
  if f.unit == "player" then UpdateAlerts(f) end
end)

-- Every frame: the potion pulses.
ns.EveryFrame("alerts", function(f)
  local potion = f.unit == "player" and f.alerts.potionIcon
  if potion then ns.Alpha(potion, 0.4 + 0.6 * pulse(5)) end
end)
