-- ui/NpcMenu.lua: Glance's section of the right-click menu on a mob: its health and
-- where the number comes from, your kills and loot, average fight, drop rates and quest
-- progress, plus a few actions (announce the pull or your quest progress, a Wowhead link,
-- forget what was learned). On newer clients it's added to Blizzard's own target menu;
-- on older ones it's a menu of Glance's own (with raid marks, since it replaces Blizzard's).

local ADDON, ns = ...

local MARK_NAMES = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }

-- To your raid, party, or /say when alone.
local function Chat(msg)
  local channel = IsInRaid and IsInRaid() and "RAID" or (IsInGroup and IsInGroup() or (GetNumPartyMembers and GetNumPartyMembers() > 0)) and "PARTY" or "SAY"
  SendChatMessage(msg, channel)
end

-- Without color codes, for chat.
local function Plain(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- The menu as a plain list ({ title } or { text, func? }), drawn by whichever menu
-- system the client has.
local function NpcItems(unit)
  local items = {}
  local name = UnitName(unit) or "?"
  local npc = ns.NpcID(UnitGUID(unit))
  local function line(t) items[#items + 1] = { text = t } end
  local function button(t, fn) items[#items + 1] = { text = t, func = fn } end
  items[#items + 1] = { title = "Glance" }
  local cur, maxHP, source = ns.HealthInfo(unit)
  if maxHP then line(string.format("Health %d / %d (%s)", cur, maxHP, source))
  elseif source then line("Health " .. source) end

  local d = ns.Drops(npc)
  local c = ns.FightStats(npc)
  if d and math.max(d.kills, d.looted) > 0 then
    line(string.format("Killed %d, looted %d", d.kills, d.looted))
  end
  if c and c.n > 0 then
    line(string.format("Avg fight %.1fs, %d damage taken", c.time / c.n, math.floor(c.dmg / c.n + 0.5)))
  end
  if d then
    for item, got in pairs(d.items) do
      local of = math.max(d.kills, d.looted, got)
      line(string.format("%s: %d%% (%d of %d)", item, math.floor(got / of * 100 + 0.5), got, of))
    end
  end
  local quest = ns.QuestText(unit)
  if quest ~= "" then
    for l in quest:gmatch("[^\n]+") do line(l) end
    button("Announce quest progress", function()
      local parts = {}
      for l in quest:gmatch("[^\n]+") do parts[#parts + 1] = Plain(l) end
      Chat(name .. ": " .. table.concat(parts, " | "))
    end)
  end
  if #items == 1 then line("|cff808080Nothing recorded yet|r") end

  button("Announce pull", function()
    local lvl = UnitLevel(unit) or 0
    Chat(string.format("Pulling %s (%s)", name, lvl > 0 and ("level " .. lvl) or "level ??"))
  end)
  if npc then
    button("Print Wowhead link", function()
      local site = ns.CLASSIC and "classic/" or ""
      ns.Say(string.format("%s: https://www.wowhead.com/%snpc=%d", name, site, npc))
    end)
    if d or c then
      button("Forget data for this mob", function()
        ns.ForgetDrops(npc)
        ns.ForgetFights(npc)
      end)
    end
  end
  return items
end

-- Newer clients: a section in Blizzard's own target menu.
if Menu and Menu.ModifyMenu then
  Menu.ModifyMenu("MENU_UNIT_TARGET", function(_, root, ctx)
    local unit = ctx and ctx.unit
    if not ns.db or not unit or not UnitExists(unit) or UnitIsPlayer(unit) then return end
    root:CreateDivider()
    for _, it in ipairs(NpcItems(unit)) do
      if it.title then root:CreateTitle(it.title)
      elseif it.func then root:CreateButton(it.text, it.func)
      else root:CreateTitle(it.text) end
    end
  end)
end

---Older clients: open Glance's own menu for an NPC at the cursor (ui/Group.lua calls it
---on right-click).
function ns.ShowNpcMenu(unit)
  if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then return end
  local dd = ns.npcMenu
  if not dd then
    dd = CreateFrame("Frame", "GlanceNPCMenu", UIParent, "UIDropDownMenuTemplate")
    ns.npcMenu = dd
  end
  local items = NpcItems(unit)
  for i = 8, 1, -1 do
    items[#items + 1] = { text = "Mark: " .. (_G["RAID_TARGET_" .. i] or MARK_NAMES[i]), func = function() SetRaidTarget(unit, i) end }
  end
  items[#items + 1] = { text = "Clear mark", func = function() SetRaidTarget(unit, 0) end }
  UIDropDownMenu_Initialize(dd, function(_, level)
    for _, it in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = it.title or it.text
      info.isTitle = it.title and true or nil
      info.notCheckable = true
      if it.func then info.func = it.func else info.notClickable = not it.title or nil end
      UIDropDownMenu_AddButton(info, level)
    end
  end, "MENU")
  ToggleDropDownMenu(1, nil, dd, "cursor")
end
