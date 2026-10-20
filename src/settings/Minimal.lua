-- settings/Minimal.lua: minimal mode, for every group: slim bars with no backgrounds and
-- almost no text; only the target's name stays. Switched with the "-" / "+" button under
-- your level, or /glance minimal. ui/ files read it with ns.Minimal() in their
-- "geometry" hooks.

local ADDON, ns = ...

---Switch minimal mode on or off. In combat the bars change now and the click areas
---catch up once it ends.
function ns.SetMinimal(on)
  ns.db.minimal = on and true or false
  ns.ForgetBarLooks()  -- redraw text and colors
  if InCombatLockdown() then ns.GeometryLater() end
  for _, f in pairs(ns.groups) do ns.ApplyGeometry(f, true) end
  ns.RunHooks("minimal", on)
  for _, f in pairs(ns.groups) do if f:IsShown() then ns.Redraw(f) end end
end

-- "-" slims the bars down; "+" brings everything back.
local function MinimalGlyph(b) b.glyph:SetText(ns.db.minimal and "+" or "-") end

---Put the button under your level, below the ? while help is on (settings/Help.lua).
function ns.PlaceMinimalButton(f)
  local m = f and f.minimalButton
  if not m then return end
  m:ClearAllPoints()
  if f.helpButton and f.helpButton:IsShown() then m:SetPoint("TOP", f.helpButton, "BOTTOM", 0, -3)
  else m:SetPoint("TOPRIGHT", f.bars.health, "BOTTOMLEFT", -4, -3) end
end

-- Dim until hovered.
local function MakeMinimalButton(f)
  local b = CreateFrame("Button", nil, f)
  b:SetSize(14, 14)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.8)
  b.glyph = b:CreateFontString(nil, "OVERLAY")
  b.glyph:SetFont(ns.FONT, 13, "OUTLINE")
  b.glyph:SetPoint("CENTER", 0, 1)
  b.glyph:SetTextColor(0.85, 0.85, 0.85)
  b:SetAlpha(0.5)
  b:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText(ns.db.minimal and "Minimal mode is on" or "Minimal mode", 1, 0.82, 0)
    GameTooltip:AddLine(ns.db.minimal and "Click to bring back the text and full-size bars."
      or "Click for slim bars with no backgrounds and almost no text.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function(self) self:SetAlpha(0.5); GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    ns.SetMinimal(not ns.db.minimal)
    MinimalGlyph(self)
  end)
  f.minimalButton = b
  MinimalGlyph(b)
end

-- After settings/Help.lua's login hook, so the button sits under the ?.
ns.Hook("login", function()
  local f = ns.groups.player
  if not f then return end
  MakeMinimalButton(f)
  ns.PlaceMinimalButton(f)
end)

-- Switched from elsewhere (/glance minimal): the glyph follows.
ns.Hook("minimal", function()
  local f = ns.groups.player
  if f and f.minimalButton then MinimalGlyph(f.minimalButton) end
end)
