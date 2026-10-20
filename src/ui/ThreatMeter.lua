-- ui/ThreatMeter.lua: your threat on the target, as a flame climbing the spine.
--
-- A slim upright meter down the spine's whole track (ns.SpineTrack), filling upward with
-- your share of threat, with an ember at its tip that burns hotter (dark red, orange,
-- yellow, white) and throws more sparks as it rises. The number sits left of the ember
-- when the gap has room for it. When you pull aggro the meter flashes red for two
-- seconds. Threat comes from features/Threat.lua. Setting: "threat".

local ADDON, ns = ...

local FONT, TEX = ns.FONT, ns.TEX
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local MOTES = 5  -- sparks in flight at once
-- The ember's color by heat (0..1): { at, r, g, b }, blended between.
local HEAT = { { 0, 0.55, 0.08, 0.02 }, { 0.4, 1, 0.35, 0.05 }, { 0.75, 1, 0.75, 0.2 }, { 1, 1, 1, 0.85 } }
-- The fill's color by threat status: 0 low, 1 overtaking soon, 2 overtaking, 3 tanking.
local THREAT_COLORS = { [0] = { 0.75, 0.75, 0.75 }, { 1, 0.87, 0 }, { 1, 0.53, 0 }, { 1, 0.2, 0.2 } }

local function HeatColor(h)
  if h <= 0 then return HEAT[1][2], HEAT[1][3], HEAT[1][4] end
  for i = 2, #HEAT do
    local a, b = HEAT[i - 1], HEAT[i]
    if h <= b[1] then
      local k = (h - a[1]) / (b[1] - a[1])
      return a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k, a[4] + (b[4] - a[4]) * k
    end
  end
  return HEAT[#HEAT][2], HEAT[#HEAT][3], HEAT[#HEAT][4]
end

local function Glow(m, layer)
  local t = m:CreateTexture(nil, layer)
  t:SetTexture(SPARK)
  t:SetBlendMode("ADD")
  return t
end

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  f.threat = f:CreateFontString(nil, "OVERLAY")
  f.threat:SetFont(FONT, 10, "OUTLINE")
  local m = CreateFrame("Frame", nil, f)
  m:SetSize(4, 40)
  local bg = m:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(ns.TRACK[1], ns.TRACK[2], ns.TRACK[3], ns.TRACK[4])
  m.fill = m:CreateTexture(nil, "ARTWORK")
  m.fill:SetTexture(TEX)
  m.fill:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 0, 0)
  m.fill:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 0, 0)
  m.glow, m.core = Glow(m, "OVERLAY"), Glow(m, "OVERLAY")
  m.motes = {}
  for i = 1, MOTES do
    local t = m:CreateTexture(nil, "OVERLAY")
    t:SetTexture(TEX)
    t:SetBlendMode("ADD")
    t:SetSize(2, 2)
    t:Hide()
    m.motes[i] = t
  end
  -- A red flash over the meter for two seconds when you pull aggro.
  m.flash = m:CreateTexture(nil, "OVERLAY")
  m.flash:SetPoint("TOPLEFT", -2, 2); m.flash:SetPoint("BOTTOMRIGHT", 2, -2)
  m.flash:SetTexture(TEX)
  m.flash:SetBlendMode("ADD")
  m.flash:SetVertexColor(1, 0.25, 0.15)
  m.flash:Hide()
  m.disp, m.goal, m.spawn = 0, 0, 0
  m:Hide()
  f.threatMeter = m
end)

ns.Hook("geometry", function(f)
  if not f.threatMeter then return end
  local pos = ns.db[f.unit]
  -- Minimal: the meter and its ember tell the story without the number.
  f.threat:SetShown(not ns.Minimal())
  f.threat:SetFont(FONT, math.max(pos.fontSize - 2, 6) + 1, "OUTLINE")
end)

-- Where the meter should rise to (0..1) and its color; no frac hides it.
local function SetThreatMeter(f, frac, r, g, b)
  local m = f.threatMeter
  if not frac then
    if ns.Vis(m, false) then m.disp = 0 end
    return
  end
  if m.guid ~= f.guid then m.guid, m.disp = f.guid, 0 end  -- a new mob rises from empty
  m.goal = math.max(0, math.min(frac, 1))
  if m.r ~= r or m.g ~= g or m.b ~= b then
    m.r, m.g, m.b = r, g, b
    m.fill:SetVertexColor(r, g, b)
  end
  ns.Vis(m, true)
end

local FLASH = 2  -- seconds the meter flashes when you pull aggro

ns.Hook("redraw", function(f)
  if not f.threatMeter then return end
  local text, frac, c = ""
  if ns.On(f, "threat") then
    local tanking, status, pct = ns.Threat(f.unit)
    -- Pulled aggro on this mob: flash. Not when it was already on you as you targeted it.
    local m = f.threatMeter
    if tanking and not m.tanking and m.tankGuid == f.guid then m.flashUntil = GetTime() + FLASH end
    m.tanking, m.tankGuid = tanking and true or false, f.guid
    if tanking then text, frac, c = "|cffff3333100|r", 1, THREAT_COLORS[3]
    elseif pct then
      local hex = status == 3 and "ff3333" or status == 2 and "ff8800" or status == 1 and "ffdd00" or "c0c0c0"
      text = string.format("|cff%s%d|r", hex, math.floor(pct + 0.5))
      frac, c = pct / 100, THREAT_COLORS[status or 0] or THREAT_COLORS[0]
    end
  end
  ns.Text(f.threat, text)
  if frac then SetThreatMeter(f, frac, c[1], c[2], c[3]) else SetThreatMeter(f) end
end)

ns.Hook("preview", function(f)
  if not f.threatMeter then return end
  f.threat:SetText("|cffffdd0085|r")
  SetThreatMeter(f, 0.85, 1, 0.87, 0)
end)

-- Every frame while shown: the fill eases to its goal, the ember flickers, sparks rise.
local function AnimateThreat(f, dt)
  local m = f.threatMeter
  if not m.vis then ns.Alpha(ns.groups.player.spineGlow, 1); return end
  m.disp = m.disp + (m.goal - m.disp) * math.min(dt * 6, 1)
  local heat, t = m.disp, GetTime()
  -- Laid over the spine's track (made on your group), kept there as the bars slide or
  -- are moved, and as long as it.
  local _, gap = ns.SpineHalf()
  local p = ns.groups.player
  local sx, top, len = ns.SpineTrack()
  local k = p:GetEffectiveScale() / f:GetEffectiveScale()
  len = math.floor(len * k + 0.5)
  if m.sx ~= sx or m.top ~= top or m.h ~= len or m.k ~= k then
    m.sx, m.top, m.h, m.k = sx, top, len, k
    m:ClearAllPoints()
    m:SetPoint("TOP", p.spineGlow, "TOP", 0, 0)
    m:SetHeight(len)
  end
  -- The meter has the same dark track of its own; the one under it (drawn by your group,
  -- which may sit above the target's) steps aside so the fill shows.
  ns.Alpha(p.spineGlow, 0)
  m.roomy = gap and gap / f:GetEffectiveScale() >= 40
  local x = (m.h or m:GetHeight()) * heat  -- height of the tip above the meter's foot
  m.fill:SetHeight(math.max(x, 0.01))
  ns.Vis(m.fill, x >= 0.5)
  local flashing = m.flashUntil and t < m.flashUntil
  if flashing then ns.Alpha(m.flash, 0.9 * math.abs(math.sin(t * 9))) end
  if ns.Vis(m.flash, flashing or false) and not flashing then m.flashUntil = nil end
  local lit = heat >= 0.02
  ns.Vis(m.core, lit); ns.Vis(m.glow, lit)
  if lit then
    local r, g, b = HeatColor(heat)
    local speed = 6 + 14 * heat
    local fl = 0.7 + 0.3 * (0.6 * math.sin(t * speed) + 0.4 * math.sin(t * speed * 2.3 + 1))  -- flicker
    local size = (5 + 7 * heat) * (0.9 + 0.1 * fl)
    m.core:ClearAllPoints()
    m.core:SetPoint("CENTER", m, "BOTTOM", 0, x)
    m.core:SetSize(size * 1.6, size)
    m.core:SetVertexColor(r, g, b)
    ns.Alpha(m.core, 0.6 + 0.4 * fl)
    m.glow:ClearAllPoints()
    m.glow:SetPoint("CENTER", m, "BOTTOM", 0, x)
    m.glow:SetSize(size * 2.6, size * 2.6)
    m.glow:SetVertexColor(r, g * 0.8, b * 0.6)
    ns.Alpha(m.glow, (0.25 + 0.5 * heat) * fl)
    -- Sparks rise off the tip once it's warm, more of them the hotter it burns.
    if heat > 0.25 then m.spawn = m.spawn + dt * (heat - 0.25) * 12 end
    while m.spawn >= 1 do
      m.spawn = m.spawn - 1
      for _, p in ipairs(m.motes) do
        if not p.at then
          p.at, p.x, p.dx = t, x, (math.random() - 0.5) * 10
          p.life, p.rise = 0.45 + 0.4 * math.random(), 8 + 12 * heat
          break
        end
      end
    end
  else
    m.spawn = 0
  end
  for _, p in ipairs(m.motes) do
    if p.at then
      local age = (t - p.at) / p.life
      if age >= 1 then
        p.at = nil
        ns.Vis(p, false)
      else
        p:ClearAllPoints()
        p:SetPoint("CENTER", m, "BOTTOM", p.dx * age, p.x + 2 + p.rise * age)
        local r, g, b = HeatColor(heat * (1 - 0.5 * age))
        p:SetVertexColor(r, g, b)
        ns.Alpha(p, 0.9 * (1 - age))
        ns.Vis(p, true)
      end
    end
  end
end

-- The number beside the ember, when the gap has room; the flame alone otherwise.
local function PlaceThreatText(f)
  local m = f.threatMeter
  local y = math.floor((m.h or m:GetHeight()) * (m.disp or 0) + 0.5)
  local show = m.vis and m.roomy and not ns.Minimal()
  ns.Alpha(f.threat, show and 1 or 0)
  if show and f.threat.y ~= y then
    f.threat.y = y
    f.threat:ClearAllPoints()
    f.threat:SetPoint("RIGHT", m, "BOTTOM", -6, y)  -- your side: the target's has its target of target
  end
end

ns.EveryFrame("timers", function(f, dt)
  if not f.threatMeter then return end
  AnimateThreat(f, dt)  -- also while unlocked with nothing targeted: the preview
  if f.exists then PlaceThreatText(f) end
end)
