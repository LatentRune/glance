-- features/BuffMemory.lua: buffs you usually keep up, and which of them are down.
--
-- Each time you enter combat, every long buff you've cast on yourself (a minute or more)
-- is counted as up or down; one that's up in most fights (at least 3, and 60% of the
-- last 20) is "usual". Kept for this character in GlanceCharDB.buffs. Missing ones are
-- shown on your alerts row (ui/AlertsRow.lua). Setting: "buffs".
-- Events: PLAYER_REGEN_DISABLED, PLAYER_DEAD.

local ADDON, ns = ...

local function MyBuffs()
  local out = {}
  for i = 1, 40 do
    local name, icon, _, duration = ns.Aura("player", i, "HELPFUL|PLAYER")
    if not name then break end
    out[name] = { icon = icon, duration = duration or 0 }
  end
  return out
end

local function LearnBuffs()
  ns.char.buffs = ns.char.buffs or {}
  local have = MyBuffs()
  for name, b in pairs(ns.char.buffs) do
    b.total = b.total + 1
    if have[name] then b.up = b.up + 1 end
    if b.total > 20 then b.up, b.total = b.up * 20 / b.total, 20 end  -- old habits fade
  end
  for name, a in pairs(have) do
    if not ns.char.buffs[name] and a.duration >= 60 then
      ns.char.buffs[name] = { icon = a.icon, up = 1, total = 1 }
    end
  end
end

-- Reminders you right-clicked away. They come back when you die or log in again.
local dismissed = {}

---Hide the reminder for a buff until you die or log in again.
function ns.DismissBuff(name) dismissed[name] = true end

---What's known about a buff: { icon, up = fights it was up, total = fights counted }.
function ns.BuffHistory(name) return ns.char.buffs and ns.char.buffs[name] end

-- Names of usual buffs that are down, sorted. Reuses its tables: it runs on every redraw.
local missing, upNow = {}, {}

---Your usual buffs that are down right now, sorted by name. The list is reused.
function ns.MissingBuffs()
  for i = #missing, 1, -1 do missing[i] = nil end
  for k in pairs(upNow) do upNow[k] = nil end
  if UnitIsDeadOrGhost("player") or (UnitOnTaxi and UnitOnTaxi("player")) then return missing end
  local auras = ns.AuraList("player", "HELPFUL|PLAYER")
  for i = 1, auras.n do upNow[auras[i].name] = true end
  for name, b in pairs(ns.char.buffs or {}) do
    if b.up >= 3 and b.up / b.total >= 0.6 and not upNow[name] and not dismissed[name] then
      missing[#missing + 1] = name
    end
  end
  table.sort(missing)
  return missing
end

ns.Listen("alerts", { "PLAYER_REGEN_DISABLED" }, function() if ns.db then LearnBuffs() end end)
ns.Listen("alerts", { "PLAYER_DEAD" }, function()
  if not ns.db then return end
  for k in pairs(dismissed) do dismissed[k] = nil end
end)
