-- ui/AuraFx.lua: buffs and debuffs arriving and leaving. A new icon starts 40% bigger
-- and invisible, then shrinks into place as it fades in. One that's gone breaks apart:
-- it swells a little, then a 6 by 6 grid of pieces, each a slice of its own icon
-- texture, scatters and fades.
--
-- Rows call ns.AuraFxSync(row, unit) after laying out their icons. It tells icons apart
-- by what they show, so a slot changing hands doesn't count as one leaving. Switching
-- targets (a different unit behind the row) changes everything at once, so that pass
-- starts nothing. Setting: "aurafx".

local ADDON, ns = ...

local IN = 0.25      -- seconds to shrink and fade in
local BIG = 1.4      -- how big a new icon starts
local GRID = 6       -- pieces per side
local SWELL = 1.2    -- how much a leaving icon swells before it breaks
local POP = 0.08     -- seconds it swells
local LIFE = 0.9     -- seconds each piece flies
local ATAN2 = math.atan2 or math.atan
local TRIM, SPAN = 0.08, 0.84  -- icons are shown trimmed of their own border

local function Key(ic)
  local fx = ic.effect
  if fx then return "fx|" .. tostring(fx.kind) .. "|" .. tostring(fx.spell) .. "|" .. tostring(fx.target) end
  return tostring(ic.fake or "") .. "|" .. tostring(ic.icon)
end

-- The pieces live on the group, not the row: a row hides when its last icon goes, and
-- the pieces of that icon still have to fly.
local function Layer(f, row)
  if row.fx then return row.fx end
  local layer = CreateFrame("Frame", nil, f)
  layer:SetAllPoints(row)
  layer:SetFrameLevel(row:GetFrameLevel() + 10)
  layer.free, layer.live = {}, {}
  row.fx = layer
  return layer
end

local function Piece(layer)
  local p = table.remove(layer.free)
  if not p then p = layer:CreateTexture(nil, "OVERLAY") end
  return p
end

local function Shatter(f, row, was)
  local layer = Layer(f, row)
  local size = was.size
  local cell = size / GRID
  local now = GetTime()
  for gy = 0, GRID - 1 do
    for gx = 0, GRID - 1 do
      local p = Piece(layer)
      p:SetTexture(was.icon)
      p:SetTexCoord(TRIM + SPAN * gx / GRID, TRIM + SPAN * (gx + 1) / GRID,
                    TRIM + SPAN * gy / GRID, TRIM + SPAN * (gy + 1) / GRID)
      local cx, cy = (gx + 0.5) * cell - size / 2, size / 2 - (gy + 0.5) * cell
      local d = math.sqrt(cx * cx + cy * cy) / size
      local a = ATAN2(cy, cx) + (math.random() - 0.5) * 0.9
      local v = (1 + math.random() * 1.4 + d * 1.2) * size
      p.ox, p.oy, p.x, p.y = was.x, was.y, cx, cy
      p.vx, p.vy = math.cos(a) * v, math.sin(a) * v + 0.6 * size
      p.cell, p.size, p.born = cell, size, now
      p.delay = POP + d * 0.08 + math.random() * 0.05
      p:SetSize(cell, cell)
      p:ClearAllPoints()
      p:SetPoint("CENTER", row, "CENTER", was.x + cx, was.y + cy)
      p:SetAlpha(1)
      p:Show()
      layer.live[#layer.live + 1] = p
    end
  end
end

-- Size an icon's picture and edge around its center (1 is normal), leaving the frame,
-- its clock and its text where they are.
local function Grow(ic, scale)
  local o = (ic.placedSize or ic:GetWidth()) * (scale - 1) / 2
  ic.tex:ClearAllPoints()
  ic.tex:SetPoint("TOPLEFT", 1 - o, -1 + o); ic.tex:SetPoint("BOTTOMRIGHT", -1 + o, 1 - o)
  ic.bg:ClearAllPoints()
  ic.bg:SetPoint("TOPLEFT", -o, o); ic.bg:SetPoint("BOTTOMRIGHT", o, -o)
end

---Compare a row's icons with the last pass: new ones grow in, missing ones break apart.
---@param f table the group the row belongs to
---@param row table a row frame with .icons
---@param unit string whose auras the row shows
---@param quiet boolean|nil record only (a preview)
function ns.AuraFxSync(f, row, unit, quiet)
  local owner = UnitGUID(unit)
  quiet = quiet or not ns.On(f, "aurafx") or owner ~= row.fxOwner or not f:IsVisible()
  row.fxOwner = owner
  local before, now = row.fxSeen or {}, {}
  local rx, ry = row:GetCenter()
  for _, ic in ipairs(row.icons) do
    if ic:IsShown() then
      local k = Key(ic)
      local n = 1
      while now[k .. "#" .. n] do n = n + 1 end  -- two of the same icon
      k = k .. "#" .. n
      local x, y = ic:GetCenter()
      now[k] = { icon = ic.icon, size = ic.placedSize or ic:GetWidth(),
                 x = x and rx and x - rx or 0, y = y and ry and y - ry or 0 }
      if not before[k] and not quiet then
        ic.popAt = GetTime()
        Grow(ic, BIG)
        ns.Alpha(ic, 0)
      end
    end
  end
  if not quiet then
    for k, was in pairs(before) do
      if not now[k] and was.icon then Shatter(f, row, was) end
    end
  end
  row.fxSeen = now
end

-- Runs after the rows' own timers (later in Glance.toc), so a growing icon's fade wins
-- over their alpha for its first quarter second.
ns.EveryFrame("timers", function(f)
  local t = GetTime()
  for r = 1, 3 do
    local row = r == 1 and f.debuffs or r == 2 and f.buffRow or f.petDebuffs
    for _, ic in ipairs(row and row.icons or {}) do
      if ic.popAt then
        local k = (t - ic.popAt) / IN
        if k >= 1 or not ic:IsShown() then
          ic.popAt = nil
          Grow(ic, 1)
          if not ic.flash then ns.Alpha(ic, 1) end
        else
          local e = 1 - (1 - k) ^ 3
          Grow(ic, BIG - (BIG - 1) * e)
          ns.Alpha(ic, e)
        end
      end
    end
    local layer = row and row.fx
    if layer and #layer.live > 0 then
      local live = layer.live
      for i = #live, 1, -1 do
        local p = live[i]
        local age = t - p.born
        local k = age - p.delay
        if k < 0 then
          local g = 1 + (SWELL - 1) * math.min(1, age / POP)
          p:SetPoint("CENTER", row, "CENTER", p.ox + p.x * g, p.oy + p.y * g)
          p:SetSize(p.cell * g, p.cell * g)
        elseif k < LIFE then
          local life = k / LIFE
          local s = p.cell * SWELL * (1 - life * 0.45)
          p:SetPoint("CENTER", row, "CENTER", p.ox + p.x * SWELL + p.vx * k,
            p.oy + p.y * SWELL + p.vy * k - 1.8 * p.size * k * k)
          p:SetSize(s, s)
          p:SetAlpha(1 - life * life)
        else
          p:Hide()
          table.remove(live, i)
          layer.free[#layer.free + 1] = p
        end
      end
    end
  end
end)
