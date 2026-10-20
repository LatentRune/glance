-- settings/Slash.lua: the /glance command.
--
--   /glance unlock | lock     show or hide the blue boxes to move the bars
--   /glance blizzard          hide or show Blizzard's player and target frames
--   /glance colors            deep or bright bar colors
--   /glance minimal           minimal mode on or off
--   /glance reset             sizes and positions back to the defaults
--   /glance cpu [seconds]     time what Glance costs for a while (dev/Profile.lua)
--   /glance debug             live costs under your bars (dev/Debug.lua)
--   /glance help              help mode on or off

local ADDON, ns = ...

local say = ns.Say

-- These work in combat; everything else waits for it to end.
local IN_COMBAT_OK = { [""] = true, cpu = true, debug = true, help = true }

SLASH_GLANCE1 = "/glance"
SlashCmdList.GLANCE = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.-)$")
  if InCombatLockdown() and not IN_COMBAT_OK[cmd] then return say("leave combat first.") end
  local db = ns.db
  if cmd == "unlock" or cmd == "lock" then
    ns.SetUnlocked(cmd == "unlock")
    say(cmd == "unlock" and "unlocked: drag the blue boxes, click one for its settings, then /glance lock." or "locked.")
  elseif cmd == "blizzard" then
    db.hideBlizzard = not db.hideBlizzard
    say(db.hideBlizzard and "will hide Blizzard's player and target frames." or "will show Blizzard's frames after /reload.")
    if db.hideBlizzard then ns.HideBlizzard() else ReloadUI() end
  elseif cmd == "reset" then
    ns.ResetGroups()
    ns.ApplyGeometryAll()
    ns.ReopenSettings()
    say("sizes and positions reset; bars back in the middle of the screen.")
  elseif cmd == "colors" then
    db.deepColors = not db.deepColors
    ns.ForgetBarLooks()
    for _, f in pairs(ns.groups) do if f:IsShown() then ns.Redraw(f) end end
    say(db.deepColors and "deep bar colors on." or "bright bar colors on.")
  elseif cmd == "minimal" then
    ns.SetMinimal(not db.minimal)
    say("minimal mode " .. (db.minimal and "on." or "off."))
  elseif cmd == "help" then
    say(ns.ToggleHelp() and "help on: hover any part of the bars. Click the ? under your level to turn it off." or "help off.")
  elseif cmd == "debug" then
    if ns.profiling then return say("wait for /glance cpu to finish.") end
    say(ns.ToggleDebug() and "debug on: live costs under your bars." or "debug off.")
  elseif cmd == "cpu" then
    ns.Profile(tonumber(arg) or 30)
  else
    say("/glance unlock | lock | blizzard (toggle default frames) | colors (deep or bright bars) | minimal | reset | cpu [seconds] | debug | help")
    -- Where to get help. Never a donation link here: Blizzard's add-on policy forbids it.
    say("questions: discord.gg/wcCfAmMsFV  bugs and ideas: github.com/LatentRune/glance/issues")
  end
end
