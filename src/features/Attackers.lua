-- features/Attackers.lua: how many mobs are on you, and how many more are coming.
--
--   On you: anything that hit or swung at you or your pet in the last 6 seconds, plus
--   any mob with you or your pet on its threat list. The second catches mobs that are
--   feared, beating on your Voidwalker, or still running in: your target always, and the
--   rest when enemy nameplates are on. Shown on the spine (ui/Spine.lua). Setting: "adds".
--
--   Coming: hostile nameplates in combat targeting you or your pet that haven't hit
--   either of you yet. Shown as +N INCOMING (ui/AlertsRow.lua). Setting: "addwarn".
--
-- Events: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED.

local ADDON, ns = ...

local attackers = {}  -- hostile GUID -> last time it hit or swung at you or your pet

local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local function Hostile(flags)
  if type(flags) ~= "number" or not (bit and bit.band) then return true end
  return bit.band(flags, HOSTILE) ~= 0
end

ns.Listen("alerts", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  if not ns.db then return end
  local _, sub0, _, src0, _, _, _, dst0 = CombatLogGetCurrentEventInfo()
  if not ns.Mine(sub0, src0, dst0) then return end
  local info = ns.LogInfo()
  local sub, src, flags, dst = info[2], info[4], info[6], info[8]
  if sub == "UNIT_DIED" or sub == "UNIT_DESTROYED" then attackers[dst or ""] = nil; return end
  local me, pet = UnitGUID("player"), UnitGUID("pet")
  if dst ~= me and (not pet or dst ~= pet) then return end
  -- Anything hitting you or your pet counts once. DoT ticks keep going after their
  -- caster dies, so they don't count as an attacker. Falls and lava are skipped.
  if src and src ~= "" and src ~= me and src ~= pet and Hostile(flags) and not sub:find("PERIODIC")
    and (sub:find("_DAMAGE$") or sub:find("_MISSED$")) and sub ~= "ENVIRONMENTAL_DAMAGE" then
    attackers[src] = GetTime()
  end
end)

ns.Listen("alerts", { "PLAYER_REGEN_ENABLED" }, function()
  if not ns.db then return end
  for k in pairs(attackers) do attackers[k] = nil end
end)

---Mobs coming for you that haven't hit you or your pet yet (needs enemy nameplates).
function ns.IncomingCount()
  local n = 0
  for i = 1, 40 do
    local u, ut = ns.PLATES[i], ns.PLATE_TARGETS[i]
    if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDeadOrGhost(u) and UnitAffectingCombat(u)
      and not attackers[UnitGUID(u) or ""]
      and (UnitIsUnit(ut, "player") or (UnitExists("pet") and UnitIsUnit(ut, "pet"))) then
      n = n + 1
    end
  end
  return n
end

-- Whether a mob has this unit (you or your pet) on its threat list.
local function OnThreat(unit, mob)
  if UnitThreatSituation then return UnitThreatSituation(unit, mob) ~= nil end
  if UnitDetailedThreatSituation then return select(2, UnitDetailedThreatSituation(unit, mob)) ~= nil end
  return false
end

local counted = {}  -- GUIDs counted this time, so a mob is counted once; reused
local function CountEngaged(u, n, pet)
  if not UnitExists(u) or not UnitCanAttack("player", u) or UnitIsDeadOrGhost(u) or not UnitAffectingCombat(u) then
    return n
  end
  local guid = UnitGUID(u)
  if guid and not counted[guid] and (OnThreat("player", u) or (pet and OnThreat("pet", u))) then
    counted[guid] = true
    n = n + 1
  end
  return n
end

---Mobs on you or your pet right now.
function ns.AttackerCount()
  for k in pairs(counted) do counted[k] = nil end
  local n, t = 0, GetTime()
  for guid, last in pairs(attackers) do
    if t - last < 6 then counted[guid] = true; n = n + 1 else attackers[guid] = nil end
  end
  if not ns.inCombat then return n end
  local pet = UnitExists("pet")
  n = CountEngaged("target", n, pet)
  for i = 1, 40 do n = CountEngaged(ns.PLATES[i], n, pet) end
  return n
end
