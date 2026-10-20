-- ui/BuffRow.lua: your buffs, on your debuff row from the left.
--   First, one of your long buffs (blue edge): the one running out soonest, with +N for
--   how many more you have. Hover it and all of them open below it.
--   Then your short buffs (procs, Slice and Dice, Evasion, trinkets) with a green edge,
--   flashing in their last five seconds.
--   Then your crowd control on mobs (purple edge) and your totems (teal), with timers.
--   One that ends stays 3 seconds, red and flashing (features/CrowdControl.lua).
--   A paladin's aura or a hunter's aspect always takes the long slot when you have one.
-- When the debuffs leave too little room they wrap to a second line. Missing long buffs
-- are left to the reminders (ui/AlertsRow.lua). Settings: "buffbar", "cc", "totems".

local ADDON, ns = ...

local MAX_BUFFS, MAX_LONG = 12, 32
local LONG_PER_LINE = 8
local GREEN_EDGE, BLUE_EDGE = { 0.25, 0.75, 0.3, 1 }, { 0.3, 0.55, 1, 1 }
local CC_EDGE, TOTEM_EDGE, ENDED_EDGE = { 0.7, 0.35, 1, 1 }, { 0.2, 0.8, 0.7, 1 }, { 1, 0.15, 0.15, 1 }

-- The long buff that always takes the row's long slot when you have it: a paladin's aura,
-- a hunter's aspect. By spell ID, turned into names once.
local PREFERRED_IDS = {
  PALADIN = { 465, 7294, 19746, 19876, 19888, 19891, 20218 },  -- Devotion, Retribution, Concentration, Shadow/Frost/Fire Resistance, Sanctity Aura
  HUNTER = { 13165, 5118, 13159, 13163, 20043, 13161, 19506 },  -- Hawk, Cheetah, Pack, Monkey, Wild, Beast, Trueshot (aspects and aura)
}
local preferred
local function Preferred()
  if preferred then return preferred end
  preferred = {}
  for _, id in ipairs(PREFERRED_IDS[ns.CLASS] or {}) do
    local name = ns.SpellName(id)
    if name then preferred[name] = true end
  end
  return preferred
end

-- Tooltip for a crowd control or totem timer.
local function EffectTip(tip, ic)
  local e = ic.effect
  if not e then return end
  tip:SetText(e.spell or "", 1, 0.82, 0)
  if e.kind == "cc" then tip:AddLine("On " .. (e.target or "?"), 1, 1, 1) end
  if e.ended then
    tip:AddLine(e.kind == "cc" and "Ended: broken, dispelled or run out." or "Gone: destroyed or run out.", 1, 0.3, 0.3, true)
  end
end

-- All your long buffs, in a box under the one on the row, while the mouse is on either.
local function OpenLong(f)
  local fly = f.longBuffs
  fly.away = 0
  fly:ClearAllPoints()
  fly:SetPoint("TOPLEFT", f.longIcon, "BOTTOMLEFT", -3, -2)
  fly:Show()
  ns.UpdateLongBuffs(f)
end

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.buffRow = CreateFrame("Frame", nil, f.debuffs)
  f.buffRow:SetPoint("TOPLEFT"); f.buffRow:SetPoint("TOPRIGHT")
  f.buffRow:SetHeight(1)
  f.buffRow.icons = {}
  f.buffRow.lowAt, f.buffRow.flashLow = 5, true  -- flash in the last five seconds
  local fly = CreateFrame("Frame", nil, f)
  fly:SetFrameStrata("DIALOG")
  fly.icons = {}
  fly.bg = fly:CreateTexture(nil, "BACKGROUND")
  fly.bg:SetAllPoints()
  fly.bg:SetColorTexture(0.02, 0.03, 0.05, 0.92)
  -- Open while the mouse is on the row's long buff or the box; a moment's grace between.
  fly:SetScript("OnUpdate", function(self, dt)
    if (f.longIcon and f.longIcon:IsMouseOver()) or self:IsMouseOver() then self.away = 0; return end
    self.away = (self.away or 0) + dt
    if self.away > 0.25 then self:Hide() end
  end)
  fly:Hide()
  f.longBuffs = fly
end)

local longList = {}
local longN = 0

---Fill the long-buff box (while it's open).
function ns.UpdateLongBuffs(f)
  local fly = f.longBuffs
  if not fly:IsShown() then return end
  local size = f.debuffs.size or 18
  for i = 1, longN do
    local a = longList[i]
    local ic = ns.AuraIcon(fly, i)
    if not ic.longEdge then ic.longEdge = true; ic.bg:SetColorTexture(BLUE_EDGE[1], BLUE_EDGE[2], BLUE_EDGE[3], 1) end
    local x = 3 + ((i - 1) % LONG_PER_LINE) * (size + 2)
    local y = -3 - math.floor((i - 1) / LONG_PER_LINE) * (size + 2)
    if ic.placedX ~= x or ic.placedY ~= y or ic.placedSize ~= size then
      ic.placedX, ic.placedY, ic.placedSize = x, y, size
      ic:SetSize(size, size)
      ic:ClearAllPoints()
      ic:SetPoint("TOPLEFT", fly, "TOPLEFT", x, y)
    end
    if ic.icon ~= a.icon then ic.icon = a.icon; ic.tex:SetTexture(a.icon) end
    ns.Text(ic.count, (a.count or 0) > 1 and a.count or "")
    ic.expires = (a.duration or 0) > 0 and a.expires or nil
    ns.SetClock(ic, a.duration, ic.expires)
    if not ic.expires then ns.Text(ic.time, "") end
    ic.unit, ic.index, ic.filter = "player", a.index, "HELPFUL"
    if not ic:IsShown() then ic:Show() end
  end
  for i = longN + 1, #fly.icons do if fly.icons[i]:IsShown() then fly.icons[i]:Hide() end end
  local cols = math.min(math.max(longN, 1), LONG_PER_LINE)
  local lines = math.max(math.ceil(longN / LONG_PER_LINE), 1)
  fly:SetSize(cols * (size + 2) + 4, lines * (size + 2) + 4)
end

local buffList = {}

---Draw your short buffs in the room the debuffs leave (called by ui/DebuffRow.lua).
---@param debuffCount integer icons already on the row from the right
---@return integer shown, integer lines how many buffs, and whether the row needs 1 or 2 lines
function ns.UpdateBuffs(f, debuffCount)
  local row = f.buffRow
  local nb = 0
  longN = 0
  local soonest  -- the long buff that runs out first (or the first, if none run out)
  if ns.On(f, "buffbar") and f.exists then
    local auras = ns.AuraList("player", "HELPFUL")
    for i = 1, auras.n do
      local a = auras[i]
      if not ns.IsShortBuff(a) and longN < MAX_LONG then
        longN = ns.AddAura(longList, longN, a.icon, a.count, a.duration, a.expires, a.index, "HELPFUL")
        local timed = (a.duration or 0) > 0 and a.expires
        local pick = Preferred()[a.name or ""]
        if soonest and soonest.pick then pick = false  -- the first aura or aspect holds the slot
        elseif not pick and soonest then
          pick = timed and (not soonest.timed or a.expires < soonest.expires)
        else pick = true end
        if pick then
          soonest = soonest or {}
          soonest.i, soonest.timed, soonest.expires = longN, timed, a.expires
          soonest.pick = Preferred()[a.name or ""] or nil
        end
      end
    end
    if soonest then
      local a = longList[soonest.i]
      nb = ns.AddAura(buffList, nb, a.icon, a.count, a.duration, a.expires, a.index, "HELPFUL")
      buffList[nb].long, buffList[nb].effect = longN - 1, nil  -- how many more there are
    end
    for i = 1, auras.n do
      local a = auras[i]
      if ns.IsShortBuff(a) and nb < MAX_BUFFS then
        nb = ns.AddAura(buffList, nb, a.icon, a.count, a.duration, a.expires, a.index, "HELPFUL")
        buffList[nb].long, buffList[nb].effect = nil, nil
      end
    end
  end
  -- Your crowd control on mobs and your totems, with their timers.
  local cc, totems = ns.On(f, "cc"), ns.On(f, "totems")
  if (cc or totems) and f.exists then
    local effects = ns.TimedEffects(cc, totems)
    for i = 1, effects.n do
      if nb >= MAX_BUFFS + 6 then break end
      local e = effects[i]
      nb = ns.AddAura(buffList, nb, e.icon, 0, e.ended and 0 or e.duration, e.expires)
      buffList[nb].long = nil
      local copy = buffList[nb].effect or {}
      copy.kind, copy.spell, copy.target, copy.ended = e.kind, e.spell, e.target, e.ended
      buffList[nb].effect = copy
    end
  end
  f.longIcon = nil
  local size = f.debuffs.size or 18
  local per = math.max(math.floor(((f.bars.health.w or 180) + 2) / (size + 2)), 1)  -- icons per line
  local room = math.max(per - debuffCount - (debuffCount > 0 and 1 or 0), 0)
  for i = 1, nb do
    local a = buffList[i]
    local ic = ns.AuraIcon(row, i)
    if not ic.flyHooked then
      ic.flyHooked = true
      -- The box has each buff's own tooltip; one for this buff alone would cover it.
      ic:HookScript("OnEnter", function(self) if self.isLong then OpenLong(f); GameTooltip:Hide() end end)
    end
    ic.isLong = a.long ~= nil
    if ic.isLong then f.longIcon = ic end
    local fx = a.effect
    ic.effect, ic.tip = fx, fx and EffectTip or nil
    -- An ended one keeps its slot for a moment, red and flashing; no countdown.
    ic.fake = fx and fx.ended and "ended" or nil
    if ic.flash and not (fx and fx.ended) then ns.Alpha(ic, 1) end
    ic.flash = fx and fx.ended and true or nil
    local e = ic.isLong and BLUE_EDGE or fx and (fx.ended and ENDED_EDGE or fx.kind == "cc" and CC_EDGE or TOTEM_EDGE) or GREEN_EDGE
    if ic.buffEdge ~= e then ic.buffEdge = e; ic.bg:SetColorTexture(e[1], e[2], e[3], 1) end
    local line, slot = 0, i - 1
    if i > room then line, slot = 1, (i - room - 1) % per end
    local x, y = slot * (size + 2), -line * (size + 2)
    if ic.placedX ~= x or ic.placedY ~= y or ic.placedSize ~= size then
      ic.placedX, ic.placedY, ic.placedSize = x, y, size
      ic:SetSize(size, size)
      ic:ClearAllPoints()
      ic:SetPoint("TOPLEFT", row, "TOPLEFT", x, y)
    end
    if ic.icon ~= a.icon then ic.icon = a.icon; ic.tex:SetTexture(a.icon) end
    if ic.isLong then ns.Text(ic.count, a.long > 0 and ("+" .. a.long) or "")
    else ns.Text(ic.count, (a.count or 0) > 1 and a.count or "") end
    ic.expires = (a.duration or 0) > 0 and a.expires or nil
    ns.SetClock(ic, a.duration, ic.expires)
    if not ic.expires then ns.Text(ic.time, "") end
    ic.unit, ic.index, ic.filter = "player", a.index, "HELPFUL"
    if GameTooltip:IsOwned(ic) and a.index then GameTooltip:SetUnitAura("player", a.index, "HELPFUL") end
    if not ic:IsShown() then ic:Show() end
  end
  for i = nb + 1, #row.icons do if row.icons[i]:IsShown() then row.icons[i]:Hide() end end
  if not f.longIcon then f.longBuffs:Hide() else ns.UpdateLongBuffs(f) end
  return nb, nb > room and 2 or 1
end

ns.EveryFrame("timers", function(f)
  if f.buffRow and f.timesDue then
    ns.UpdateIconTimes(f, f.buffRow)
    if f.longBuffs:IsShown() then ns.UpdateIconTimes(f, f.longBuffs) end
  end
  if f.buffRow then
    local a = 0.25 + 0.75 * math.abs(math.sin(GetTime() * 7))
    for _, ic in ipairs(f.buffRow.icons) do
      if ic.flash and ic:IsShown() then ns.Alpha(ic, a) end
    end
  end
end)
