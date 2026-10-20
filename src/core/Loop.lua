-- core/Loop.lua: the heartbeat. Decides when things happen; ui/Group.lua and the rest
-- decide what.
--
--   every frame        the "frame" hooks (bars glide toward their values, the bars slide)
--   5 times a second   each group is redrawn (ns.Redraw, ui/Group.lua), which runs every
--                      "redraw" hook; up to 10 times a second while your or your target's
--                      health or power changes
--   at login           settings load, then the "login" hooks make and place the bars
--
-- Bars can't be moved or resized in combat (the game protects click-to-target frames),
-- so geometry asked for in combat waits for combat to end: see ns.GeometryLater.
--
-- Events: PLAYER_LOGIN, PLAYER_REGEN_DISABLED/ENABLED, PLAYER_TARGET_CHANGED,
-- UNIT_DISPLAYPOWER, UPDATE_SHAPESHIFT_FORM, and health and power for you and your target.

local ADDON, ns = ...

-- The named frames the work runs on, made here so their order is fixed: every frame
-- "bars" runs first (this file), then "timers" and "alerts" (ui/ files add to those).
-- Each is one line in /glance cpu.
local bars = ns.HandlerFrame("bars")
ns.HandlerFrame("timers")
ns.HandlerFrame("alerts")

local elapsed = 0
local dirty = false  -- health or power changed: redraw sooner

---Re-apply sizes and positions to every group (ns.ApplyGeometry, ui/Group.lua).
function ns.ApplyGeometryAll()
  for _, f in pairs(ns.groups) do ns.ApplyGeometry(f) end
end

---Ask for geometry once combat ends: frames can't be resized in combat.
function ns.GeometryLater() ns.pendingGeometry = true end

bars:SetScript("OnUpdate", function(_, dt)
  ns.RunHooks("frame", dt)
  elapsed = elapsed + dt
  if elapsed < (dirty and ns.cadence.fast or ns.cadence.slow) then return end
  elapsed, dirty = 0, false
  for _, f in pairs(ns.groups) do
    if f:IsShown() then ns.Redraw(f) end
  end
end)

ns.Listen("bars", { "PLAYER_LOGIN" }, function()
  ns.LoadSettings()
  ns.RunHooks("login")
  if InCombatLockdown() then ns.GeometryLater() end
end)

ns.ListenUnits("bars", { "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXHEALTH", "UNIT_MAXPOWER" },
  { "player", "target" }, function() dirty = true end)

ns.Listen("bars", { "PLAYER_REGEN_DISABLED" }, function() ns.inCombat = true end)
ns.Listen("bars", { "PLAYER_REGEN_ENABLED" }, function() ns.inCombat = false end)

ns.Listen("bars", { "PLAYER_TARGET_CHANGED", "UNIT_DISPLAYPOWER", "UPDATE_SHAPESHIFT_FORM" }, function(event)
  if event == "PLAYER_TARGET_CHANGED" then elapsed = 1 end  -- redraw on the next frame
  if not ns.db then return end
  -- A new target, a form or a spec can add or drop bars; resize once out of combat.
  if InCombatLockdown() then ns.GeometryLater() else ns.ApplyGeometryAll() end
end)
