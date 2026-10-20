-- Helpers scenarios use: start the addon, change targets, let time pass.

NS = {}

-- Loads the addon the way the game does (files in .toc order, each given the addon's name
-- and its shared table), then logs in. db: saved settings to start from.
function Boot(db)
  GlanceDB = db or {}
  if GlanceDB.help == nil then GlanceDB.help = false end
  local files = {}
  for line in io.lines(ADDON_DIR .. "Glance.toc") do
    local f = line:match("^%s*([^#%s][^%s]*%.lua)%s*$")
    if f then files[#files + 1] = (f:gsub("\\", "/")) end  -- the game writes folders as core\File.lua
  end
  for _, f in ipairs(files) do
    local chunk = assert(loadfile(ADDON_DIR .. f))
    chunk("Glance", NS)
  end
  FireEvent("ADDON_LOADED", "Glance")
  FireEvent("PLAYER_LOGIN")
  FireEvent("PLAYER_ENTERING_WORLD")
  Advance(0.5)
  P, T = NS.groups.player, NS.groups.target
end

-- A new target (or none): the game sends the event and the bars catch up.
function Target(unit)
  WORLD.units.target = unit
  FireEvent("PLAYER_TARGET_CHANGED")
  FireEvent("UNIT_AURA", "target")
end

function Combat(on)
  WORLD.combat = on
  FireEvent(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end

-- Health changes as the game reports them.
function SetHealth(unit, hp)
  WORLD.units[unit].hp = hp
  FireEvent("UNIT_HEALTH", unit)
end

function AurasChanged(unit) FireEvent("UNIT_AURA", unit) end

-- Short GUIDs for made-up mobs: Creature-0-0-0-0-<npc>-<spawn>.
function Mob(npc, spawn) return string.format("Creature-0-1-2-3-%d-%d", npc, spawn or 1) end
