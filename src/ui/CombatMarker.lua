-- ui/CombatMarker.lua: while you're in combat, crossed swords take the place of your
-- level and the spine shows its track: a dark channel, the color of a bar's empty part,
-- that the threat flame climbs (placed by ui/Spine.lua, filled by ui/ThreatMeter.lua).
-- Entering combat the swords shrink in from 140% as they fade in, flash red for a few
-- seconds, then go back to their own color. Leaving combat they shatter: the swords
-- swell, a flash goes off, and an 8 by 8 grid of pieces (each a slice of the same
-- texture) flies outward and fades while your level fades back in. The pieces sit on
-- their own layer so a faded bar doesn't dim them.
-- Setting: "combat".

local ADDON, ns = ...

local RED = { 1, 0.16, 0.1 }
local FLASH = 3      -- seconds the swords flash red after combat starts
local GRID = 8       -- the shatter is GRID x GRID pieces
local POP = 0.15     -- seconds the swords swell before they break
local SWELL = 2.4    -- how big they swell, in icon widths
local IN, BIG = 0.25, 1.4  -- entering combat they shrink from 140% as they fade in
local LIFE = 1.5     -- seconds each piece flies
local ATAN2 = math.atan2 or math.atan  -- the game has atan2; newer Lua folds it into atan
local L, R, T, B = 0.5, 1, 0, 0.5  -- the swords in UI-StateIcon

local function Layer(f)
  if f.shardLayer then return f.shardLayer end
  local layer = CreateFrame("Frame", nil, f)
  layer:SetAllPoints(f)
  layer:SetFrameLevel(f:GetFrameLevel() + 20)
  if layer.SetIgnoreParentAlpha then layer:SetIgnoreParentAlpha(true) end
  local burst = layer:CreateTexture(nil, "ARTWORK")
  burst:SetTexture("Interface\\Cooldown\\star4")
  burst:SetBlendMode("ADD")
  burst:SetVertexColor(1, 0.85, 0.4)
  burst:SetPoint("CENTER", f.level, "CENTER", 0, 0)
  burst:Hide()
  layer.burst = burst
  layer.pieces = {}
  for y = 0, GRID - 1 do
    for x = 0, GRID - 1 do
      local p = layer:CreateTexture(nil, "OVERLAY")
      p:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
      p:SetTexCoord(L + (R - L) * x / GRID, L + (R - L) * (x + 1) / GRID,
                    T + (B - T) * y / GRID, T + (B - T) * (y + 1) / GRID)
      p:Hide()
      p.gx, p.gy = x, y
      layer.pieces[#layer.pieces + 1] = p
    end
  end
  f.shardLayer = layer
  return layer
end

-- Break the swords where they stand. Distances are in icon widths so the burst looks the
-- same at any bar height: pieces travel three to six widths.
local function Shatter(f)
  local layer = Layer(f)
  local size = f.combatIcon:GetWidth()
  local cell = size / GRID
  local c = f.combatRed and RED or { 1, 1, 1 }  -- the pieces keep the swords' color
  for _, p in ipairs(layer.pieces) do
    p:SetVertexColor(c[1], c[2], c[3])
    local cx, cy = (p.gx + 0.5) * cell - size / 2, size / 2 - (p.gy + 0.5) * cell
    local d = math.sqrt(cx * cx + cy * cy) / size
    local a = ATAN2(cy, cx) + (math.random() - 0.5) * 0.9
    local v = (2 + math.random() * 2.2 + d * 2) * size
    p.x, p.y, p.vx, p.vy = cx, cy, math.cos(a) * v, math.sin(a) * v + 0.8 * size
    p.delay, p.cell, p.size = POP + d * 0.1 + math.random() * 0.06, cell, size
    p.spin = 0
    p:SetSize(cell, cell)
    p:ClearAllPoints()
    p:SetPoint("CENTER", f.level, "CENTER", cx, cy)
    p:SetAlpha(1)
    p:Show()
  end
  layer.burst:SetSize(size, size)
  layer.burst:SetAlpha(0)
  layer.burst:Show()
  f.shatterAt = GetTime()
end

local function StopShatter(f)
  f.shatterAt = nil
  if not f.shardLayer then return end
  f.shardLayer.burst:Hide()
  for _, p in ipairs(f.shardLayer.pieces) do p:Hide() end
end

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.combatIcon = f:CreateTexture(nil, "OVERLAY")
  f.combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
  f.combatIcon:SetTexCoord(0.5, 1, 0, 0.5)
  f.combatIcon:SetPoint("CENTER", f.level, "CENTER", 0, 0)
  ns.Vis(f.combatIcon, false)
  f.spineGlow = f:CreateTexture(nil, "BACKGROUND", nil, -6)
  f.spineGlow:SetColorTexture(ns.TRACK[1], ns.TRACK[2], ns.TRACK[3], ns.TRACK[4])
  f.spineGlow:SetWidth(4)
  ns.Vis(f.spineGlow, false)
end)

ns.Hook("geometry", function(f)
  if f.unit ~= "player" then return end
  local ih = math.min(ns.db.player.healthHeight, ns.ICON_BASE)
  f.combatSize = ih + 4
  f.combatIcon:SetSize(ih + 4, ih + 4)
end)

ns.Hook("redraw", function(f)
  if f.unit ~= "player" then return end
  local want = ns.On(f, "combat") and f.exists and (ns.inCombat or UnitAffectingCombat("player")) and true or false
  local was = f.combatIcon:IsShown()
  if ns.Vis(f.combatIcon, want) then
    if want then
      f.combatAt = GetTime()
      StopShatter(f)
      ns.Alpha(f.level, 0)
    elseif was and f.exists then
      Shatter(f)
    else
      ns.Alpha(f.level, 1)
    end
  end
  ns.Vis(f.spineGlow, want)
end)

ns.EveryFrame("timers", function(f)
  if f.unit ~= "player" then return end
  local t = GetTime()
  if f.combatIcon:IsShown() then
    local e = t - (f.combatAt or 0)
    local red = e < FLASH
    if red ~= f.combatRed then
      f.combatRed = red
      if red then f.combatIcon:SetVertexColor(RED[1], RED[2], RED[3]) else f.combatIcon:SetVertexColor(1, 1, 1) end
    end
    local a = red and 0.25 + 0.75 * math.abs(math.sin(e * 7)) or 1
    if e < IN then
      local k = 1 - (1 - e / IN) ^ 3
      local s = (f.combatSize or 20) * (BIG - (BIG - 1) * k)
      f.combatIcon:SetSize(s, s)
      a = a * k
      f.combatGrowing = true
    elseif f.combatGrowing then
      f.combatGrowing = nil
      f.combatIcon:SetSize(f.combatSize or 20, f.combatSize or 20)
    end
    ns.Alpha(f.combatIcon, a)
  end
  if not f.shatterAt then return end
  local e = t - f.shatterAt
  local layer = f.shardLayer
  ns.Alpha(f.level, math.min(1, math.max(0, (e - 0.5) / 0.6)))
  -- The swell: the whole grid grows, still in one piece, then the pieces fly from there.
  local grow = 1 + (SWELL - 1) * math.min(1, e / POP) ^ 0.5
  -- The flash goes off as they break.
  local b = (e - POP) / 0.45
  if b < 1 then
    local bs = layer.pieces[1].size * (1.5 + 4 * math.max(0, b))
    layer.burst:SetSize(bs, bs)
    layer.burst:SetAlpha(b < 0 and 0.5 * (e / POP) or 1 - b)
  else
    layer.burst:Hide()
  end
  local alive = false
  for _, p in ipairs(layer.pieces) do
    local k = e - p.delay
    if k < 0 then
      alive = true
      p:SetPoint("CENTER", f.level, "CENTER", p.x * grow, p.y * grow)
      p:SetSize(p.cell * grow, p.cell * grow)
    elseif k < LIFE then
      alive = true
      local life = k / LIFE
      local scale = SWELL * (1 - life * 0.45)
      p:SetPoint("CENTER", f.level, "CENTER",
        p.x * SWELL + p.vx * k, p.y * SWELL + p.vy * k - 2.2 * p.size * k * k)
      p:SetSize(p.cell * scale, p.cell * scale)
      p:SetAlpha(1 - life * life)
    else
      p:Hide()
    end
  end
  if not alive then StopShatter(f); ns.Alpha(f.level, 1) end
end)
