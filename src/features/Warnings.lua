-- features/Warnings.lua: reminders on your debuff row for things worth fixing but easy
-- to miss. Each warning is its own file (Gear.lua, Bags.lua, DeathRecap.lua) and adds
-- itself here; ui/DebuffRow.lua draws them, in the order they were added.
--
-- Adding a warning: make a file in features/ that calls ns.AddWarning, list it in
-- Glance.toc after this file, and give its key a checkbox (core/Defaults.lua,
-- settings/Panel.lua).

local ADDON, ns = ...

ns.warnings = {}       -- in order
ns.warningsByKey = {}  -- the same, by key

---Add a warning to your debuff row.
---@param w table {
---  key: string,          the setting that switches it on or off
---  icon: string,         its icon's texture path
---  edge?: number[],      its border color { r, g, b, a } (red by default)
---  check: fun(): boolean|nil, integer|nil, string|nil, number[]|nil, boolean|nil
---                        whether to show it now, with an optional count, a short text
---                        on the icon, a border color for this time, and whether it
---                        flashes
---  dismiss?: fun(),      right-click: hide it (until it gets worse, say)
---  tip: fun(tip),        fill the tooltip
---}
function ns.AddWarning(w)
  ns.warnings[#ns.warnings + 1] = w
  ns.warningsByKey[w.key] = w
end
