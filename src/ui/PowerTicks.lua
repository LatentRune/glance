-- ui/PowerTicks.lua: a spark riding along your power and mana bars to the next energy
-- tick, or for mana across the five-second rule (reddish) and then to the next regen
-- tick (white). Timing comes from features/PowerTicks.lua. Setting: "tick".

local ADDON, ns = ...

local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local ENERGY, MANA = ns.ENERGY, ns.MANA

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  for _, key in ipairs({ "power", "mana" }) do
    local bar = f.bars[key]
    bar.spark = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    bar.spark:SetTexture(SPARK)
    bar.spark:SetBlendMode("ADD")
    bar.spark:SetWidth(10)
    ns.Vis(bar.spark, false)
  end
end)

ns.Hook("geometry", function(f)
  if f.unit ~= "player" then return end
  for _, key in ipairs({ "power", "mana" }) do
    local bar = f.bars[key]
    bar.spark:SetHeight(bar:GetHeight() * 2.2)
  end
end)

-- Which bar shows energy and which mana depends on your power type, read with each redraw.
ns.Hook("redraw", function(f)
  if f.unit == "player" then f.ptype = UnitPowerType("player") end
end)

local function PlaceSpark(bar, frac)
  local x = math.floor((bar.w or bar:GetWidth()) * frac * 10 + 0.5) / 10
  bar.sparkOn = true
  if bar.sparkX ~= x then
    bar.sparkX = x
    bar.spark:ClearAllPoints()
    bar.spark:SetPoint("CENTER", bar, "LEFT", x, 0)
  end
  ns.Vis(bar.spark, true)
end

local function SparkColor(bar, r, g, b)
  if bar.sparkR ~= r then bar.sparkR = r; bar.spark:SetVertexColor(r, g, b) end
end

-- Power as of the last redraw (the bars' own goal and maximum) is close enough here.
local function NotFull(bar)
  return (bar.goal or 0) < (bar.max or 0)
end

local function PlaceSparks(energyBar, manaBar)
  local t = GetTime()
  local e = energyBar and NotFull(energyBar) and ns.EnergyTickFrac(t)
  if e then PlaceSpark(energyBar, e) end
  if manaBar and NotFull(manaBar) then
    local phase, frac = ns.ManaTickFrac(t)
    if phase then
      PlaceSpark(manaBar, frac)
      if phase == "rule" then SparkColor(manaBar, 1, 0.5, 0.5) else SparkColor(manaBar, 1, 1, 1) end
    end
  end
end

ns.EveryFrame("timers", function(f)
  if f.unit ~= "player" then return end
  local ptype, shown = f.ptype, f.shownBars or {}
  local energyBar = ptype == ENERGY and shown.power and f.bars.power
  local manaBar = (ptype == MANA and f.bars.power) or (shown.mana and f.bars.mana)
  f.bars.power.sparkOn, f.bars.mana.sparkOn = false, false
  if ns.On(f, "tick") then PlaceSparks(energyBar, manaBar) end
  f.sparkBars = f.sparkBars or { f.bars.power, f.bars.mana }
  for _, b in ipairs(f.sparkBars) do
    if not b.sparkOn then ns.Vis(b.spark, false) end
  end
end)
