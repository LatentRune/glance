-- core/CombatLog.lua: reading the combat log cheaply. Several features listen to it
-- (swing timer, attackers, known damage, fight history, death recap), and in a raid or a
-- city it sends hundreds of lines a second, so each one checks ns.Mine first and only
-- unpacks the line when it's about you.

local ADDON, ns = ...

-- The current combat log line as a list, in one table that's refilled for each line
-- rather than a new one per line and per handler.
local logInfo = { n = 0 }
local function Fill(n, ...)
  for i = 1, n do logInfo[i] = (select(i, ...)) end
  for i = n + 1, logInfo.n do logInfo[i] = nil end
  logInfo.n = n
  return logInfo
end

---The current combat log line, as a list: [2] is the subevent ("SWING_DAMAGE"...),
---[4] the source GUID, [8] the destination GUID, then the subevent's own fields.
---Read it straight away and don't keep it: the next call refills the same table.
---@return table
function ns.LogInfo()
  return Fill(select("#", CombatLogGetCurrentEventInfo()), CombatLogGetCurrentEventInfo())
end

---Whether a combat log line concerns you: yours, your pet's, or a death (anyone's, so
---fights and kills can be closed).
---@param sub string the subevent
---@param src string|nil source GUID
---@param dst string|nil destination GUID
function ns.Mine(sub, src, dst)
  if sub == "UNIT_DIED" or sub == "UNIT_DESTROYED" then return true end
  -- Your GUID never changes; your pet's is re-read with each redraw (ui/Group.lua).
  ns.myGUID = ns.myGUID or UnitGUID("player")
  local me, pet = ns.myGUID, ns.petGUID
  if src == me or dst == me then return true end
  return pet ~= nil and (src == pet or dst == pet)
end
