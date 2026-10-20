-- ui/KnownDamage.lua: damage already on its way to the target, drawn on its health bar.
--
-- A thin glowing strip along the bottom, next to where the fill drains: green is what
-- your DoTs on the target will still deal, the pale tip past it your spells on their way
-- (the one you're casting, or one still flying). After the percent, a callout: DOTS KILL,
-- KILL, or xN, how many more of your usual attack it takes. Worked out by
-- features/KnownDamage.lua. Setting: "preview".

local ADDON, ns = ...

local FONT = ns.FONT

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  local hb = f.bars.health
  f.dotGlow = hb:CreateTexture(nil, "OVERLAY", nil, 2)
  f.dotGlow:SetBlendMode("ADD")
  f.castGlow = hb:CreateTexture(nil, "OVERLAY", nil, 2)
  f.castGlow:SetBlendMode("ADD")
  f.dotSeg = hb:CreateTexture(nil, "OVERLAY", nil, 3)
  f.castSeg = hb:CreateTexture(nil, "OVERLAY", nil, 4)
  f.hits = hb:CreateFontString(nil, "OVERLAY")
  f.hits:SetFont(FONT, 12, "OUTLINE")
  f.hits:SetTextColor(1, 1, 1)
  f.hits:SetPoint("LEFT", hb.pct, "RIGHT", 4, 0)
  hb.label:SetPoint("LEFT", f.hits, "RIGHT", 4, 0)  -- a long name gives way to the callout
  for _, t in ipairs({ f.dotGlow, f.castGlow, f.dotSeg, f.castSeg }) do ns.Vis(t, false) end
  f.pv = {}  -- what's known and where the strip's ends are now
end)

ns.Hook("geometry", function(f)
  if not f.hits then return end
  local pos = ns.db[f.unit]
  -- Smaller and without the outline in minimal mode.
  if ns.Minimal() then f.hits:SetFont(FONT, math.max(pos.fontSize - 2, 6), "")
  else f.hits:SetFont(FONT, pos.fontSize + 1, "OUTLINE") end
end)

-- Every frame. The strip's far ends glide when a DoT goes up or a cast starts. A tick or
-- a hit landing doesn't move them: the fill just drains into the strip.
local function UpdatePreview(f, dt)
  local h, pv, unit = f.bars.health, f.pv, f.unit
  local guid = f.guid
  -- What's known only changes with hits, ticks and casts: ten times a second is plenty.
  pv.wait = (pv.wait or 0) - (dt or 0.05)
  if pv.wait <= 0 or pv.guid ~= guid then
    pv.wait, pv.dots, pv.cast, pv.say = 0.1, nil, nil, nil
    if ns.On(f, "preview") then pv.dots, pv.cast, pv.say = ns.KnownDamage(unit) end
  end
  local dots, cast, text = pv.dots, pv.cast, pv.say
  if not dots then
    ns.Vis(f.dotGlow, false); ns.Vis(f.castGlow, false); ns.Vis(f.dotSeg, false); ns.Vis(f.castSeg, false)
    if pv.text ~= nil or pv.dotEnd then ns.Text(f.hits, "") end
    pv.dotEnd, pv.guid, pv.text, pv.next = nil, nil, nil, nil
    return
  end
  -- Where the health will be once the DoTs have run out, and once the cast has landed too.
  local frac = (f.hp or 0) / math.max(f.hpMax or 0, 1)  -- as of the last redraw
  local dotGoal = math.max(frac - dots, 0)
  local castGoal = math.max(dotGoal - cast, 0)
  if not pv.dotEnd or pv.guid ~= guid then
    pv.dotEnd, pv.castEnd, pv.guid, pv.text = dotGoal, castGoal, guid, nil
  else
    local k = math.min(1, (dt or 0.05) * 6)
    pv.dotEnd = pv.dotEnd + (dotGoal - pv.dotEnd) * k
    pv.castEnd = pv.castEnd + (castGoal - pv.castEnd) * k
  end
  local w = h.w or h:GetWidth()
  local x = w * math.min((h.shownValue or 0) / math.max(h.max or 1, 1), 1)  -- right edge of the fill
  local dx = math.min(w * pv.dotEnd, x)
  local cx = math.min(w * pv.castEnd, dx)
  local sh = ns.StripHeight(h)
  ns.GlowStrip(f.dotSeg, f.dotGlow, h, dx, x, sh, false, 0.2, 1, 0.3)
  ns.GlowStrip(f.castSeg, f.castGlow, h, cx, dx, sh, false, 0.75, 1, 0.75)
  -- A new callout replaces the old one once it has held for a moment, so a DoT's timer and
  -- its tick arriving a few frames apart can't make it flicker.
  text = text or ""
  if text ~= pv.next then pv.next, pv.nextAt = text, GetTime() end
  if pv.next ~= pv.text and (not pv.text or GetTime() - pv.nextAt >= 0.15) then
    pv.text = pv.next
    f.hits:SetText(pv.text)
  end
end

ns.EveryFrame("timers", function(f, dt)
  if f.pv and f.exists then UpdatePreview(f, dt) end
end)
