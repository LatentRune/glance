-- core/Namespace.lua: the shared table every file of Glance receives, and the constants
-- they all use. Loaded first.
--
-- Each file starts with `local ADDON, ns = ...`: the game hands every file of the addon
-- its name and one shared table, `ns`. Anything a file wants others to use goes on `ns`;
-- everything else stays local to the file.
--
-- How the folders fit together (see docs/ARCHITECTURE.md):
--   core/      this foundation: settings, hooks, the redraw heartbeat, API shims
--   features/  works things out from the game (threat, swings, known damage...); no frames
--   ui/        draws what features worked out; asks the game for nothing beyond unit bars
--   settings/  the settings panel, Edit Mode, minimal and help modes, /glance
--   dev/       the CPU and memory panel and /glance cpu

local ADDON, ns = ...
ns.ADDON = ADDON

ns.FONT = "Fonts\\ARIALN.TTF"
ns.TEX = "Interface\\Buttons\\WHITE8X8"

-- Icons, debuffs and strips keep the size they had at the original 18px health height
-- (or smaller, if you shrink it); only the health bar itself grows.
ns.ICON_BASE = 18

-- The game's power type numbers (Enum.PowerType on newer clients).
ns.MANA, ns.RAGE, ns.ENERGY, ns.COMBO = 0, 1, 3, 4

local _, CLASS = UnitClass("player")
ns.CLASS = CLASS  -- "WARRIOR", "MAGE"...: never changes while you play

-- Classic Era and its seasons, as opposed to the current retail game.
ns.CLASSIC = not (WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- The two groups of bars, by unit: ns.groups.player and ns.groups.target. Made at login
-- by ui/Group.lua.
ns.groups = {}

-- The addon's named event and update frames, for the CPU numbers in /glance cpu and
-- /glance debug. Filled by ns.HandlerFrame (core/Hooks.lua).
ns.handlers = {}

-- How often things are asked for, in seconds. Everything is redrawn every `slow`, and
-- every `fast` while your or your target's health or power is changing. Auras are read
-- again at least every `aura` even when the game doesn't say they changed.
ns.cadence = { slow = 0.2, fast = 0.1, aura = 1 }

-- Saved settings, set at login (core/Defaults.lua): ns.db is shared by all your
-- characters, ns.char is this character's own.
ns.db, ns.char = nil, nil

---Whether a feature's checkbox is on for a group. Everything is on unless unticked.
---@param f table a group (ns.groups.player or ns.groups.target)
---@param key string the feature's key in the settings, e.g. "threat"
---@return boolean
function ns.On(f, key) return ns.db[f.unit].labels[key] ~= false end
