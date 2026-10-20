-- features/KnownDamage.lua: damage already on its way to the target, and how much more
-- it takes. Drawn on the target's health bar by ui/KnownDamage.lua. Setting: "preview".
--
-- Known damage is what your DoTs on the target will still deal (ticks left on each, from
-- its timer, times its usual tick) and your spells on their way to it, from the moment
-- you start casting until they land. Nothing here guesses what you'll press next.
--
-- Learned per spell from the combat log, for this character (GlanceCharDB.spells): the
-- last ten non-crit hits, and for DoTs how far apart the ticks come.
--
-- Mob health: newer clients give real numbers. Classic Era gives only percentages, so
-- a mob's health is learned from your solo kills (what you dealt adds up to its health)
-- and kept per mob type and level in GlanceDB.mobhp. During a fight with one you haven't
-- killed yet, it's worked out from the damage dealt against the share of health it took.
--
-- Events: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED, UNIT_SPELLCAST_START,
-- UNIT_SPELLCAST_SUCCEEDED.

local ADDON, ns = ...

local function now() return GetTime() end

local engaged = {}      -- target GUID -> { startFrac, total, key } for learning mob health
local runs = {}         -- target GUID .. DoT name -> the current application's last tick
local landed = {}       -- spell key -> when it last hit or missed
local uses = {}         -- spell key -> times used this fight
local castKey, castOn   -- the cast in progress and who it's aimed at
local flights = {}      -- { key, guid, t }: spells that have left your hands and not landed
local countKey          -- the attack the count is in
local lastUsed, streak  -- the attack you used last, and how many times in a row

local function IsDirect(key)
  return key ~= "Auto Attack" and key ~= "Auto Shot" and not key:find(" %(DoT%)$")
end

local function Push(list, v, keep)
  list[#list + 1] = v
  while #list > (keep or 3) do table.remove(list, 1) end
end

local function Avg(list, last)
  if not list or #list == 0 then return end
  local from = last and math.max(1, #list - last + 1) or 1
  local sum = 0
  for i = from, #list do sum = sum + list[i] end
  return sum / (#list - from + 1)
end

local function SpellData(key)
  ns.char.spells = ns.char.spells or {}
  local d = ns.char.spells[key]
  if not d then d = { dmg = {} }; ns.char.spells[key] = d end
  return d
end

-- Your usual hit with an attack (the average of its last three non-crit hits), and the
-- least it has done in its last ten.
local function Usual(key)
  local d = key and ns.char.spells and ns.char.spells[key]
  if not d or #d.dmg == 0 then return end
  local low = d.dmg[1]
  for _, v in ipairs(d.dmg) do if v < low then low = v end end
  return Avg(d.dmg, 3), low
end

local function MobKey(unit)
  local npc = ns.NpcID(UnitGUID(unit))
  return npc and (npc .. ":" .. (UnitLevel(unit) or 0))
end

-- Health: real numbers when the client gives them, otherwise learned or inferred.
local function MaxHP(unit, guid, frac, max)
  if max > 100 then return max end
  local known = ns.db.mobhp and ns.db.mobhp[MobKey(unit) or ""]
  if known and #known > 0 then return Avg(known) end
  local e = engaged[guid]
  if e and e.startFrac >= 0.99 and e.startFrac - frac >= 0.1 and not (IsInGroup and IsInGroup()) then
    return e.total / (e.startFrac - frac)  -- solo: what you've dealt / share of health it took
  end
end

-- For the right-click menu: the mob's health and where the number comes from.
---@return number|nil cur, number|nil max, string|nil source e.g. "learned from your kills"
function ns.HealthInfo(unit)
  local max = UnitHealthMax(unit) or 0
  if max <= 0 then return end
  local cur = UnitHealth(unit) or 0
  if max > 100 then return cur, max, "from the game" end
  local maxHP = MaxHP(unit, UnitGUID(unit), cur / max, max)
  if not maxHP then return nil, nil, "unknown until you kill one solo" end
  local known = ns.db.mobhp and ns.db.mobhp[MobKey(unit) or ""]
  return cur / max * maxHP, maxHP, known and "learned from your kills" or "worked out this fight"
end

-- What your DoTs on this unit will still deal.
local function Committed(unit)
  local spells, t, total = ns.char.spells or {}, now(), 0
  local auras = ns.AuraList(unit, "HARMFUL|PLAYER")
  for i = 1, auras.n do
    local a = auras[i]
    local d = spells[a.name .. " (DoT)"]
    local tick, left = d and Avg(d.dmg, 3), (a.expires or 0) - t
    if tick and left > 0 then
      total = total + math.ceil((left - 0.001) / (Avg(d.every) or 3)) * tick
    end
  end
  return total
end

-- Your spells on their way to this unit: the one you're casting at it, and any that have
-- left your hands and not landed yet (a Shadow Bolt still flying). Their usual damage, and
-- the least they've done lately.
local function InFlight(unit)
  local guid, t, sum, low = UnitGUID(unit), now(), 0, 0
  local name = UnitCastingInfo("player")
  if name and name == castKey and castOn == guid and IsDirect(name) then
    local a, l = Usual(name)
    if a then sum, low = a, l end
  end
  for i = #flights, 1, -1 do
    local fl = flights[i]
    if t - fl.t >= 2.5 then
      table.remove(flights, i)  -- evaded, or out of sight
    elseif fl.guid == guid then
      local a, l = Usual(fl.key)
      if a then sum, low = sum + a, low + l end
    end
  end
  return sum, low
end

-- The count is in the attack you're using: the one you've used twice in a row, or at the
-- start of a fight the one you used most last fight. Before you've cast anything, your
-- auto attacks or Auto Shots.
local function CountKey()
  if countKey then return countKey end
  local a, s = landed["Auto Attack"] or 0, landed["Auto Shot"] or 0
  if a > 0 or s > 0 then return a >= s and "Auto Attack" or "Auto Shot" end
end

-- For the preview, as shares of the unit's full health: what your DoTs will still deal
-- and your spells on their way. Then the callout: DOTS KILL when the DoTs alone finish it,
-- KILL when the spells on their way do even with a low roll, otherwise how many more of
-- your attack it takes after both.
---@return number|nil dots, number|nil cast shares of full health; string|nil callout
function ns.KnownDamage(unit)
  if not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then return end
  local max = UnitHealthMax(unit) or 0
  if max <= 0 then return end
  local frac = (UnitHealth(unit) or 0) / max
  local maxHP = MaxHP(unit, UnitGUID(unit), frac, max)
  if not maxHP then return end
  local left = frac * maxHP
  local dots = Committed(unit)
  local cast, low = InFlight(unit)
  local text
  if dots > 0 and dots >= left then text = "|cff40ff40DOTS KILL|r"
  elseif low > 0 and dots + low >= left then text = "|cffff4040KILL|r"
  else
    local hit = Usual(CountKey())
    if hit and hit > 0 then text = "x" .. math.max(math.ceil((left - dots - cast) / hit), 1) end
  end
  return dots / maxHP, cast / maxHP, text
end

local function ModelTrack(info)
  local sub, src, dst = info[2], info[4], info[8]
  local t = now()
  if sub == "UNIT_DIED" then
    local e = engaged[dst]
    if e and e.startFrac >= 0.99 and not (IsInGroup and IsInGroup()) and e.key then
      ns.db.mobhp = ns.db.mobhp or {}
      ns.db.mobhp[e.key] = ns.db.mobhp[e.key] or {}
      Push(ns.db.mobhp[e.key], e.total)
    end
    engaged[dst] = nil
    return
  end
  local me, pet = UnitGUID("player"), UnitGUID("pet")
  if src ~= me and (not pet or src ~= pet) then return end
  -- Each application of your DoTs, so the time between its ticks can be learned.
  if src == me and (sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" or sub == "SPELL_AURA_REMOVED")
    and info[15] == "DEBUFF" and info[13] then
    runs[dst .. info[13]] = sub ~= "SPELL_AURA_REMOVED" and {} or nil
    return
  end
  -- A spell of yours that hits or misses is no longer on its way.
  if src == me and (sub == "SPELL_DAMAGE" or sub == "RANGE_DAMAGE" or sub == "SPELL_MISSED" or sub == "RANGE_MISSED") then
    local key = info[13]
    if key then landed[key] = t end
    for i, fl in ipairs(flights) do
      if fl.key == key and fl.guid == dst then table.remove(flights, i); break end
    end
  end
  local key, amount, overkill, crit
  if sub == "SWING_DAMAGE" then
    key, amount, overkill, crit = "Auto Attack", info[12], info[13], info[18]
  elseif sub == "SPELL_DAMAGE" or sub == "RANGE_DAMAGE" or sub == "SPELL_PERIODIC_DAMAGE" then
    key, amount, overkill, crit = info[13], info[15], info[16], info[21]
  else
    return
  end
  if type(amount) ~= "number" or not key then return end
  if src == me then
    if sub == "SWING_DAMAGE" then landed[key] = t end
    if sub == "SPELL_PERIODIC_DAMAGE" then
      local run = runs[dst .. key]
      key = key .. " (DoT)"
      if run then
        local d = SpellData(key)
        if run.last and t - run.last > 0.5 and t - run.last < 6 then
          d.every = d.every or {}
          Push(d.every, t - run.last)
        end
        run.last = t
      end
    end
    if not crit then Push(SpellData(key).dmg, amount, 10) end
  end

  -- Solo, everything you and your pet deal adds up to the mob's health once it dies.
  local real = amount - ((type(overkill) == "number" and overkill > 0) and overkill or 0)
  local e = engaged[dst]
  if not e then
    local frac = 0
    local S = ns.ttd.guid == dst and ns.ttd.samples
    if S and S[1] then
      frac = S[1].v  -- health sampled before the fight's first hits
    elseif UnitGUID("target") == dst and (UnitHealthMax("target") or 0) > 0 then
      -- health is read after this hit landed, so add it back for the starting point
      frac = UnitHealth("target") / UnitHealthMax("target")
      if UnitHealthMax("target") > 100 then frac = frac + real / UnitHealthMax("target") end
    end
    e = { startFrac = frac >= 0.97 and 1 or frac, total = 0, key = UnitGUID("target") == dst and MobKey("target") or nil }
    engaged[dst] = e
  end
  e.total = e.total + real
end

-- A spell left your hands: it's on its way until it lands. Using the same attack twice in
-- a row makes it the one the count is in (three times for one that opens a DoT, like
-- Immolate, so reapplying it doesn't take over).
local function OnCast(key)
  if not key or not IsDirect(key) or not Usual(key) then return end
  local t = now()
  local guid = key == castKey and castOn or UnitGUID("target")
  castKey, castOn = nil, nil
  -- An instant melee hit can be logged before the cast is.
  if guid and t - (landed[key] or 0) > 0.3 then flights[#flights + 1] = { key = key, guid = guid, t = t } end
  uses[key] = (uses[key] or 0) + 1
  streak = key == lastUsed and streak + 1 or 1
  lastUsed = key
  -- The first attack you ever use counts at once, unless it's the opener of a DoT.
  local opener = ns.char.spells[key .. " (DoT)"]
  if streak >= (opener and 3 or 2) or (not countKey and not opener) then countKey = key end
end

ns.Listen("damage model", { "COMBAT_LOG_EVENT_UNFILTERED", "PLAYER_REGEN_ENABLED", "UNIT_SPELLCAST_START",
  "UNIT_SPELLCAST_SUCCEEDED" }, function(event, unit, _, spellID)
  if not ns.db then return end
  if event == "UNIT_SPELLCAST_START" then
    if unit == "player" and spellID then castKey, castOn = ns.SpellName(spellID), UnitGUID("target") end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if unit == "player" and spellID then OnCast(ns.SpellName(spellID)) end
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Next fight's count starts in the attack you used most in this one.
    local best
    for key, n in pairs(uses) do
      if not best or n > uses[best] or (n == uses[best] and key == countKey) then best = key end
    end
    if best then countKey = best end
    for k in pairs(uses) do uses[k] = nil end
    for k in pairs(engaged) do engaged[k] = nil end
    for k in pairs(runs) do runs[k] = nil end
  else
    local _, sub, _, src, _, _, _, dst = CombatLogGetCurrentEventInfo()
    if ns.Mine(sub, src, dst) then ModelTrack(ns.LogInfo()) end
  end
end)
