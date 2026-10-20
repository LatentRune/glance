-- ui/widgets/Strip.lua: pieces drawn on a bar: a segment across its full height, or a
-- thin strip along its bottom or top edge. Positions are pixels from the bar's left edge.
-- Each remembers where it was put and only moves when that changes (they run every frame).

local ADDON, ns = ...

---A texture across the bar's full height from `from` to `to` pixels. Hidden when
---narrower than a pixel.
function ns.Segment(tex, bar, from, to)
  if to - from < 1 then ns.Vis(tex, false); return end
  from, to = math.floor(from * 10 + 0.5) / 10, math.floor(to * 10 + 0.5) / 10
  if tex.segFrom == from and tex.segTo == to and tex.vis then return end
  tex.segFrom, tex.segTo = from, to
  tex:ClearAllPoints()
  tex:SetPoint("TOPLEFT", bar, "TOPLEFT", from, 0)
  tex:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", to, 0)
  ns.Vis(tex, true)
end

---One piece of a strip: from..to pixels across, h pixels tall, on the bar's bottom edge
---(or its top edge).
function ns.Strip(tex, bar, from, to, h, top)
  if to - from < 1 then ns.Vis(tex, false); return end
  from, to = math.floor(from * 10 + 0.5) / 10, math.floor(to * 10 + 0.5) / 10
  if tex.segFrom == from and tex.segTo == to and tex.segH == h and tex.vis then return end
  tex.segFrom, tex.segTo, tex.segH = from, to, h
  tex:ClearAllPoints()
  if top then
    tex:SetPoint("TOPLEFT", bar, "TOPLEFT", from, 0)
    tex:SetPoint("BOTTOMRIGHT", bar, "TOPLEFT", to, -h)
  else
    tex:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", from, 0)
    tex:SetPoint("TOPRIGHT", bar, "BOTTOMLEFT", to, h)
  end
  ns.Vis(tex, true)
end

---A strip with a soft glow of its own color around it and no border.
function ns.GlowStrip(tex, glow, bar, from, to, h, top, r, g, b)
  if to - from < 1 then ns.Vis(tex, false); ns.Vis(glow, false); return end
  ns.Strip(glow, bar, from - 2, to + 2, h + 2, top)
  ns.Strip(tex, bar, from, to, h, top)
  if tex.colorR ~= r or tex.colorG ~= g then
    tex.colorR, tex.colorG = r, g
    glow:SetColorTexture(r, g, b, 0.3)
    tex:SetColorTexture(r, g, b, 1)
  end
end

---Strip thickness: a hairline, about a fourteenth of the original 18px health bar.
function ns.StripHeight(bar)
  return math.max(math.floor(math.min(bar.hgt or bar:GetHeight(), ns.ICON_BASE) * 0.07 + 0.5), 1)
end

---Where a bar's fill currently ends, in pixels from its left edge, and the bar's width.
function ns.FillEdge(bar)
  local w = bar.w or bar:GetWidth()
  local max, v = bar.max, bar.shownValue  -- kept by SetBar and Animate
  if not max or not v then
    local _
    _, max = bar:GetMinMaxValues()
    v = bar:GetValue()
  end
  return w * math.min(v / math.max(max, 1), 1), w
end

---Shade the part of a bar's fill that's about to drain (`width` pixels), next to its
---empty side.
function ns.DrainSegment(tex, bar, width)
  local x, w = ns.FillEdge(bar)
  width = math.min(width, x)
  if bar.reversed then ns.Segment(tex, bar, w - x, w - x + width) else ns.Segment(tex, bar, x - width, x) end
end
