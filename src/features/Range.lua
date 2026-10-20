-- features/Range.lua: whether the target is in range, and whether you're idle. Both feed
-- the fading in ui/Fade.lua: your bars dim when idle, the target's when out of range.
-- Settings: "fade" (yours), "range" (the target's).

local ADDON, ns = ...

-- A spell per class with a range like your usual attacks, tried in order. The first one
-- you know answers.
local RANGE_SPELLS = {
  WARRIOR = { 78 }, ROGUE = { 1752 }, HUNTER = { 75, 2973 }, MAGE = { 133, 116 },
  WARLOCK = { 686 }, PRIEST = { 585 }, DRUID = { 5176 }, SHAMAN = { 403 }, PALADIN = { 20271 },
}

---Whether a spell of yours would reach the unit: true, false, or nil when it can't be told
---(you don't know the spell, or the client can't check).
function ns.SpellInRange(id, unit)
  if IsPlayerSpell and not IsPlayerSpell(id) then return end
  if C_Spell and C_Spell.IsSpellInRange then return C_Spell.IsSpellInRange(id, unit) end
  local name = ns.SpellName(id)
  if name and IsSpellInRange then
    local r = IsSpellInRange(name, unit)
    if r ~= nil then return r == 1 end
  end
end

---Whether the unit is in range: of your attacks for an enemy, of your group for a friend.
---Unknown counts as in range, so nothing fades without reason.
function ns.InRange(unit)
  if not UnitCanAttack("player", unit) then
    if UnitInRange and (UnitInParty(unit) or UnitInRaid(unit)) then return (UnitInRange(unit)) end
    return true
  end
  local any
  for _, id in ipairs(RANGE_SPELLS[ns.CLASS] or {}) do
    local r = ns.SpellInRange(id, unit)
    if r == true then return true end
    if r == false then any = false end
  end
  if any == nil and not InCombatLockdown() and CheckInteractDistance then
    local ok, r = pcall(CheckInteractDistance, unit, 4)  -- 4: about 28 yards (follow range)
    if ok then return r and true or false end
  end
  return any ~= false
end

---Whether you're idle: out of combat, no target, full health, and power at rest (full,
---or empty for rage and runic power, which drain to 0).
function ns.Idle()
  if UnitAffectingCombat("player") or UnitExists("target") then return false end
  if UnitHealth("player") < UnitHealthMax("player") then return false end
  local ptype = UnitPowerType("player")
  local p, pm = UnitPower("player"), UnitPowerMax("player")
  if ptype == 1 or ptype == 6 then return p == 0 end  -- rage and runic power drain to 0
  return p >= pm
end
