-- features/TargetClass.lua: what kind of target it is: elite, rare, boss, or a player of
-- the other faction. Shown as the corner brackets and tag above the target's bars
-- (ui/TargetTag.lua). Settings: "enemyfaction", "pvptag".

local ADDON, ns = ...

---"elite", "rareelite", "rare" or "worldboss" for a special mob; nil or "normal" otherwise.
function ns.Classification(unit)
  return UnitClassification and UnitClassification(unit)
end

---The faction of a player of the other faction ("Horde" or "Alliance"), or nil.
function ns.EnemyFaction(unit)
  if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
  local theirs = UnitFactionGroup(unit)
  if theirs ~= UnitFactionGroup("player") then return theirs end
end

---A player of your own faction (not you): their faction, or nil.
function ns.AllyFaction(unit)
  if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
  local theirs = UnitFactionGroup(unit)
  if theirs and theirs == UnitFactionGroup("player") then return theirs end
end

---Whether a unit is flagged for PvP.
function ns.PvPFlagged(unit)
  return UnitIsPVP(unit) or (UnitIsPVPFreeForAll and UnitIsPVPFreeForAll(unit)) or false
end
