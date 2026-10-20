-- dev/Profile.lua: /glance cpu. Times each of Glance's named frames for a while (30
-- seconds by default) and prints where the time went, plus how memory grew. Play as
-- usual meanwhile. The frames are the ones in ns.handlers (core/Hooks.lua): each name is
-- one line.

local ADDON, ns = ...

local say = ns.Say

local function Memory()
  if not (UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then return end
  UpdateAddOnMemoryUsage()
  return GetAddOnMemoryUsage(ADDON)
end

---Start timing for `seconds`; prints the results when done. Sets ns.profiling meanwhile.
function ns.Profile(seconds)
  if ns.profiling then return say("already timing.") end
  if ns.Debugging and ns.Debugging() then return say("debug mode is on and already shows this live.") end
  if not debugprofilestop or not (C_Timer and C_Timer.After) then return say("this client can't time addons.") end
  local spent, wrapped = {}, {}
  -- Each script is wrapped to add its time up, and put back afterwards.
  local function wrap(name, fr, script)
    local fn = fr:GetScript(script)
    if not fn then return end
    local key = name .. (script == "OnUpdate" and " (every frame)" or " (events)")
    spent[key] = 0
    fr:SetScript(script, function(...)
      local t = debugprofilestop()
      fn(...)
      spent[key] = spent[key] + debugprofilestop() - t
    end)
    wrapped[#wrapped + 1] = { fr, script, fn }
  end
  for name, fr in pairs(ns.handlers) do wrap(name, fr, "OnUpdate"); wrap(name, fr, "OnEvent") end
  local m0, t0 = Memory(), debugprofilestop()
  ns.profiling = true
  say(("timing for %d seconds; play as usual."):format(seconds))
  C_Timer.After(seconds, function()
    for _, w in ipairs(wrapped) do w[1]:SetScript(w[2], w[3]) end
    ns.profiling = false
    local secs, keys, total = (debugprofilestop() - t0) / 1000, {}, 0
    for k, ms in pairs(spent) do keys[#keys + 1] = k; total = total + ms end
    table.sort(keys, function(a, b) return spent[a] > spent[b] end)
    say(("%.2f ms per second in all (%.2f%% of the time)."):format(total / secs, total / secs / 10))
    for _, k in ipairs(keys) do
      if spent[k] > 0 then say(("  %s: %.2f ms/s"):format(k, spent[k] / secs)) end
    end
    local m1 = Memory()
    if m0 and m1 then say(("memory %d KB -> %d KB"):format(m0, m1)) end
  end)
end
