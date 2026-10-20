-- ui/DebuffRow.lua: the row of icons under each group's bars.
--
-- Under yours, from the right: reminders first (your breath underwater, kills that still
-- have loot, then each warning from features/Warnings.lua), then the debuffs on you,
-- newest at the edge. Under the target's, from the left: your debuffs on it, pulsing when
-- about to run out. Other files share the row: your short buffs (ui/BuffRow.lua) and the
-- target's known casts (ui/MobAbilities.lua) fill it from the other end.
--
-- Icons are ui/widgets/AuraIcon.lua. Settings: "debuffs", "expireflash" (the target's),
-- "loot", "breath", and each warning's key.

local ADDON, ns = ...

local LOOT_ICON = "Interface\\Icons\\INV_Misc_Bag_08"
local BREATH_ICON = "Interface\\Icons\\Spell_Shadow_DemonBreath"  -- Unending Breath

-- The loot reminder: hover for how many, right-click to hide it until your next kill
-- with loot. (The breath reminder's kind is in ui/Breath.lua.)
ns.iconKinds.loot = {
  edge = { 1, 0.82, 0, 1 },
  tip = function(tip, ic)
    local n = ic.loot or 0
    tip:SetText("Loot", 1, 0.82, 0)
    tip:AddLine(n == 1 and "1 of your kills still has loot on it." or (n .. " of your kills still have loot on them."), 1, 1, 1, true)
    tip:AddLine("Goes away once you loot them. Right-click to hide it until your next kill with loot. Hidden in combat.", 0.7, 0.7, 0.7, true)
  end,
  dismiss = function() ns.DismissLoot() end,
}

ns.Hook("create", function(f)
  f.debuffs = CreateFrame("Frame", nil, f)
  f.debuffs.icons = {}
  f.debuffs.alignRight = f.unit == "player"  -- yours from the right, the target's from the left
  f.debuffs:Hide()
end)

ns.Hook("geometry", function(f)
  f.debuffs.size = math.min(ns.db[f.unit].healthHeight, ns.ICON_BASE) + 2
  f.debuffs:SetHeight(f.debuffs.size)
  f.debuffs.lines = 1
end)

---Fill the next entry of a kept list of icons to draw; returns the new count.
function ns.AddAura(list, n, icon, count, duration, expires, index, filter)
  n = n + 1
  local a = list[n] or {}
  list[n] = a
  a.icon, a.count, a.duration, a.expires, a.index, a.filter = icon, count, duration, expires, index, filter
  a.fake, a.text, a.edge, a.flash = nil, nil, nil, nil
  return n
end
local AddAura = ns.AddAura

---Redraw a row of debuffs: the group's own row by default, or another row and unit (your
---pet's, ui/PetDebuffs.lua). preview fills it with samples while placing the bars.
function ns.RedrawDebuffs(f, preview, row, unit)
  row, unit = row or f.debuffs, unit or f.unit
  -- Entries are kept and refilled: this runs on every redraw.
  local list = row.list or {}
  row.list = list
  local n = 0
  -- Reminders, on your own row only.
  local mine = row == f.debuffs and f.unit == "player" and not preview
  local air = mine and ns.On(f, "breath") and ns.Breath()
  if air then
    n = AddAura(list, n, BREATH_ICON, 0, 0)
    list[n].fake = "breath"
  end
  local loot = mine and ns.On(f, "loot") and not ns.inCombat and ns.LootCount() or 0
  if loot > 0 then
    n = AddAura(list, n, LOOT_ICON, loot, 0)
    list[n].fake = "loot"
  end
  -- Worn gear, full bags, how you died: each until fixed or right-clicked away.
  if mine then
    for _, w in ipairs(ns.warnings) do
      if ns.On(f, w.key) then
        local show, count, text, edge, flash = w.check()
        if show then
          n = AddAura(list, n, w.icon, count or 0, 0)
          local a = list[n]
          a.fake, a.text, a.edge, a.flash = w.key, text, edge or w.edge, flash
        end
      end
    end
  end
  if preview then
    n = AddAura(list, n, "Interface\\Icons\\Spell_Shadow_ShadowWordPain", 0, 18, GetTime() + 12)
    n = AddAura(list, n, "Interface\\Icons\\Ability_Warrior_Sunder", 3, 30, GetTime() + 21)
  elseif ns.On(f, "debuffs") and UnitExists(unit) then
    -- On the target, only the debuffs you put there.
    local filter = unit == "target" and "HARMFUL|PLAYER" or "HARMFUL"
    local auras = ns.AuraList(unit, filter)
    for i = 1, math.min(auras.n, 8) do
      local a = auras[i]
      n = AddAura(list, n, a.icon, a.count, a.duration, a.expires, a.index, filter)
    end
  end
  local size = row.size or 18
  for i = 1, n do
    local a = list[i]
    local ic = ns.AuraIcon(row, i)
    -- On you and your pet the newest debuff sits at the right edge and older ones move left.
    local x = row.alignRight and -(n - i) * (size + 2) or (i - 1) * (size + 2)
    if ic.placedX ~= x or ic.placedSize ~= size then
      ic.placedX, ic.placedSize = x, size
      ic:SetSize(size, size)
      ic:ClearAllPoints()
      if row.alignRight then ic:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, 0)
      else ic:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0) end
    end
    if ic.icon ~= a.icon then ic.icon = a.icon; ic.tex:SetTexture(a.icon) end
    ns.Text(ic.count, (a.count or 0) > 1 and a.count or "")
    local kind = ns.IconKind(a.fake)
    local e = a.edge or (kind and kind.edge) or ns.RED_EDGE  -- loot gold, breath blue, debuffs red...
    if ic.edge ~= e then ic.edge = e; ic.bg:SetColorTexture(e[1], e[2], e[3], e[4]) end
    if ic.fake ~= a.fake then
      -- The slot held something else: undo what that left behind.
      ns.Alpha(ic, 1)
      ic.drowning, ic.timeLow = nil, nil
      ic.time:SetTextColor(1, 1, 1)
    end
    if ic.fake ~= a.fake and ic.SetMouseClickEnabled then
      -- Right-clicks for reminders you can dismiss; left clicks always fall through to the camera.
      local clicks = kind and kind.dismiss and true or false
      if clicks and ic.SetPassThroughButtons then pcall(ic.SetPassThroughButtons, ic, "LeftButton") end
      ic:SetMouseClickEnabled(clicks)
    end
    ic.fake = a.fake
    if ic.flash and not a.flash then ns.Alpha(ic, 1) end
    ic.flash = a.flash
    ic.loot = a.fake == "loot" and a.count or nil
    if a.fake == "breath" then f.breathIcon = ic end
    ic.expires = (a.duration or 0) > 0 and a.expires or nil
    ns.SetClock(ic, not a.fake and a.duration, ic.expires)
    if a.text then ns.Text(ic.time, a.text)
    elseif not ic.expires and a.fake ~= "breath" then ns.Text(ic.time, "") end  -- a slot can carry over a timer from the debuff it held before
    ic.unit, ic.index, ic.filter = unit, a.index, a.filter
    if GameTooltip:IsOwned(ic) and a.index then GameTooltip:SetUnitAura(unit, a.index, a.filter) end
    if not ic:IsShown() then ic:Show() end
  end
  for i = n + 1, #row.icons do if row.icons[i]:IsShown() then row.icons[i]:Hide() end end
  if not air and row == f.debuffs and f.breathIcon then ns.Alpha(f.breathIcon, 1); f.breathIcon = nil end
  local want = n > 0
  -- The target's known casts take the room the debuffs leave, from the right.
  if row == f.debuffs and f.abilityRow then
    local per = math.max(math.floor(((f.bars.health.w or 180) + 2) / ((row.size or 18) + 2)), 1)
    local room = math.min(per - n - (n > 0 and 1 or 0), ns.MAX_CASTS)
    want = ns.UpdateAbilities(f, math.max(room, 0)) > 0 or want
  end
  -- Your short buffs, from the left, wrapping to a second line when the row is full.
  if row == f.debuffs and f.buffRow then
    local nb, lines = ns.UpdateBuffs(f, n)
    want = want or nb > 0
    local h = lines * (row.size or 18) + (lines - 1) * 2
    if row.lines ~= lines then
      row.lines = lines
      row:SetHeight(h)
      if row:IsShown() then ns.ChainBelow(f) end
    end
  end
  if want ~= row:IsShown() then row:SetShown(want); if not row.above then ns.ChainBelow(f) end end
  ns.AuraFxSync(f, row, unit, preview)
  if row == f.debuffs and f.buffRow then ns.AuraFxSync(f, f.buffRow, "player", preview) end
end

---Countdowns on a row's icons, turning red in the last seconds (row.lowAt, 3 by default).
---Debuffs about to drop off the target pulse (setting "expireflash"), and rows with
---row.flashLow (your buffs) always do.
function ns.UpdateIconTimes(f, row)
  local now = GetTime()
  for _, ic in ipairs((row or f.debuffs).icons) do
    if ic:IsShown() and not ic.fake then
      local left = ic.expires and ic.expires - now
      if left and left > 0 then
        ns.Text(ic.time, left >= 60 and (math.ceil(left / 60) .. "m") or math.ceil(left))
        local low = left < (row and row.lowAt or 3)
        if ic.timeLow ~= low then
          ic.timeLow = low
          if low then ic.time:SetTextColor(1, 0.3, 0.3) else ic.time:SetTextColor(1, 1, 1) end
        end
        if low and (row and row.flashLow or f.unit ~= "player" and ns.On(f, "expireflash")) then
          ns.Alpha(ic, 0.3 + 0.7 * math.abs(math.sin(now * 6)))
        else
          ns.Alpha(ic, 1)
        end
      else
        ns.Text(ic.time, "")
        ns.Alpha(ic, 1)
      end
    end
  end
end

ns.Hook("redraw", function(f) ns.RedrawDebuffs(f) end)

ns.Hook("preview", function(f)
  if f.unit ~= "player" then ns.RedrawDebuffs(f, true) end
end)

-- Countdowns change once a second; ten updates a second keeps the pulse smooth.
-- f.timesDue tells the other rows (buffs, pet debuffs) it's their turn too.
ns.EveryFrame("timers", function(f, dt)
  f.timesWait = (f.timesWait or 0) - dt
  f.timesDue = f.timesWait <= 0
  if f.timesDue then f.timesWait = 0.1 end
  if f.timesDue and (f.unit == "player" or f.exists) then ns.UpdateIconTimes(f) end
  -- Warnings that flash (a CC that broke, a mob that spotted you, losing aggro...).
  if f.unit == "player" then
    local a = 0.25 + 0.75 * math.abs(math.sin(GetTime() * 7))
    for _, ic in ipairs(f.debuffs.icons) do
      if ic.flash and ic:IsShown() then ns.Alpha(ic, a) end
    end
  end
end)
