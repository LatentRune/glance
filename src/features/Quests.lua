-- features/Quests.lua: which of your quest objectives the target counts for, and how
-- often its kind drops the quest items you need.
--
-- The game has no drop tables, so Glance learns them: every kill (yours or your group's)
-- and every corpse you loot is counted per mob type, with the quest items each corpse
-- held. Until a first drop, an item is guessed from names ("Boar Meat" from a "Crag Boar").
-- Learned drops are saved in GlanceDB.drops, shared by your characters.
--
-- Drawn under the target's bars by ui/QuestRows.lua, and listed in the NPC menu.
-- Setting: "quests". Events: COMBAT_LOG_EVENT_UNFILTERED (PARTY_KILL), LOOT_OPENED.

local ADDON, ns = ...

-- Something changed (quest log, a drop): the quest rows are rebuilt on the next redraw.
ns.quests = { dirty = true }

---Your quest log as a list: { title, level, index, id, objectives = { text, type, finished } }.
function ns.QuestLog()
  local out = {}
  if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetQuestObjectives and C_QuestLog.GetNumQuestLogEntries then
    for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
      local info = C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.questID then
        out[#out + 1] = { title = info.title, level = info.level, index = i, id = info.questID,
          objectives = C_QuestLog.GetQuestObjectives(info.questID) or {} }
      end
    end
  elseif GetNumQuestLogEntries then
    for i = 1, (GetNumQuestLogEntries()) or 0 do
      local title, level, _, _, _, _, _, id = GetQuestLogTitle(i)
      local boards = GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(i) or 0
      if title and boards > 0 then
        local objs = {}
        for j = 1, boards do
          local text, kind, finished = GetQuestLogLeaderBoard(j, i)
          objs[#objs + 1] = { text = text, type = kind, finished = finished }
        end
        out[#out + 1] = { title = title, level = level, index = i, id = id, objectives = objs }
      end
    end
  end
  return out
end

-- "Boar Ribs: 2/8" (Classic) or "2/8 Boar Ribs" (newer clients) -> "Boar Ribs", 2, 8
local function ParseObjective(text)
  local have, need = text:match("(%d+)%s*/%s*(%d+)")
  local name = text:gsub("%s*:?%s*%d+%s*/%s*%d+%s*", " "):gsub("^%s+", ""):gsub("[%s:]+$", "")
  return name, tonumber(have), tonumber(need)
end

-- Learned drops, saved per mob type: kills, looted corpses, and corpses that held each quest item.
local function DropStats(npc)
  local d = ns.db.drops[npc]
  if not d then d = { kills = 0, looted = 0, items = {} }; ns.db.drops[npc] = d end
  return d
end

-- How often this mob type has dropped an item (0..1), and out of how many.
local function DropRate(npc, item)
  local d = npc and ns.db.drops[npc]
  local got = d and d.items[item]
  if not got then return end
  return got / math.max(d.kills, d.looted, got), math.max(d.kills, d.looted)
end

-- The unit's tooltip as plain text (newer clients list quest items a mob drops there).
local function TooltipText(unit)
  if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return "" end
  local data, parts = C_TooltipInfo.GetUnit(unit), {}
  for _, line in ipairs(data and data.lines or {}) do parts[#parts + 1] = line.leftText or "" end
  return table.concat(parts, "\n")
end

-- No drop table in the game, so before the first drop guess from names: an item that
-- shares a word with the mob's name or family ("Boar Meat" / "Large Crag Boar",
-- "Gnoll Paw" / "Riverpaw Gnoll", "Bear Flank" / family Bear) is probably from it.
local function Words(text, out)
  for w in text:lower():gmatch("%a+") do
    if #w >= 4 then out[w] = true; out[(w:gsub("s$", ""))] = true end
  end
  return out
end

local function LikelyDrop(unit, name, item)
  if not UnitCanAttack("player", unit) then return false end
  local mob = Words(name, {})
  local family = UnitCreatureFamily and UnitCreatureFamily(unit)
  if family then Words(family, mob) end
  for w in pairs(Words(item, {})) do
    if mob[w] then return true end
  end
  return false
end

---What this mob counts for: one title row per quest ({ title, quest }), then one row
---per objective ({ kill = true, name } or { item, rate, n }, with have, need, done).
---At most 8 rows.
function ns.QuestRows(unit)
  local out = {}
  if UnitIsPlayer(unit) then return out end
  local name, npc = UnitName(unit) or "", ns.NpcID(UnitGUID(unit))
  local tip = TooltipText(unit)
  for _, q in ipairs(ns.QuestLog()) do
    local rows = {}
    for _, o in ipairs(q.objectives) do
      if o.text then
        local item, have, need = ParseObjective(o.text)
        have, need = have or (o.finished and 1 or 0), need or 1
        if o.type == "monster" and name ~= "" and o.text:find(name, 1, true) then
          rows[#rows + 1] = { kill = true, name = item ~= "" and item or (name .. " slain"), have = have, need = need, done = o.finished }
        elseif o.type == "item" and item ~= "" then
          local rate, n = DropRate(npc, item)
          if rate or tip:find(item, 1, true) or LikelyDrop(unit, name, item) then
            rows[#rows + 1] = { item = item, have = have, need = need, done = o.finished, rate = rate, n = n }
          end
        end
      end
    end
    if #rows > 0 then
      out[#out + 1] = { title = q.title or "", quest = q }
      for _, r in ipairs(rows) do r.quest = q; out[#out + 1] = r end
    end
    if #out >= 8 then break end
  end
  return out
end

-- "Kill 7 more" / "Boar Meat: 6 more"; the right side carries the count and drop rate.
local function RowText(r)
  local left = r.need - r.have
  local what
  if r.done or left <= 0 then what = r.kill and "Kills done" or (r.item .. ": done")
  elseif r.kill then what = "Kill " .. left .. " more"
  else what = r.item .. ": " .. left .. " more" end
  local right = r.have .. "/" .. r.need
  if r.item and not r.done then
    right = right .. (r.rate and string.format(" · %d%%", math.floor(r.rate * 100 + 0.5)) or " · ?")
  end
  return what, right
end

---The quest rows for a unit as colored text, one line each (for the NPC menu).
function ns.QuestText(unit)
  local lines = {}
  for _, r in ipairs(ns.QuestRows(unit)) do
    if r.title then lines[#lines + 1] = "|cffffd100" .. r.title .. "|r"
    else
      local what, right = RowText(r)
      lines[#lines + 1] = (r.done and "|cff808080" or "|cffffffff") .. what .. "  " .. right .. "|r"
    end
  end
  return table.concat(lines, "\n")
end

---The quest's own text: its description and objectives, as the quest log has them.
function ns.QuestLogText(q)
  if not (GetQuestLogQuestText and q.index) then return end
  -- Older clients read the selected entry, so select it and put the selection back.
  local prev = GetQuestLogSelection and GetQuestLogSelection()
  if SelectQuestLogEntry then SelectQuestLogEntry(q.index) end
  local desc, objectives = GetQuestLogQuestText(q.index)
  if SelectQuestLogEntry and prev and prev > 0 then SelectQuestLogEntry(prev) end
  return desc, objectives
end

------------------------------------------------------------------------------
-- Learning drops
------------------------------------------------------------------------------

-- Count kills (yours or your group's) and looted corpses, and which quest items each corpse held.
local counted, nCounted = {}, 0  -- recent GUIDs, so reopening a corpse doesn't count twice

local function Count(key)
  if counted[key] then return false end
  -- Corpses are long gone by the time 500 more have been counted; start a fresh list.
  if nCounted >= 500 then for k in pairs(counted) do counted[k] = nil end; nCounted = 0 end
  counted[key], nCounted = true, nCounted + 1
  return true
end

local function OnPartyKill(guid)
  local npc = ns.NpcID(guid)
  if not npc or not Count("k" .. guid) then return end
  local d = DropStats(npc)
  d.kills = d.kills + 1
end

local function OnLoot()
  local wanted = {}
  for _, q in ipairs(ns.QuestLog()) do
    for _, o in ipairs(q.objectives) do
      if o.type == "item" and o.text then wanted[(ParseObjective(o.text))] = true end
    end
  end
  local held = {}  -- guid -> { item = true }
  for slot = 1, (GetNumLootItems and GetNumLootItems() or 0) do
    local _, item = GetLootSlotInfo(slot)
    local sources = { GetLootSourceInfo and GetLootSourceInfo(slot) }
    if #sources == 0 then
      local g = UnitGUID("target")
      if g and UnitIsDead("target") then sources = { g, 1 } end
    end
    for i = 1, #sources, 2 do
      local g = sources[i]
      if ns.NpcID(g) then
        held[g] = held[g] or {}
        if item and wanted[item] then held[g][item] = true end
      end
    end
  end
  for g, items in pairs(held) do
    if Count("l" .. g) then
      local d = DropStats(ns.NpcID(g))
      d.looted = d.looted + 1
      for item in pairs(items) do d.items[item] = (d.items[item] or 0) + 1 end
    end
  end
  ns.quests.dirty = true
end

ns.Listen("bars", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  local _, sub, _, _, _, _, _, dest = CombatLogGetCurrentEventInfo()
  if sub == "PARTY_KILL" and ns.db then OnPartyKill(dest) end
end)

ns.Listen("bars", { "LOOT_OPENED" }, function()
  if ns.db then OnLoot() end
end)

---What's been learned about a mob type's drops: { kills, looted, items = { [item] =
---corpses that held it } }, or nil (for the NPC menu).
function ns.Drops(npc) return npc and ns.db.drops[npc] end

---Forget what was learned about a mob type (from the NPC menu).
function ns.ForgetDrops(npc) ns.db.drops[npc] = nil end
