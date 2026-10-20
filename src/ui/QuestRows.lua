-- ui/QuestRows.lua: quest progress under the target's bars: a slim gold bar for each
-- objective this mob counts for that's still needed ("Boar Ribs  2/8"). Hover one for its
-- quest. What counts and the drop rates come from features/Quests.lua.
-- Setting: "quests". Events: QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED.

local ADDON, ns = ...

local FONT = ns.FONT

-- Long quest descriptions are cut at a word, to keep the tooltip readable.
local function Clip(text, max)
  if #text <= max then return text end
  local cut = text:sub(1, max):match("^(.*)%s") or text:sub(1, max)
  return cut .. "..."
end

-- Hovering an objective: what the quest is, what it asks for, and how far along it is.
local function QuestTooltip(self)
  local q = self.quest
  if not q then return end
  GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
  local title = q.title or ""
  if q.level and q.level > 0 then title = "[" .. q.level .. "] " .. title end
  local c = q.level and GetQuestDifficultyColor and GetQuestDifficultyColor(q.level)
  GameTooltip:SetText(title, c and c.r or 1, c and c.g or 0.82, c and c.b or 0)
  local desc, objectives = ns.QuestLogText(q)
  if objectives and objectives ~= "" then GameTooltip:AddLine(objectives, 1, 1, 1, true) end
  for _, o in ipairs(q.objectives or {}) do
    if o.text and o.text ~= "" then
      if o.finished then GameTooltip:AddLine("- " .. o.text, 0.5, 0.5, 0.5)
      else GameTooltip:AddLine("- " .. o.text, 1, 0.82, 0) end
    end
  end
  if desc and desc ~= "" then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Clip(desc, 300), 0.7, 0.7, 0.7, true)
  end
  GameTooltip:Show()
end

-- One slim progress bar per objective still needed. Quest titles and finished objectives
-- aren't drawn. Bars are kept and reused.
local function DrawQuest(f, rows)
  local box, pos = f.quest, ns.db[f.unit]
  local size = math.max(pos.fontSize - 2, 6)
  local barH = size + 4
  box.bars = box.bars or {}
  local nb, y = 0, 0
  for _, r in ipairs(rows) do
    if not (r.title or r.done or r.have >= r.need) then
      nb = nb + 1
      local b = box.bars[nb]
      if not b then
        b = ns.NewBar(box, false)
        b:SetReverseFill(false); b.reversed = nil  -- progress fills left to right
        local back = b:CreateTexture(nil, "BACKGROUND", nil, -8)
        back:SetPoint("TOPLEFT", -1, 1); back:SetPoint("BOTTOMRIGHT", 1, -1)
        back:SetColorTexture(0, 0, 0, 0.85)
        b.back = back
        -- Hover for the quest; clicks still fall through to the camera.
        b:EnableMouse(true)
        if b.SetMouseClickEnabled then b:SetMouseClickEnabled(false) end
        b:SetScript("OnEnter", QuestTooltip)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        box.bars[nb] = b
      end
      b:SetHeight(barH)
      ns.SetBarFont(b, size)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -y - 1)
      b:SetPoint("RIGHT", box, "RIGHT", -1, 0)
      b:SetMinMaxValues(0, math.max(r.need, 1))
      b:SetValue(math.min(r.have, r.need))
      local cr, cg, cb = 0.85, 0.65, 0.1
      b:SetStatusBarColor(cr, cg, cb)
      b.bg:SetColorTexture(cr * 0.2, cg * 0.2, cb * 0.2, 0.9)
      -- What it's for on the left ("Boar Ribs", "Plainstrider slain"), the count on the right.
      b.quest = r.quest
      b.label:SetText(ns.Minimal() and "" or (r.kill and r.name or r.item))
      ns.Backing(b, not ns.Minimal())
      b.pct:SetText(r.have .. "/" .. r.need)
      b:Show()
      y = y + barH + 4
    end
  end
  for i = nb + 1, #box.bars do box.bars[i]:Hide() end
  box:SetHeight(math.max(y, 1))
  if nb > 0 ~= box:IsShown() or y ~= box.lastY then
    box.lastY = y
    box:SetShown(nb > 0)
    ns.ChainBelow(f)
  end
end

-- Rebuilt only for a new target, when the quest log or a drop rate changed, or when forced
-- (sizes changed).
local function RefreshQuest(f, force)
  if not f.quest then return end
  local guid = UnitExists(f.unit) and UnitGUID(f.unit)
  if not force and not ns.quests.dirty and guid == f.questGuid then return end
  f.questGuid, f.questAt, ns.quests.dirty = guid, GetTime(), false
  if not guid or not ns.On(f, "quests") then DrawQuest(f, {}); return end
  DrawQuest(f, ns.QuestRows(f.unit))
end

ns.Hook("redraw", function(f) RefreshQuest(f) end)

ns.Hook("geometry", function(f)
  if f.quest then f.quest:SetWidth(ns.db[f.unit].width); RefreshQuest(f, true) end
end)

-- While placing the bars: a sample of what quest rows look like.
ns.Hook("preview", function(f)
  if f.quest then
    DrawQuest(f, { { title = "A quest" }, { kill = true, name = "Plainstrider slain", have = 3, need = 10 },
      { item = "Boar Ribs", have = 2, need = 8, rate = 0.34, n = 12 } })
  end
end)

ns.Listen("bars", { "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED" }, function()
  ns.quests.dirty = true
  local f = ns.groups.target
  if f then RefreshQuest(f); ns.quests.dirty = false end
end)
