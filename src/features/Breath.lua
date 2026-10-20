-- features/Breath.lua: how long you can stay underwater, from the game's breath timer.
-- Shown as a countdown on your debuff row by ui/Breath.lua. Setting: "breath".
-- Events: MIRROR_TIMER_START, MIRROR_TIMER_STOP, MIRROR_TIMER_PAUSE.

local ADDON, ns = ...

local breath  -- { value (ms), max (ms), scale (negative while it drains), at, paused }

ns.Listen(nil, { "MIRROR_TIMER_START", "MIRROR_TIMER_STOP", "MIRROR_TIMER_PAUSE" }, function(event, timer, value, max, scale, paused)
  if event == "MIRROR_TIMER_START" and timer == "BREATH" then
    breath = { value = value, max = max, scale = scale, at = GetTime(), paused = paused and paused ~= 0 }
  elseif event == "MIRROR_TIMER_STOP" and timer == "BREATH" then
    breath = nil
  elseif event == "MIRROR_TIMER_PAUSE" and breath then
    breath.paused = (timer or 0) > 0
  end
end)

---Seconds of air left (0 once you're drowning) and the most you can hold, or nil when
---you're not holding your breath.
---@return number|nil left, number|nil max
function ns.Breath()
  local b = breath
  if not b or (b.scale or 0) >= 0 then return end  -- refilling at the surface: nothing to warn about
  local ms = b.value
  if not b.paused then ms = ms + b.scale * (GetTime() - b.at) * 1000 end
  return math.max(ms, 0) / 1000, (b.max or 0) / 1000
end
