-- settings/Panel.lua: the settings panel for one group: sliders for its size, text and
-- opacity, and a checkbox for each feature that applies to it. Opened by clicking a
-- group's blue box while the bars are unlocked (settings/EditMode.lua).
--
-- Adding a checkbox: add a line to LABELS with the feature's key, and the key to the
-- defaults in core/Defaults.lua. `player` or `target` limits it to that group, `both`
-- shows it on both; with none of those it shows on groups that have a bar of that key.

local ADDON, ns = ...

local SLIDERS = {
  { key = "width",        label = "Width",         min = 80,  max = 400, step = 1 },
  { key = "healthHeight", label = "Health height", min = 6,   max = 40,  step = 1 },
  { key = "powerHeight",  label = "Power height",  min = 4,   max = 30,  step = 1 },
  { key = "fontSize",     label = "Text size",     min = 6,   max = 20,  step = 1 },
  { key = "scale",        label = "Scale",         min = 0.5, max = 2,   step = 0.05 },
  { key = "alpha",        label = "Opacity",       min = 0.1, max = 1,   step = 0.05 },
}

local LABELS = {
  { key = "health", label = "Name on health" },
  { key = "power",  label = "Name on power" },
  { key = "mana",   label = "Name on mana" },
  { key = "combo",  label = "Combo points", target = true },
  { key = "enemycombo", label = "Enemy combo points on you", player = true },
  { key = "ammo",   label = "Name on ammo/shards", player = true },
  { key = "quests", label = "Quest progress", target = true },
  { key = "cast",    label = "Cast bar", target = true },
  { key = "debuffs", label = "Debuffs", both = true },
  { key = "threat",  label = "Threat", target = true },
  { key = "tot",     label = "Target of target", target = true },
  { key = "range",   label = "Fade out of range", target = true },
  { key = "tick",    label = "Energy/mana tick", player = true },
  { key = "swing",   label = "Swing timer", player = true },
  { key = "pet",     label = "Pet bar", player = true },
  { key = "fade",    label = "Fade when idle", player = true },
  { key = "combat",  label = "In-combat marker", player = true },
  { key = "lowflash", label = "Flash below 30%", player = true },
  { key = "expireflash", label = "Flash expiring debuffs", target = true },
  { key = "preview", label = "Known damage preview", target = true },
  { key = "trail",   label = "Hit flash", both = true },
  { key = "aurafx",  label = "Buffs grow in, break apart", both = true },
  { key = "pace",    label = "Kill pace", target = true },
  { key = "markbtns", label = "Skull/cross buttons", target = true },
  { key = "runner",  label = "Runner warning", target = true },
  { key = "interrupt", label = "Interrupt cue", target = true },
  { key = "abilities", label = "Known mob casts", target = true },
  { key = "execute", label = "Execute zone", target = true },
  { key = "enemyfaction", label = "Faction corners", target = true },
  { key = "pvptag",  label = "PvP tag", target = true },
  { key = "adds",    label = "Aggro count", player = true },
  { key = "addwarn", label = "Incoming add warning", player = true },
  { key = "loot",    label = "Loot reminder", player = true },
  { key = "breath",  label = "Breath warning", player = true },
  { key = "gear",    label = "Worn gear warning", player = true },
  { key = "bags",    label = "Full bags warning", player = true },
  { key = "recap",   label = "Death recap", player = true },
  { key = "buffbar", label = "Short buffs", player = true },
  { key = "manacost", label = "Mana per cast", player = true },
  { key = "potion",  label = "Potion prompt", player = true },
  { key = "buffs",   label = "Missing buffs", player = true },
  { key = "hunter",  label = "Pet mood, ammo, range", player = true },
  { key = "marker",  label = "Raid marker", both = true },
  { key = "clickthrough", label = "Shift/Ctrl/Alt to click", both = true },
  { key = "resting", label = "Resting indicator", player = true },
  { key = "cc",      label = "Crowd control timers", player = true },
  { key = "totems",  label = "Totem timers", player = true },
  { key = "detected", label = "Spotted in stealth", player = true },
  { key = "aggrowarn", label = "Losing aggro (tanks)", player = true },
  { key = "healwatch", label = "Heal target low", player = true },
  { key = "slide",   label = "Center until there's a target", player = true },
}

local panel  -- made the first time it's opened

local function fmt(v, step) return step < 1 and string.format("%.2f", v) or tostring(math.floor(v + 0.5)) end

local function BuildPanel()
  panel = CreateFrame("Frame", "GlanceSettings", UIParent)
  panel:SetSize(300, 56 + #SLIDERS * 40 + #LABELS * 12)
  panel:SetPoint("CENTER", 0, 160)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  local bg = panel:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.05, 0.08, 0.92)

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("TOPLEFT", 12, -10)
  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  panel.sliders = {}
  for i, def in ipairs(SLIDERS) do
    local s = CreateFrame("Slider", nil, panel)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(276, 14)
    s:SetPoint("TOPLEFT", 12, -24 - i * 40 + 12)
    s:SetMinMaxValues(def.min, def.max)
    s:SetValueStep(def.step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT"); track:SetPoint("RIGHT")
    track:SetHeight(4)
    track:SetColorTexture(1, 1, 1, 0.25)
    s.label = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.label:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2)
    s.value = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.value:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2)
    s.label:SetText(def.label)
    s:EnableMouseWheel(true)
    s:SetScript("OnMouseWheel", function(self, d) self:SetValue(self:GetValue() + d * def.step) end)
    s:SetScript("OnValueChanged", function(self, v)
      if not panel.group then return end
      v = math.floor(v / def.step + 0.5) * def.step
      self.value:SetText(fmt(v, def.step))
      if panel.loading then return end  -- being filled in by ns.OpenSettings, not moved
      ns.db[panel.group.unit][def.key] = v
      ns.ApplyGeometry(panel.group)
    end)
    panel.sliders[def.key] = s
  end

  panel.checks = {}
  local top = -24 - #SLIDERS * 40
  for i, def in ipairs(LABELS) do
    local c = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    c:SetSize(22, 22)
    c:SetPoint("TOPLEFT", 8, top - (i - 1) * 24)
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", c, "RIGHT", 2, 0)
    t:SetText(def.label)
    c:SetScript("OnClick", function(self)
      if not panel.group then return end
      ns.db[panel.group.unit].labels[def.key] = self:GetChecked() and true or false
      ns.ApplyGeometry(panel.group)
    end)
    panel.checks[def.key] = c
  end
  panel:Hide()
end

---Open the settings panel for a group, filled in with its settings. Not in combat.
function ns.OpenSettings(f)
  if InCombatLockdown() then return end
  if not panel then BuildPanel() end
  local db = ns.db
  panel.group = f
  panel.title:SetText(f.unit == "player" and "Glance: your bars" or "Glance: target bars")
  panel.loading = true
  for _, def in ipairs(SLIDERS) do
    local s = panel.sliders[def.key]
    s:SetValue(db[f.unit][def.key])
    s.value:SetText(fmt(db[f.unit][def.key], def.step))
  end
  panel.loading = false
  -- Only the checkboxes for this group, in two columns.
  local n = 0
  for _, def in ipairs(LABELS) do
    local c = panel.checks[def.key]
    local isPlayer = f.unit == "player"
    local fits = def.both or (def.target and not isPlayer) or (def.player and isPlayer)
      or (not def.target and not def.player and f.bars[def.key])
    if fits then
      n = n + 1
      c:ClearAllPoints()
      c:SetPoint("TOPLEFT", 8 + ((n - 1) % 2) * 144, -24 - #SLIDERS * 40 - math.floor((n - 1) / 2) * 24)
      c:SetChecked(db[f.unit].labels[def.key] ~= false)
      c:Show()
    else
      c:Hide()
    end
  end
  panel:SetHeight(56 + #SLIDERS * 40 + math.ceil(n / 2) * 24)
  panel:Show()
end

---Close the settings panel, if it's open.
function ns.CloseSettings()
  if panel then panel:Hide() end
end

---Fill the panel in again from the settings, if it's open (after /glance reset).
function ns.ReopenSettings()
  if panel and panel:IsShown() then ns.OpenSettings(panel.group) end
end
