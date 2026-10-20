-- features/Interrupts.lua: whether you can interrupt the target's cast right now: it can
-- be interrupted, and an interrupt of yours is known and off cooldown.
-- Shown as a blue glow around the target's cast bar (ui/Interrupt.lua). Setting: "interrupt".

local ADDON, ns = ...

-- Each class's interrupts (and stuns that stop a cast), tried in order. IDs from every
-- client; the ones a client doesn't have are never known.
local INTERRUPTS = {
  WARRIOR = { 6552, 72 }, ROGUE = { 1766 }, MAGE = { 2139 }, SHAMAN = { 57994, 8042 },
  PRIEST = { 15487 }, PALADIN = { 96231 }, DRUID = { 106839, 5211 }, HUNTER = { 147362, 187707, 34490 },
  WARLOCK = { 19647, 119910 }, DEATHKNIGHT = { 47528 }, MONK = { 116705 }, DEMONHUNTER = { 183752 },
  EVOKER = { 351338 },
}

local function Known(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  return IsSpellKnown and (IsSpellKnown(id) or IsSpellKnown(id, true))  -- true: your pet's (Spell Lock)
end

local function Cooldown(id)
  -- The plain function where there is one: the newer one returns a table.
  if GetSpellCooldown then
    local s, d = GetSpellCooldown(id)
    return s or 0, d or 0
  end
  if C_Spell and C_Spell.GetSpellCooldown then
    local c = C_Spell.GetSpellCooldown(id)
    if c then return c.startTime or 0, c.duration or 0 end
    return 0, 0
  end
  local s, d = GetSpellCooldown(id)
  return s or 0, d or 0
end

---The spell ID of an interrupt you could use now, or nil.
function ns.InterruptReady()
  for _, id in ipairs(INTERRUPTS[ns.CLASS] or {}) do
    if Known(id) then
      local s, d = Cooldown(id)
      if s == 0 or d <= 1.5 or s + d <= GetTime() then return id end  -- 1.5s or less is only the GCD
    end
  end
end

---Whether the unit's current cast or channel can be interrupted (false when not casting).
function ns.Interruptible(unit)
  local n, _, _, _, _, _, _, ni = UnitCastingInfo(unit)
  if n then return ni ~= true end
  if UnitChannelInfo then
    local cn, _, _, _, _, _, cni = UnitChannelInfo(unit)
    if cn then return cni ~= true end
  end
  return false
end
