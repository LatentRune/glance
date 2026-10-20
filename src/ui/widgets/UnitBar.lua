-- ui/widgets/UnitBar.lua: a slim bar that follows a unit of its own: your target's target
-- (ui/TargetOfTarget.lua) or your pet (ui/PetBar.lua).

local ADDON, ns = ...

---Update a slim bar from its unit: health, a color (class for players, friend or foe
---otherwise) and the name. Hides it when the unit is gone or the setting is off.
---Keeps bar.exists, bar.guid, bar.dead, bar.hp and bar.hpMax for the hit flash, which runs
---every frame without asking the game. For the target of target, bar.onYou is true when
---it's you, and the name reads YOU; bar.onYouAt is when it switched to you.
function ns.UnitBar(f, bar, unit, enabled)
  if not (enabled and UnitExists(unit)) then
    bar.exists, bar.onYou = false, false
    if bar:IsShown() then bar:Hide() end
    return
  end
  bar.exists, bar.guid, bar.dead = true, UnitGUID(unit), UnitIsDeadOrGhost(unit)
  bar.hp, bar.hpMax = UnitHealth(unit), UnitHealthMax(unit)
  local r, g, b = 0.3, 0.8, 0.3
  local _, cls = UnitClass(unit)
  local c = UnitIsPlayer(unit) and cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
  if c then r, g, b = c.r, c.g, c.b
  elseif unit ~= "pet" then
    local rx = UnitReaction(unit, "player")
    local rc = rx and FACTION_BAR_COLORS and FACTION_BAR_COLORS[rx]
    if rc then r, g, b = rc.r, rc.g, rc.b end
  end
  local label = UnitName(unit) or ""
  local onYou = unit == "targettarget" and UnitIsUnit(unit, "player") or false
  if onYou and not bar.onYou then bar.onYouAt = GetTime() end  -- just switched to you
  bar.onYou = onYou
  if onYou then label = "|cffff1010YOU|r"
  elseif unit == "targettarget" then label = "> " .. label end
  ns.SetBar(bar, bar.hp, bar.hpMax, label, r, g, b)
  if not bar:IsShown() then bar:Show() end
end
