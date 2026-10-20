-- ui/RaidMarks.lua: raid marks for the target in one click: a skull at the outer end of
-- its debuff row (or the mark it has, if another), placed as the stack under the bars
-- moves (ui/Stack.lua), dim while unmarked. Hover it for all eight,
-- four across and two down. Ctrl-click the target's bars for skull, Alt-click for cross.
-- Marking with the mark it already has clears it (features/Marks.lua).
-- Setting: "markbtns".

local ADDON, ns = ...

local MARKERS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local MARK_NAMES = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }
local SKULL, CROSS = 8, 7

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  local marks = CreateFrame("Button", nil, f)
  marks:SetSize(16, 16)
  marks:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", 5, -4)  -- until the stack places it
  marks.icon = marks:CreateTexture(nil, "ARTWORK")
  marks.icon:SetAllPoints()
  marks.icon:SetTexture(MARKERS)
  SetRaidTargetIconTexture(marks.icon, SKULL)
  marks:RegisterForClicks("LeftButtonUp")
  marks:SetScript("OnClick", function() ns.Mark(f.unit, SKULL) end)
  local grid = CreateFrame("Frame", nil, marks)
  grid:SetSize(4 * 19 + 5, 2 * 19 + 5)
  grid:SetPoint("TOPRIGHT", marks, "BOTTOMRIGHT", 4, -2)
  grid:SetFrameLevel(marks:GetFrameLevel() + 5)
  local gbg = grid:CreateTexture(nil, "BACKGROUND")
  gbg:SetAllPoints()
  gbg:SetColorTexture(0.02, 0.03, 0.05, 0.92)
  grid.buttons = {}
  for idx = 1, 8 do
    local b = CreateFrame("Button", nil, grid)
    b:SetSize(16, 16)
    b:SetPoint("TOPLEFT", 3 + ((idx - 1) % 4) * 19, -3 - math.floor((idx - 1) / 4) * 19)
    b.hl = b:CreateTexture(nil, "BACKGROUND")  -- marks the one it has now
    b.hl:SetPoint("TOPLEFT", -1, 1); b.hl:SetPoint("BOTTOMRIGHT", 1, -1)
    b.hl:SetColorTexture(1, 1, 1, 0.18)
    b.hl:Hide()
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints()
    t:SetTexture(MARKERS)
    SetRaidTargetIconTexture(t, idx)
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function() ns.Mark(f.unit, idx); grid:Hide() end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Mark " .. MARK_NAMES[idx])
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b.idx = idx
    grid.buttons[idx] = b
  end
  -- Open while the mouse is on the skull or the grid; a moment's grace to cross the gap.
  grid:SetScript("OnUpdate", function(self, dt)
    if marks:IsMouseOver() or self:IsMouseOver() then self.away = 0; return end
    self.away = (self.away or 0) + dt
    if self.away > 0.25 then self:Hide() end
  end)
  grid:Hide()
  marks:SetScript("OnEnter", function()
    local cur = GetRaidTargetIndex and GetRaidTargetIndex(f.unit)
    for i, b in ipairs(grid.buttons) do b.hl:SetShown(i == cur) end
    grid.away = 0
    grid:Show()
  end)
  marks.grid = grid
  f.markBtns = marks

  -- Ctrl-click and Alt-click on the bars themselves.
  f:HookScript("OnClick", function(self, button)
    if button ~= "LeftButton" then return end
    if IsControlKeyDown() then ns.Mark(self.unit, SKULL)
    elseif IsAltKeyDown() then ns.Mark(self.unit, CROSS) end
  end)
end)

-- The skull, or the mark the target has if it's another one; dim while unmarked.
local function UpdateMarkButtons(f)
  local marks = f.markBtns
  local show = ns.On(f, "markbtns") and not ns.Minimal()
  marks:SetShown(show)
  if not show then return end
  local cur = GetRaidTargetIndex and GetRaidTargetIndex(f.unit)
  if marks.cur ~= cur then
    marks.cur = cur
    SetRaidTargetIconTexture(marks.icon, cur or SKULL)
    marks.icon:SetAlpha(cur and 1 or 0.45)
  end
end

---Put the skull beside the debuff row: y is where the row's top is, whether it's
---showing or not, so the skull stays put as debuffs come and go. Called by ns.ChainBelow.
function ns.PlaceMarks(f, y)
  local marks = f.markBtns
  if not marks then return end
  local size = f.debuffs.size or 16
  y = math.floor(y - (size - 16) / 2 + 0.5)
  if marks.y == y then return end
  marks.y = y
  marks:ClearAllPoints()
  marks:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", 5, y)
end

ns.Hook("redraw", function(f) if f.markBtns then UpdateMarkButtons(f) end end)
ns.Hook("preview", function(f) if f.markBtns then UpdateMarkButtons(f) end end)
