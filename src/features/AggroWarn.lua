-- features/AggroWarn.lua: for tanks (warriors, druids in bear form, paladins with
-- Righteous Fury): while you hold your target's aggro, a groupmate passing 70% of what it
-- takes to pull it off you flashes a warning on your debuff row for 3 seconds. Once
-- per climb: they have to fall back under 60% to set it off again. Setting: "aggrowarn".

local ADDON, ns = ...

local WARN_AT, RESET_AT, FLASH = 70, 60, 3
local ORANGE = { 1, 0.5, 0.1, 1 }
local RIGHTEOUS_FURY = 25780
local over = {}    -- groupmate GUID -> true while above RESET_AT
local warnedAt, who, whoGUID, whoPct

local function Tank()
  local cls = ns.CLASS
  if cls == "WARRIOR" then return true end
  if cls == "DRUID" then return UnitPowerType("player") == 1 end  -- bear form runs on rage
  if cls == "PALADIN" then
    local fury = ns.SpellName(RIGHTEOUS_FURY)
    local auras = fury and ns.AuraList("player", "HELPFUL")
    for i = 1, auras and auras.n or 0 do if auras[i].name == fury then return true end end
  end
  return false
end

local function Scan(unit)
  if not UnitExists(unit) or UnitIsUnit(unit, "player") then return end
  local _, _, pct = UnitDetailedThreatSituation(unit, "target")
  local guid = UnitGUID(unit)
  if not guid then return end
  if pct and pct >= WARN_AT then
    if not over[guid] then
      over[guid] = true
      warnedAt, who, whoGUID = GetTime(), UnitName(unit), guid
    end
    if guid == whoGUID then whoPct = pct end
  elseif not pct or pct < RESET_AT then
    over[guid] = nil
    if guid == whoGUID then whoPct = pct or 0 end
  end
end

ns.AddWarning({
  key = "aggrowarn",
  icon = "Interface\\Icons\\Ability_Warrior_Taunt",
  edge = ORANGE,
  check = function()
    if UnitDetailedThreatSituation and UnitExists("target") and Tank()
      and UnitDetailedThreatSituation("player", "target") then
      if IsInRaid and IsInRaid() then
        for i = 1, 40 do Scan("raid" .. i) end
      else
        for i = 1, 4 do Scan("party" .. i) end
      end
      Scan("pet")
    end
    if warnedAt and GetTime() - warnedAt < FLASH then
      return true, 0, math.floor(whoPct + 0.5) .. "%", nil, true
    end
  end,
  tip = function(tip)
    tip:SetText("Losing aggro", 1, 0.5, 0.1)
    tip:AddLine(string.format("%s is at %d%% of what it takes to pull your target off you.",
      who or "A groupmate", math.floor((whoPct or 0) + 0.5)), 1, 1, 1, true)
  end,
})
