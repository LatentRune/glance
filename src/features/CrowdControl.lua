-- features/CrowdControl.lua: your crowd control on mobs, and your totems, with how long
-- each has left, so you know when the sheep wakes up after you've switched targets.
--
--   Crowd control: from the combat log when your Polymorph, Sap, Fear... lands. It runs
--   for the spell's full duration (top rank, before diminishing returns) unless the log
--   says it ended sooner, or until the target's own aura says how long it really has.
--   Totems: from the game's totem slots.
--
-- When one ends (broken, dispelled, run out, or a totem destroyed) it stays 3 seconds,
-- flagged as ended. Shown on your buff row (ui/BuffRow.lua). Settings: "cc", "totems".
--
-- Events: COMBAT_LOG_EVENT_UNFILTERED, UNIT_AURA (target), PLAYER_TOTEM_UPDATE.

local ADDON, ns = ...

local ENDED_FOR = 3  -- seconds an ended one stays, flashing
-- Spell ID -> seconds, at top rank. Looked up by name: some Classic clients leave the
-- combat log's spell IDs empty.
local CC = {
  [118] = 50,    -- Polymorph
  [6770] = 45,   -- Sap
  [1776] = 4,    -- Gouge
  [2094] = 10,   -- Blind
  [408] = 6,     -- Kidney Shot
  [5782] = 20,   -- Fear
  [5484] = 15,   -- Howl of Terror
  [6358] = 15,   -- Seduction
  [710] = 30,    -- Banish
  [2637] = 40,   -- Hibernate
  [339] = 27,    -- Entangling Roots
  [3355] = 20,   -- Freezing Trap Effect
  [1513] = 20,   -- Scare Beast
  [19386] = 12,  -- Wyvern Sting
  [9484] = 50,   -- Shackle Undead
  [8122] = 8,    -- Psychic Scream
  [5246] = 8,    -- Intimidating Shout
  [853] = 6,     -- Hammer of Justice
  [20066] = 6,   -- Repentance
  [2878] = 20,   -- Turn Undead
  [122] = 8,     -- Frost Nova
}
local byName  -- name -> { seconds, icon }, built once
local function Lookup()
  byName = {}
  for id, secs in pairs(CC) do
    local name = ns.SpellName(id)
    if name then byName[name] = { secs, ns.SpellIcon(id) } end
  end
end

local active = {}  -- "guid:spell" -> { guid, target, spell, icon, duration, expires, ended }

local function Start(guid, target, spell, info)
  local key = guid .. ":" .. spell
  local c = active[key] or {}
  c.guid, c.target, c.spell, c.icon = guid, target, spell, info[2]
  c.duration, c.expires, c.ended = info[1], GetTime() + info[1], nil
  active[key] = c
end

local function End(key, at)
  local c = active[key]
  if c and not c.ended then c.ended = at or GetTime() end
end

ns.Listen("alerts", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  if not ns.db then return end
  local _, sub0, _, src0, _, _, _, dst0 = CombatLogGetCurrentEventInfo()
  if not ns.Mine(sub0, src0, dst0) then return end
  local info = ns.LogInfo()
  local sub, src, dst = info[2], info[4], info[8]
  if sub == "UNIT_DIED" then  -- a dead mob needs no timer
    for key, c in pairs(active) do if c.guid == dst then active[key] = nil end end
    return
  end
  ns.myGUID = ns.myGUID or UnitGUID("player")
  if src ~= ns.myGUID or not dst then return end
  if not byName then Lookup() end
  local spell = info[13]
  local cc = spell and byName[spell]
  if not cc then return end
  if sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" then
    Start(dst, info[9] or "", spell, cc)
  elseif sub == "SPELL_AURA_REMOVED" or sub == "SPELL_AURA_BROKEN" or sub == "SPELL_AURA_BROKEN_SPELL" then
    End(dst .. ":" .. spell)
  end
end)

-- Your target's own auras say how long yours really has (lower ranks, diminishing returns).
ns.Listen(nil, { "UNIT_AURA", "PLAYER_TARGET_CHANGED" }, function()
  if not ns.db or not next(active) then return end
  local guid = UnitGUID("target")
  if not guid then return end
  local auras = ns.AuraList("target", "HARMFUL|PLAYER")
  for i = 1, auras.n do
    local a = auras[i]
    local c = active[guid .. ":" .. (a.name or "")]
    if c and not c.ended and (a.duration or 0) > 0 then c.duration, c.expires = a.duration, a.expires end
  end
end)

-- Totems: what each slot held last time, to notice one ending.
local slots = {}
local totemEnded = {}  -- slot -> { spell, icon, ended }

local function ReadTotems()
  if not GetTotemInfo then return end
  for slot = 1, 4 do
    local have, name, start, duration, icon = GetTotemInfo(slot)
    local s = slots[slot]
    local live = have and name and name ~= "" and (duration or 0) > 0
    if s and (not live or s.start ~= start) then
      totemEnded[slot] = { spell = s.spell, icon = s.icon, ended = GetTime() }
    end
    if live then
      slots[slot] = { spell = name, icon = icon, start = start, duration = duration, expires = start + duration }
    else
      slots[slot] = nil
    end
  end
end
ns.Listen(nil, { "PLAYER_TOTEM_UPDATE", "PLAYER_ENTERING_WORLD" }, function() if ns.db then ReadTotems() end end)

local list = { n = 0 }
local function Add(kind, spell, target, icon, duration, expires, ended)
  list.n = list.n + 1
  local e = list[list.n] or {}
  list[list.n] = e
  e.kind, e.spell, e.target, e.icon, e.duration, e.expires, e.ended = kind, spell, target, icon, duration, expires, ended
end

---Your crowd control and totems now, ending soonest first, then the ones that just ended.
---Each: { kind = "cc"|"totem", spell, target (cc), icon, duration, expires, ended (when) }.
---Reuses one table: read it straight away.
---@param cc boolean include crowd control
---@param totems boolean include totems
function ns.TimedEffects(cc, totems)
  list.n = 0
  local t = GetTime()
  for key, c in pairs(active) do
    if not c.ended and t >= c.expires then c.ended = c.expires end  -- ran its full time
    if c.ended and t - c.ended > ENDED_FOR then active[key] = nil
    elseif cc then Add("cc", c.spell, c.target, c.icon, c.duration, c.expires, c.ended) end
  end
  for slot = 1, 4 do
    local s, e = slots[slot], totemEnded[slot]
    if s and t >= s.expires then ReadTotems(); s = slots[slot]; e = totemEnded[slot] end
    if totems and s then Add("totem", s.spell, nil, s.icon, s.duration, s.expires) end
    if e then
      if t - e.ended > ENDED_FOR then totemEnded[slot] = nil
      elseif totems then Add("totem", e.spell, nil, e.icon, 0, e.ended, e.ended) end
    end
  end
  -- Live ones by time left, then ended ones.
  for i = list.n + 1, #list do list[i] = nil end
  table.sort(list, function(a, b)
    if (a.ended ~= nil) ~= (b.ended ~= nil) then return a.ended == nil end
    return (a.expires or 0) < (b.expires or 0)
  end)
  return list
end
