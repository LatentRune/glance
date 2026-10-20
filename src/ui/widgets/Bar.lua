-- ui/widgets/Bar.lua: the bar every part of Glance is built from, and its helpers.
--
-- A bar is a StatusBar with a label (the name) and a percent. It eases toward its value
-- every frame rather than jumping (ns.Animate), and only calls into the game when
-- something it shows changed. Your bars drain toward the right, toward the spine; the
-- target's (mirrored) toward the left.

local ADDON, ns = ...

local FONT, TEX = ns.FONT, ns.TEX

---Corner brackets around a region: eight short arms, two per corner, `out` pixels
---outside it. Used for the target's classification border and the execute reticle.
---@return table[] arms the eight textures, to color or show together
function ns.Brackets(owner, around, out, layer, sub, r, g, b)
  local arms = {}
  local ARM = 7  -- pixels each arm reaches along its edge
  for _, c in ipairs({ { "TOPLEFT", -1, 1 }, { "TOPRIGHT", 1, 1 }, { "BOTTOMLEFT", -1, -1 }, { "BOTTOMRIGHT", 1, -1 } }) do
    local x, y = c[2] * out, c[3] * out
    local h = owner:CreateTexture(nil, layer, nil, sub)
    h:SetPoint(c[1], around, c[1], x, y)
    h:SetSize(ARM, 2)
    local v = owner:CreateTexture(nil, layer, nil, sub)
    v:SetPoint(c[1], around, c[1], x, y)
    v:SetSize(2, ARM)
    for _, t in ipairs({ h, v }) do
      t:SetColorTexture(r or 1, g or 1, b or 1, 1)
      arms[#arms + 1] = t
    end
  end
  return arms
end

---A new bar. mirrored puts the label on the right and fills from the left.
---Fields others read: b.label, b.pct (font strings), b.bg (the empty part), b.reversed,
---and after ns.SetBar: b.goal, b.max (the value and maximum), b.shownValue (where the
---fill is drawn now), b.w and b.hgt (size, when set by geometry).
function ns.NewBar(parent, mirrored)
  local b = CreateFrame("StatusBar", nil, parent)
  b:SetStatusBarTexture(TEX)
  b:SetMinMaxValues(0, 1)
  -- Your bars are anchored on the right and drain toward it; the target's drain toward the left.
  if not mirrored then b:SetReverseFill(true); b.reversed = true end
  -- Empty part is a deep shade of the bar's own color. Over the fill, a smooth light at
  -- the top fading down and a shadow at the bottom fading up: no hard bands.
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
  local sheen = b:CreateTexture(nil, "OVERLAY", nil, -2)
  sheen:SetAllPoints()
  ns.VerticalFade(sheen, 1, 1, 1, 0, 0.32)
  local edge = b:CreateTexture(nil, "OVERLAY", nil, -1)
  edge:SetPoint("TOPLEFT"); edge:SetPoint("TOPRIGHT")
  edge:SetHeight(1)
  edge:SetColorTexture(1, 1, 1, 0.12)
  -- A darker underside gives the fill depth, so hit flashes and gold combo points stand out.
  local shade = b:CreateTexture(nil, "OVERLAY", nil, -3)
  shade:SetAllPoints()
  ns.VerticalFade(shade, 0, 0, 0, 0.6, 0)
  -- Minimal mode drops the background but keeps this hairline, so the fill's length still
  -- reads against the full width.
  local hair = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  hair:SetPoint("BOTTOMLEFT"); hair:SetPoint("BOTTOMRIGHT")
  hair:SetHeight(1)
  hair:SetColorTexture(1, 1, 1, 0.14)
  hair:Hide()
  b.sheen, b.edge, b.shade, b.hair = sheen, edge, shade, hair

  b.pct = b:CreateFontString(nil, "OVERLAY")
  b.pct:SetFont(FONT, 11, "OUTLINE")
  b.label = b:CreateFontString(nil, "OVERLAY")
  b.label:SetFont(FONT, 11, "OUTLINE")
  b.label:SetWordWrap(false)
  if mirrored then
    b.pct:SetPoint("LEFT", 4, 0)
    b.label:SetPoint("RIGHT", -4, 0)
    b.label:SetPoint("LEFT", b.pct, "RIGHT", 4, 0)
    b.label:SetJustifyH("RIGHT")
  else
    b.pct:SetPoint("RIGHT", -4, 0)
    b.label:SetPoint("LEFT", 4, 0)
    b.label:SetPoint("RIGHT", b.pct, "LEFT", -4, 0)
    b.label:SetJustifyH("LEFT")
  end
  return b
end

---A slim bar with a 1px dark frame, for the cast bar, target of target and pet. Hidden.
function ns.SlimBar(f, mirrored)
  local b = ns.NewBar(f, mirrored)
  local back = b:CreateTexture(nil, "BACKGROUND", nil, -8)
  back:SetPoint("TOPLEFT", -1, 1)
  back:SetPoint("BOTTOMRIGHT", 1, -1)
  back:SetColorTexture(0, 0, 0, 0.85)
  b.back = back
  b:Hide()
  return b
end

---The slim bars' height (target of target, pet), which every bar takes in minimal mode.
---@param pos table a group's settings (ns.db.player or ns.db.target)
function ns.SlimHeight(pos) return math.max(pos.powerHeight - 2, 8) end

---Set both of a bar's font sizes.
function ns.SetBarFont(b, size)
  b.label:SetFont(FONT, size, "OUTLINE")
  b.pct:SetFont(FONT, size, "OUTLINE")
end

---Show or hide a bar's background, sheen and dark frame (minimal mode hides them and
---keeps a hairline instead).
function ns.Backing(b, on)
  b.bg:SetShown(on); b.sheen:SetShown(on); b.edge:SetShown(on)
  if b.shade then b.shade:SetShown(on) end
  if b.hair then b.hair:SetShown(not on) end
  if b.back then b.back:SetShown(on) end
end

---Give a bar a new value, label and color. The fill glides there (ns.Animate) unless it's
---a new unit (a new maximum), when it jumps. The percent shows only when it says
---something: not for a full bar out of combat. Health at 25% or less turns it red.
function ns.SetBar(b, cur, max, label, r, g, bl)
  max = (max and max > 0) and max or 1
  cur = cur or 0
  r, g, bl = ns.Deep(r, g, bl)
  if b.max ~= max or not b.disp then b.disp = cur end  -- jump on a new unit, glide otherwise
  b.max, b.goal = max, cur
  if b.shownMax ~= max then b.shownMax, b.shownValue = max, nil; b:SetMinMaxValues(0, max) end
  if b.r ~= r or b.g ~= g or b.b ~= bl then
    b.r, b.g, b.b = r, g, bl
    b:SetStatusBarColor(r, g, bl)
    local k = ns.db and ns.db.deepColors and 0.1 or 0.2
    b.bg:SetColorTexture(r * k, g * k, bl * k, 0.92)
  end
  ns.Text(b.label, b.showLabel == false and "" or label)
  local p = ns.Pct(cur, max)
  -- Just the number; out of combat a full bar has nothing to say.
  local calm = p >= 100 and not ns.inCombat
  ns.Text(b.pct, (b.showPct == false or calm) and "" or p)
  local low = b.key == "health" and p <= 25
  if b.pctLow ~= low then
    b.pctLow = low
    if low then b.pct:SetTextColor(1, 0.35, 0.3) else b.pct:SetTextColor(1, 1, 1) end
  end
end

---Ease a bar toward its value; called every frame.
function ns.Animate(b, dt)
  if not b.goal then return end
  if b.disp ~= b.goal then
    local d = b.goal - b.disp
    if math.abs(d) < b.max * 0.002 then b.disp = b.goal else b.disp = b.disp + d * math.min(1, dt * 12) end
  end
  -- Always resync: a new maximum (level-up, form change, buff) or a fresh bar must
  -- not leave the fill behind the number.
  if b.shownValue ~= b.disp then b.shownValue = b.disp; b:SetValue(b.disp) end
end
