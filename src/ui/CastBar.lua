-- ui/CastBar.lua: your cast and the target's, each in its own lane under its bars: the
-- spell's name at the outer end and the seconds left by the spine. Orange for a cast,
-- green for a channel, gray when it can't be interrupted.
--
-- The lane is kept while it could be needed (in combat for yours, while the target is
-- something you can fight for its), with a faint line while empty, so a cast starting or
-- ending never moves what hangs below. Casts are read by features/Casts.lua.
-- Setting: "cast".

local ADDON, ns = ...

ns.Hook("create", function(f, mirrored)
  f.cast = ns.SlimBar(f, mirrored)
  -- A faint line marks the lane while it's reserved and empty.
  f.castLane = f:CreateTexture(nil, "BACKGROUND", nil, -6)
  f.castLane:SetPoint("LEFT", f.cast, "LEFT", 0, 0)
  f.castLane:SetPoint("RIGHT", f.cast, "RIGHT", 0, 0)
  f.castLane:SetHeight(1)
  f.castLane:SetColorTexture(1, 1, 1, 0.07)
  ns.Vis(f.castLane, false)
end)

ns.Hook("geometry", function(f)
  local pos = ns.db[f.unit]
  local minimal = ns.Minimal()
  f.cast:SetHeight(minimal and ns.SlimHeight(pos) or pos.powerHeight)
  ns.SetBarFont(f.cast, minimal and math.max(pos.fontSize - 2, 6) or math.max(pos.fontSize - 1, 6))
  ns.Backing(f.cast, not minimal)
  f.cast.showPct = true
end)

ns.Hook("redraw", function(f)
  if f.unit ~= "player" then f.hostile = UnitCanAttack("player", f.unit) end
end)

-- While placing the bars: a sample cast.
ns.Hook("preview", function(f)
  if f.unit == "player" then return end
  ns.SetBar(f.cast, 0.6, 1, "Cast bar", 1, 0.7, 0)
  f.cast.pct:SetText("1.2")
  ns.Vis(f.cast, true)
end)

local function LaneReserved(f)
  if not ns.On(f, "cast") then return false end
  if f.unit == "player" then return ns.inCombat and true or false end
  return f.exists and f.hostile and not f.dead or false
end

-- Every frame: the bar runs on from what the game last said about the cast.
local function UpdateCast(f, dt)
  local bar, unit, c = f.cast, f.unit, f.castInfo
  if not c then c = {}; f.castInfo = c end  -- kept between frames; ui/MobAbilities.lua reads it
  local reserved = LaneReserved(f)
  if bar.reserved ~= reserved then bar.reserved = reserved; ns.ChainBelow(f) end
  ns.ReadCast(unit, c, dt, ns.On(f, "cast"))
  local t = GetTime() * 1000
  if not c.name or not c.endMS or t > c.endMS + 200 then
    if ns.Vis(bar, false) then ns.ChainBelow(f) end
    ns.Vis(f.castLane, reserved)
    return
  end
  ns.Vis(f.castLane, false)
  local total = math.max(c.endMS - c.startMS, 1)
  local done = math.min(math.max(t - c.startMS, 0), total)
  if bar.total ~= total then bar.total = total; bar:SetMinMaxValues(0, total) end
  bar:SetValue(c.channel and (total - done) or done)  -- channels drain, casts fill
  local look = c.locked and 1 or c.channel and 2 or 3
  if bar.look ~= look then
    bar.look = look
    -- Deep colors so the blue interrupt glow stands out against the fill.
    if look == 1 then bar:SetStatusBarColor(0.5, 0.5, 0.5)
    elseif look == 2 then bar:SetStatusBarColor(ns.Deep(0.3, 0.85, 0.3))
    else bar:SetStatusBarColor(ns.Deep(1, 0.7, 0)) end
  end
  ns.Text(bar.label, c.name)
  ns.Text(bar.pct, string.format("%.1f", (total - done) / 1000))
  if ns.Vis(bar, true) then ns.ChainBelow(f) end
end

ns.EveryFrame("timers", function(f, dt)
  if f.unit == "player" or f.exists then UpdateCast(f, dt) end
end)
