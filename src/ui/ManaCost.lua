-- ui/ManaCost.lua: while you cast, a pale strip at the end of your mana fill shows what
-- the cast will spend. At the bar's outer (left) end, how many more of your last spell
-- your mana covers: "Frostbolt x12", amber under 5, red under 2. Costs come from
-- features/ManaCost.lua. Setting: "manacost".

local ADDON, ns = ...

local FONT, MANA = ns.FONT, ns.MANA

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  for _, key in ipairs({ "power", "mana" }) do
    local b = f.bars[key]
    b.costSeg = b:CreateTexture(nil, "OVERLAY", nil, -4)
    b.costSeg:SetColorTexture(0.75, 0.9, 1, 0.45)
    ns.Vis(b.costSeg, false)
    b.casts = b:CreateFontString(nil, "OVERLAY")
    b.casts:SetFont(FONT, 9, "OUTLINE")
    b.casts:SetPoint("LEFT", b, "LEFT", 4, 0)
  end
end)

ns.Hook("geometry", function(f)
  if f.unit ~= "player" then return end
  for _, key in ipairs({ "power", "mana" }) do
    f.bars[key].casts:SetFont(FONT, math.max(ns.db.player.fontSize - 2, 6), "OUTLINE")
  end
end)

local function UpdateManaCost(f)
  local bars = f.manaBars
  if not bars then bars = { f.bars.power, f.bars.mana }; f.manaBars = bars end
  -- Mana is on the power bar, or on the mana bar while shapeshifted.
  local manaBar = UnitPowerType("player") == MANA and f.bars.power or (f.bars.mana:IsShown() and f.bars.mana)
  local casting = ns.mana.casting
  f.manaBar, f.costFor = manaBar, casting
  local id = casting and ns.ManaCost(casting) and casting or ns.mana.last
  local cost = ns.On(f, "manacost") and manaBar and manaBar:IsShown() and ns.ManaCost(id)
  for _, b in ipairs(bars) do
    if b ~= manaBar or not cost then ns.Vis(b.costSeg, false); ns.Text(b.casts, ""); b.castsN = nil end
  end
  if not cost then return end
  local mana, max = manaBar.goal or 0, manaBar.max or 0  -- set by the last redraw
  if max <= 0 then return end
  if casting and id == casting then
    ns.DrainSegment(manaBar.costSeg, manaBar, cost / max * (manaBar.w or manaBar:GetWidth()))
  else
    ns.Vis(manaBar.costSeg, false)
  end
  local casts = math.floor(mana / cost)
  local minimal = ns.Minimal()  -- no count in minimal mode
  if manaBar.castsN ~= casts or manaBar.castsFor ~= id or manaBar.castsMin ~= minimal then
    manaBar.castsN, manaBar.castsFor, manaBar.castsMin = casts, id, minimal
    local color = casts < 2 and "ff5544" or casts < 5 and "ffcc33" or "c0c0c0"
    manaBar.casts:SetText(minimal and "" or string.format("|cff%s%s x%d|r", color, ns.CachedSpellName(id) or "Casts", casts))
  end
end

ns.Hook("redraw", function(f)
  if f.unit == "player" then UpdateManaCost(f) end
end)

-- Every frame, but only while the mana fill glides or the cast changes.
ns.EveryFrame("alerts", function(f)
  if f.unit ~= "player" then return end
  local mb = f.manaBar
  if f.costFor ~= ns.mana.casting or (mb and mb.disp ~= mb.goal) then UpdateManaCost(f) end
end)
