-- features/KillPace.lua: how long fights with each kind of mob take you.
--
-- Every fight is tracked from your first hit (or its first hit on you) until it dies:
-- how long it took and how much damage you took. Per mob type, kept for this character
-- in GlanceCharDB.combat. Shown beside the target of target by ui/KillPace.lua, and in
-- the NPC menu. Setting: "pace".
-- Events: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED.

local ADDON, ns = ...

local fights = {}  -- mob GUID -> { start, npc, dmg }: fights going on now

---When the fight with this mob started, if you're fighting it.
function ns.FightStart(guid)
  return guid and fights[guid] and fights[guid].start
end

local function CombatStats(npc)
  ns.char.combat = ns.char.combat or {}
  local c = ns.char.combat[npc]
  if not c then c = { n = 0, time = 0, dmg = 0 }; ns.char.combat[npc] = c end
  return c
end

---Your past fights with a mob type: { n = fights, time = seconds in all, dmg = damage
---taken in all }, or nil if none.
function ns.FightStats(npc)
  return npc and ns.char.combat and ns.char.combat[npc]
end

---Forget your fights with a mob type (from the NPC menu).
function ns.ForgetFights(npc)
  if ns.char.combat then ns.char.combat[npc] = nil end
end

local function TrackFight(info)
  local sub, src, dst = info[2], info[4], info[8]
  local me = UnitGUID("player")
  local t = GetTime()
  if sub == "UNIT_DIED" then
    local fight = fights[dst]
    if fight then
      local c = CombatStats(fight.npc)
      c.n, c.time, c.dmg = c.n + 1, c.time + (t - fight.start), c.dmg + fight.dmg
      fights[dst] = nil
    end
    return
  end
  local mob = (src == me and ns.NpcID(dst) and dst) or (dst == me and ns.NpcID(src) and src)
  if not mob or not sub:find("_DAMAGE$") and not sub:find("_MISSED$") then return end
  local fight = fights[mob]
  if not fight then fight = { start = t, npc = ns.NpcID(mob), dmg = 0 }; fights[mob] = fight end
  if dst == me then
    local amount = sub == "SWING_DAMAGE" and info[12] or (sub:find("_DAMAGE$") and info[15])
    if type(amount) == "number" then fight.dmg = fight.dmg + amount end
  end
end

ns.Listen("fight history", { "COMBAT_LOG_EVENT_UNFILTERED", "PLAYER_REGEN_ENABLED" }, function(event)
  if not ns.db then return end
  if event == "PLAYER_REGEN_ENABLED" then
    for k in pairs(fights) do fights[k] = nil end  -- anything left got away
  else
    local _, sub, _, src, _, _, _, dst = CombatLogGetCurrentEventInfo()
    if ns.Mine(sub, src, dst) then TrackFight(ns.LogInfo()) end
  end
end)
