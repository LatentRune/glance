-- features/HealWatch.lua: the last player you healed directly (not yourself, and not
-- with a group heal or a heal over time): while they're below half health, a flashing
-- warning on your debuff row with their health. Setting: "healwatch".
--
-- Events: COMBAT_LOG_EVENT_UNFILTERED.

local ADDON, ns = ...

local LOW = 0.5
local RED = { 1, 0.15, 0.15, 1 }
-- Heals that land on several people at once don't count as healing someone.
local GROUP_HEALS = { 596, 1064, 15237, 740 }  -- Prayer of Healing, Chain Heal, Holy Nova, Tranquility
local group
local lastGUID, lastName, lastPct

ns.Listen("alerts", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  if not ns.db or ns.db.player.labels.healwatch == false then return end
  local _, sub, _, src, _, _, _, dst = CombatLogGetCurrentEventInfo()
  if sub ~= "SPELL_HEAL" then return end  -- heals over time tick as SPELL_PERIODIC_HEAL
  ns.myGUID = ns.myGUID or UnitGUID("player")
  if src ~= ns.myGUID or not dst or dst == ns.myGUID then return end
  if not group then
    group = {}
    for _, id in ipairs(GROUP_HEALS) do local n = ns.SpellName(id); if n then group[n] = true end end
  end
  local info = ns.LogInfo()
  if group[info[13] or ""] then return end
  lastGUID, lastName = dst, info[9]
end)

-- Where to read them: any unit token that's them right now.
local function FindUnit(guid)
  if UnitGUID("target") == guid then return "target" end
  if UnitGUID("mouseover") == guid then return "mouseover" end
  if IsInRaid and IsInRaid() then
    for i = 1, 40 do if UnitGUID("raid" .. i) == guid then return "raid" .. i end end
  else
    for i = 1, 4 do if UnitGUID("party" .. i) == guid then return "party" .. i end end
  end
end

ns.AddWarning({
  key = "healwatch",
  icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
  edge = RED,
  check = function()
    if not lastGUID then return end
    local unit = FindUnit(lastGUID)
    if not unit or UnitIsDeadOrGhost(unit) then return end
    local max = UnitHealthMax(unit) or 0
    if max <= 0 then return end
    lastPct = UnitHealth(unit) / max
    if lastPct < LOW then return true, 0, math.floor(lastPct * 100) .. "%", nil, true end
  end,
  tip = function(tip)
    tip:SetText("Heal target low", 1, 0.3, 0.3)
    tip:AddLine(string.format("%s, the last one you healed, is at %d%% health.",
      lastName or "Your heal target", math.floor((lastPct or 0) * 100)), 1, 1, 1, true)
  end,
})
