-- features/EnemyCombo.lua: combo points an enemy rogue (or cat-form druid) has built on
-- you. The game doesn't say, so they're counted from the combat log: each builder that
-- lands on you adds one, a finisher from them or a builder on someone else clears them,
-- and they're forgotten if that enemy dies or goes 30 seconds without building. Talents
-- that add a point on a crit (Seal Fate) aren't seen, so the count can run one short.
-- Shown along the top of your health bar (ui/ComboBar.lua). Setting: "enemycombo".
--
-- Events: COMBAT_LOG_EVENT_UNFILTERED.

local ADDON, ns = ...

local MAX, FORGET = 5, 30
-- Builders, by the combat log line that means it landed: damage, or the effect it puts
-- on you for those that do little or no direct damage.
local BUILDERS = {
  [1752] = "SPELL_DAMAGE",        -- Sinister Strike
  [53] = "SPELL_DAMAGE",          -- Backstab
  [16511] = "SPELL_DAMAGE",       -- Hemorrhage
  [8676] = "SPELL_DAMAGE",        -- Ambush
  [14278] = "SPELL_DAMAGE",       -- Ghostly Strike
  [1776] = "SPELL_AURA_APPLIED",  -- Gouge
  [703] = "SPELL_AURA_APPLIED",   -- Garrote
  [1833] = "SPELL_AURA_APPLIED",  -- Cheap Shot
  [1082] = "SPELL_DAMAGE",        -- Claw
  [5221] = "SPELL_DAMAGE",        -- Shred
  [1822] = "SPELL_DAMAGE",        -- Rake
  [6785] = "SPELL_DAMAGE",        -- Ravage
  [9005] = "SPELL_AURA_APPLIED",  -- Pounce
}
local FINISHERS = { 2098, 5171, 408, 1943, 8647, 22568, 1079 }  -- Eviscerate, Slice and Dice, Kidney Shot, Rupture, Expose Armor, Ferocious Bite, Rip

-- By name, since the combat log in some Classic clients gives no spell IDs. Built once.
local byName
local function Lookup()
  byName = {}
  for id, sub in pairs(BUILDERS) do
    local name = ns.SpellName(id)
    if name then byName[name] = sub end
  end
  for _, id in ipairs(FINISHERS) do
    local name = ns.SpellName(id)
    if name then byName[name] = "finisher" end
  end
end

local onMe = {}  -- enemy GUID -> { n = points, at = when the last one landed }

local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local function Hostile(flags)
  if type(flags) ~= "number" or not (bit and bit.band) then return true end
  return bit.band(flags, HOSTILE) ~= 0
end

ns.Listen("alerts", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  if not ns.db or ns.db.player.labels.enemycombo == false then return end
  local _, sub0, _, src0, _, _, _, dst0 = CombatLogGetCurrentEventInfo()
  -- Lines about you, and anything from an enemy already counting on you (a finisher or
  -- a builder on someone else ends their count).
  if not (onMe[src0 or ""] or ns.Mine(sub0, src0, dst0)) then return end
  local info = ns.LogInfo()
  local sub, src, flags, dst = info[2], info[4], info[6], info[8]
  ns.myGUID = ns.myGUID or UnitGUID("player")
  local me = ns.myGUID
  if sub == "UNIT_DIED" then
    if dst == me then for k in pairs(onMe) do onMe[k] = nil end else onMe[dst or ""] = nil end
    return
  end
  if not src or src == me then return end
  if not byName then Lookup() end
  local kind = byName[info[13] or ""]
  if not kind then return end
  if kind == "finisher" then
    if sub == "SPELL_CAST_SUCCESS" or sub == "SPELL_DAMAGE" or sub == "SPELL_AURA_APPLIED" then onMe[src] = nil end
  elseif sub == kind then
    if dst == me and Hostile(flags) then
      local c = onMe[src] or { n = 0 }
      c.n, c.at = math.min(MAX, c.n + 1), GetTime()
      onMe[src] = c
    elseif dst ~= me then
      onMe[src] = nil  -- building on someone else: what they had on you is gone
    end
  end
end)

---The most combo points any enemy has on you right now (0 if none).
---@return integer
function ns.EnemyComboOnMe()
  local best, t = 0, GetTime()
  for guid, c in pairs(onMe) do
    if t - c.at > FORGET then onMe[guid] = nil
    elseif c.n > best then best = c.n end
  end
  return best
end
