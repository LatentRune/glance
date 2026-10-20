-- features/Auras.lua: buffs and debuffs, read cheaply.
--
-- Auras are read many times a second, and on newer clients every read builds a table for
-- the garbage collector. So each unit's list is read once after the game says it changed
-- (UNIT_AURA, a new target or pet), and kept. It's read again at least once a second
-- (ns.cadence.aura) in case a change went unannounced.
-- Events: UNIT_AURA, PLAYER_TARGET_CHANGED, UNIT_PET.

local ADDON, ns = ...

local auraLists, auraGen = {}, {}  -- unit -> filter -> list; unit -> change count

---A unit's auras for a filter, as a kept list: entries { name, icon, count, duration,
---expires, index }, n of them. The tables are reused; read them, don't keep them.
---@param filter string "HELPFUL", "HARMFUL", "HARMFUL|PLAYER" (yours on it)...
function ns.AuraList(unit, filter)
  local byUnit = auraLists[unit]
  if not byUnit then byUnit = {}; auraLists[unit] = byUnit end
  local list = byUnit[filter]
  if not list then list = { n = 0 }; byUnit[filter] = list end
  local t = GetTime()
  if list.gen == (auraGen[unit] or 0) and t - (list.at or 0) < ns.cadence.aura then return list end
  list.gen, list.at = auraGen[unit] or 0, t
  local n = 0
  for i = 1, 40 do
    local name, icon, count, duration, expires = ns.Aura(unit, i, filter)
    if not name then break end
    n = n + 1
    local a = list[n] or {}
    list[n] = a
    a.name, a.icon, a.count, a.duration, a.expires, a.index = name, icon, count, duration, expires, i
  end
  list.n = n
  return list
end

ns.Listen(nil, { "UNIT_AURA", "PLAYER_TARGET_CHANGED", "UNIT_PET" }, function(event, unit)
  if event == "PLAYER_TARGET_CHANGED" then unit = "target"
  elseif event == "UNIT_PET" then unit = "pet" end
  if unit then auraGen[unit] = (auraGen[unit] or 0) + 1 end
end)

-- Your short buffs (procs, Slice and Dice, Evasion, trinkets) are the ones worth timing;
-- long ones are left to the missing-buff reminders (features/BuffMemory.lua).
local SHORT_BUFF = 120  -- seconds

---Whether a buff is short enough to show with a timer on your buff row.
function ns.IsShortBuff(a)
  local d = a.duration or 0
  return d > 0 and d <= SHORT_BUFF
end
