-- ui/Group.lua: the two groups of bars, yours and the target's, and what every redraw
-- and resize does to them before handing over to the other ui/ files.
--
-- A group is a secure click-to-target button (left-click targets, right-click opens the
-- unit menu) holding a stack of bars: health, power, and for you ammo or shards and mana
-- while shapeshifted. Around it hang the parts other files make in their "create" hooks
-- (cast bar, debuffs, threat...). Your group reads left to right toward the spine in the
-- middle of the screen; the target's is mirrored.
--
--   ns.Redraw(f)         reads the unit and updates the bars, then the "redraw" hooks
--                        (or the "preview" hooks while unlocked with nothing targeted)
--   ns.ApplyGeometry(f)  applies sizes, fonts and position, then the "geometry" hooks
--
-- What a redraw stores on the group for every-frame work to use without asking the game:
-- f.exists, f.guid, f.hp, f.hpMax, f.dead, f.pvpFlag, f.tagStyle, f.shownBars.

local ADDON, ns = ...

local FONT = ns.FONT
local MANA = ns.MANA
local groups = ns.groups

local function PowerColor(token, ptype)
  local c = PowerBarColor and (PowerBarColor[token] or PowerBarColor[ptype])
  if c then return c.r, c.g, c.b end
  return 0, 0.55, 1
end

-- The game's own name for a power ("Mana", "Energy"), or one made from its token.
local function PowerLabel(token)
  local s = token and _G[token]
  if type(s) == "string" and s ~= "" then return s end
  return token and (token:sub(1, 1) .. token:sub(2):lower()) or "Power"
end

local function NewGroup(unit, mirrored)
  local f = CreateFrame("Button", "Glance_" .. unit, UIParent, "SecureUnitButtonTemplate")
  f:SetAttribute("unit", unit)
  f:SetAttribute("*type1", "target")
  -- Right-click: the same unit menu the default frames give (whisper, invite, trade, inspect...).
  -- Newer clients have a secure "togglemenu" action; older ones open Blizzard's own dropdown,
  -- or Glance's own for NPCs (ui/NpcMenu.lua).
  if UnitPopup_OpenMenu or (Menu and Menu.ModifyMenu) then
    f:SetAttribute("*type2", "togglemenu")
  else
    f:SetAttribute("*type2", "menu")
    f.menu = function(self)
      if self.unit ~= "player" and not UnitIsPlayer(self.unit) and ns.ShowNpcMenu then
        return ns.ShowNpcMenu(self.unit)
      end
      local dd = self.unit == "player" and PlayerFrameDropDown or TargetFrameDropDown
      if dd and ToggleDropDownMenu then ToggleDropDownMenu(1, nil, dd, "cursor") end
    end
  end
  f:RegisterForClicks("AnyUp")
  -- The target's bars tuck in under yours while they're centered (ui/Slide.lua).
  if unit ~= "player" then f:SetFrameStrata("LOW") end
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f.unit = unit
  f.bars = {}
  -- One dark frame behind the stack; the 1px gaps between bars read as dividers.
  local back = f:CreateTexture(nil, "BACKGROUND", nil, -8)
  back:SetPoint("TOPLEFT", -1, 1)
  back:SetPoint("BOTTOMRIGHT", 1, -1)
  back:SetColorTexture(0, 0, 0, 0.85)
  f.back = back

  -- Classification frame: corner brackets around the whole stack for elites, rares,
  -- bosses and enemy players (target only), plus a small tag on its top edge. Colored
  -- and shown by ui/TargetTag.lua.
  if unit ~= "player" then
    local frame = CreateFrame("Frame", nil, f)
    frame:SetPoint("TOPLEFT", -4, 4)
    frame:SetPoint("BOTTOMRIGHT", 4, -4)
    -- Corner brackets rather than a full box: the HUD's targeting reticle.
    frame.edges = ns.Brackets(frame, frame, 0, "BORDER", 0)
    frame.tag = frame:CreateFontString(nil, "OVERLAY")
    frame.tag:SetFont(FONT, 9, "OUTLINE")
    -- Above the bars beside the level (placed below, once the level exists), pinned by
    -- its outer end so longer tags ("ELITE, RUNNER") grow inward.
    frame:Hide()
    f.classFrame = frame
  end

  local order = unit == "player" and { "health", "power", "ammo", "mana" } or { "health", "power" }
  for _, key in ipairs(order) do
    local bar = ns.NewBar(f, mirrored)
    bar.key = key
    f.bars[#f.bars + 1] = bar
    f.bars[key] = bar
  end

  if unit ~= "player" then
    -- Combo points, along the top of the target's health (ui/ComboBar.lua). Drawn on the
    -- bar itself, over its fill but under its text, so the name stays readable.
    local hb = f.bars.health
    local cback = hb:CreateTexture(nil, "ARTWORK", nil, 2)  -- dark, so lit segments stand out
    cback:SetPoint("TOPLEFT"); cback:SetPoint("TOPRIGHT")
    cback:SetColorTexture(0, 0, 0, 0.8)
    cback:Hide()
    f.combo = { segs = {}, back = cback }
  end

  -- Level and PvP icon sit off the bar: left of your health, right of the target's.
  local h = f.bars.health
  f.level = f:CreateFontString(nil, "OVERLAY")
  f.level:SetFont(FONT, 12, "OUTLINE")
  f.pvp = f:CreateTexture(nil, "OVERLAY")
  f.pvp:SetTexCoord(0, 0.609375, 0, 0.609375)
  if mirrored then
    f.level:SetPoint("LEFT", h, "RIGHT", 4, 0)
    f.pvp:SetPoint("LEFT", f.level, "RIGHT", 1, 0)
    -- The tag sits above the bars' outer end (ui/TargetTag.lua places it).
    if f.classFrame then f.classFrame.tag:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4) end
    -- Quest progress for the target, under its bars and debuffs (ui/QuestRows.lua).
    f.quest = CreateFrame("Frame", nil, f)
    f.quest:SetSize(200, 1)
    f.quest:Hide()
  else
    f.level:SetPoint("RIGHT", h, "LEFT", -4, 0)
    f.pvp:SetPoint("RIGHT", f.level, "LEFT", -1, 0)
  end

  -- Drag handle shown only while unlocked (settings/EditMode.lua). Click it for settings.
  local mover = CreateFrame("Frame", nil, f)
  mover:SetAllPoints()
  mover:SetFrameLevel(f:GetFrameLevel() + 10)
  mover:EnableMouse(true)
  mover:RegisterForDrag("LeftButton")
  local t = mover:CreateTexture(nil, "OVERLAY")
  t:SetAllPoints()
  t:SetColorTexture(0.2, 0.6, 1, 0.35)
  mover:SetScript("OnMouseDown", function() ns.OpenSettings(f) end)
  mover:SetScript("OnDragStart", function() f:StartMoving() end)
  mover:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    local cx, cy = UIParent:GetCenter()
    local s = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local pos = ns.db[unit]
    pos.point = "TOPLEFT"
    pos.x = f:GetLeft() - cx / s
    pos.y = f:GetTop() - cy / s
  end)
  mover:Hide()
  f.mover = mover

  groups[unit] = f
  ns.RunHooks("create", f, mirrored)
  return f
end

-- Which bars this unit needs right now, top to bottom, stacked with the gap between.
-- Sets f.shownBars and f.contentHeight (the stack's height).
local function Layout(f)
  local unit = f.unit
  local shown = f.shownBars or {}
  f.shownBars = shown
  local preview = f.mover:IsShown() and not UnitExists(unit)
  shown.health = true
  shown.power = preview or (UnitPowerMax(unit) or 0) > 0
  if unit == "player" then
    local ptype = UnitPowerType("player")
    shown.mana = ptype ~= MANA and (UnitPowerMax("player", MANA) or 0) > 0
    shown.ammo = ns.UsesSupplies()
  end
  local y = 0
  for _, bar in ipairs(f.bars) do
    if shown[bar.key] then
      -- Re-anchored only when its place in the stack moves.
      if bar.layoutY ~= y or not bar:IsShown() then
        bar.layoutY = y
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
        bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -y)
        bar:Show()
      end
      y = y + bar:GetHeight() + ns.db.gap
    elseif bar:IsShown() then
      bar:Hide()
    end
  end
  f.contentHeight = y - ns.db.gap
end

local LEVEL_GOLD, LEVEL_SKULL = { r = 1, g = 0.82, b = 0 }, { r = 1, g = 0.1, b = 0.1 }
local LEVEL_TRIVIAL = { r = 0.75, g = 0.75, b = 0.75 }
-- Border color and tag for special mobs, by classification (drawn by ui/TargetTag.lua).
local CLASS_STYLE = {
  elite = { 1, 0.78, 0.1, "ELITE" }, rareelite = { 1, 0.78, 0.1, "RARE ELITE" },
  rare = { 0.8, 0.85, 0.95, "RARE" }, worldboss = { 1, 0.3, 0.15, "BOSS" },
}

---Read a group's unit and update its bars, then run the "redraw" hooks. Runs 5 to 10
---times a second (core/Loop.lua). While unlocked with nothing targeted, shows sample bars
---and runs the "preview" hooks instead.
function ns.Redraw(f)
  local unit = f.unit
  Layout(f)
  -- What the every-frame animations need, read here a few times a second instead of by
  -- each of them on every frame.
  f.exists = UnitExists(unit)
  if unit == "player" then ns.inCombat, ns.petGUID = UnitAffectingCombat("player"), UnitGUID("pet") end
  if not f.exists then
    f.guid, f.hp, f.hpMax, f.dead = nil, nil, nil, nil
    -- Placeholder while positioning the target bars with nothing targeted.
    if f.mover:IsShown() then
      ns.SetBar(f.bars.health, 1, 1, "Target", 0.8, 0.2, 0.2)
      ns.SetBar(f.bars.power, 1, 1, PowerLabel("MANA"), PowerColor("MANA", MANA))
      f.level:SetText("??")
      f.pvp:Hide()
      ns.RunHooks("preview", f)
    end
    return
  end

  local h = f.bars.health
  local r, g, b = 0.15, 0.75, 0.2
  if unit == "player" then
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[ns.CLASS]
    if c then r, g, b = c.r, c.g, c.b end
  else
    -- Class color for everyone: NPCs have a class too (most are Warrior, casters Mage,
    -- plus some Paladin and Rogue). Friend or foe shows as the panel's edge color instead.
    local _, cls = UnitClass(unit)
    local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if c then r, g, b = c.r, c.g, c.b end
    local rx = UnitReaction(unit, "player")
    local rc = rx and FACTION_BAR_COLORS and FACTION_BAR_COLORS[rx]
    -- Players of your faction get green corner brackets instead (ui/TargetTag.lua).
    if rc and not (ns.On(f, "enemyfaction") and ns.AllyFaction(unit)) then
      f.back:SetColorTexture(rc.r * 0.6, rc.g * 0.6, rc.b * 0.6, 0.95)
    else f.back:SetColorTexture(0, 0, 0, 0.85) end
    -- Tagged by someone else (no loot or credit for you): gray bar and gray edge.
    local tapped
    if UnitIsTapDenied then tapped = UnitIsTapDenied(unit)
    elseif UnitIsTapped then tapped = UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) end
    if tapped then
      r, g, b = 0.45, 0.45, 0.45
      f.back:SetColorTexture(0.25, 0.25, 0.25, 0.95)
    end
  end
  local name = UnitName(unit) or ""
  f.guid, f.hp, f.hpMax, f.dead = UnitGUID(unit), UnitHealth(unit) or 0, UnitHealthMax(unit) or 0, UnitIsDeadOrGhost(unit)
  if f.dead then name = name .. " (dead)"; r, g, b = 0.35, 0.35, 0.35 end
  -- Level: difficulty-colored for the target, + for elite, ?? for skull.
  local lvl = UnitLevel(unit) or 0
  local lvlText = lvl > 0 and tostring(lvl) or "??"
  local cls = ns.Classification(unit)
  if cls == "elite" or cls == "rareelite" or cls == "worldboss" then lvlText = lvlText .. "+" end
  local lc = LEVEL_GOLD
  if unit ~= "player" then
    lc = lvl > 0 and GetQuestDifficultyColor and GetQuestDifficultyColor(lvl) or LEVEL_SKULL
    -- The game's gray for trivial mobs reads as faded against the bars; a lighter gray.
    if lc.r == lc.g and lc.g == lc.b and lc.r < 0.7 then lc = LEVEL_TRIVIAL end
  end
  if f.classFrame then f.tagStyle = CLASS_STYLE[cls or ""] end
  f.level:SetText(lvlText)
  f.level:SetTextColor(lc.r, lc.g, lc.b)

  -- PvP flagged: the name turns green for a friend and red for a foe, and the target's
  -- tag says PVP (ui/TargetTag.lua).
  f.pvpFlag = ns.PvPFlagged(unit)
  f.pvp:Hide()

  ns.SetBar(h, f.hp, f.hpMax, name, r, g, b)
  local nameColor = not f.pvpFlag and 0 or (UnitIsFriend("player", unit) and 1 or 2)
  if h.nameColor ~= nameColor then
    h.nameColor = nameColor
    if nameColor == 1 then h.label:SetTextColor(0.3, 1, 0.3)
    elseif nameColor == 2 then h.label:SetTextColor(1, 0.3, 0.3)
    else h.label:SetTextColor(1, 1, 1) end
  end

  if f.bars.power:IsShown() then
    local ptype, token = UnitPowerType(unit)
    local pr, pg, pb = PowerColor(token, ptype)
    ns.SetBar(f.bars.power, UnitPower(unit), UnitPowerMax(unit), PowerLabel(token), pr, pg, pb)
  end
  if f.bars.mana and f.bars.mana:IsShown() then
    local pr, pg, pb = PowerColor("MANA", MANA)
    ns.SetBar(f.bars.mana, UnitPower(unit, MANA), UnitPowerMax(unit, MANA), PowerLabel("MANA"), pr, pg, pb)
  end
  if f.bars.ammo and f.bars.ammo:IsShown() then
    local have, room, label, cr, cg, cb = ns.Supplies()
    ns.SetBar(f.bars.ammo, math.min(have, room), room, label, cr, cg, cb)
    ns.Text(f.bars.ammo.pct, ns.Minimal() and "" or (have .. "/" .. room))
  end
  ns.RunHooks("redraw", f)
end

---Apply a group's sizes, fonts, scale, opacity and position, then run the "geometry"
---hooks and restack what hangs below (ns.ChainBelow).
---In combat the group itself can't change (it's protected), so this does nothing unless
---`look` is set, and then only what isn't protected: bar heights, fonts and backgrounds.
---The group keeps its size until combat ends, so what hangs below it is moved by the
---difference (f.slack) meanwhile.
---@param look boolean|nil
function ns.ApplyGeometry(f, look)
  local locked = InCombatLockdown()
  if locked and not look then return end
  local pos = ns.db[f.unit]
  local lsize = pos.fontSize + 1
  f.level:SetFont(FONT, lsize, "OUTLINE")
  local ih = math.min(pos.healthHeight, ns.ICON_BASE)
  f.pvp:SetSize(ih + 6, ih + 6)
  local minimal = ns.Minimal()
  if minimal then f.back:Hide() else f.back:Show() end
  for _, bar in ipairs(f.bars) do
    -- Minimal: only the target's name is left, at the slim bars' height and text size.
    bar.showLabel = pos.labels[bar.key] ~= false and (not minimal or (bar.key == "health" and f.unit ~= "player"))
    bar.showPct = not minimal
    ns.Backing(bar, not minimal)
    local h = minimal and ns.SlimHeight(pos) or bar.key == "health" and pos.healthHeight or pos.powerHeight
    bar:SetHeight(h)
    bar.hgt = h
    local size = minimal and math.max(pos.fontSize - 2, 6) or math.max(pos.fontSize - (h < 16 and 1 or 0), 6)
    bar.label:SetFont(FONT, size, "OUTLINE")
    -- Health numbers are the read at a glance: a size up, beside the spine.
    bar.pct:SetFont(FONT, (bar.key == "health" and not minimal) and size + 4 or size, "OUTLINE")
  end
  if not locked then
    f:SetScale(pos.scale)
    f:SetAlpha(pos.alpha)
    f.glanceAlpha = nil  -- the fade sets it again on its next step
    f:SetWidth(pos.width)
    for _, bar in ipairs(f.bars) do bar.w = pos.width end  -- the bars span the group
  end
  Layout(f)
  local h = math.max(f.contentHeight or pos.healthHeight, 1)
  if locked then
    f.slack = f:GetHeight() - h
  else
    f.slack = 0
    f:SetHeight(h)
    ns.PlaceGroup(f)
  end
  -- The dark frame and the elite border follow the bars, not the group.
  f.back:SetPoint("BOTTOMRIGHT", 1, -1 + f.slack)
  if f.classFrame then f.classFrame:SetPoint("BOTTOMRIGHT", 4, -4 + f.slack) end
  ns.RunHooks("geometry", f)
  ns.ChainBelow(f)
end

---Clear what each bar remembers drawing, so the next redraw sets its text and colors
---again (after deep colors or minimal mode change).
function ns.ForgetBarLooks()
  for _, f in pairs(groups) do
    for _, bar in ipairs(f.bars) do bar.shownMax = nil; bar.r = nil end
  end
end

-- Login: make both groups. The target's shows and hides with your target, securely, so
-- it works in combat.
ns.Hook("login", function()
  NewGroup("player", false)
  NewGroup("target", true)
  RegisterUnitWatch(groups.target)
  ns.ApplyGeometryAll()
end)

-- Every frame, the bars glide toward their values.
ns.Hook("frame", function(dt)
  for _, f in pairs(groups) do
    for _, bar in ipairs(f.bars) do ns.Animate(bar, dt) end
  end
end)

-- Geometry asked for during combat happens now.
ns.Listen("bars", { "PLAYER_REGEN_ENABLED" }, function()
  if not ns.pendingGeometry then return end
  ns.pendingGeometry = false
  ns.ApplyGeometryAll()
  ns.HideBlizzard()
end)
