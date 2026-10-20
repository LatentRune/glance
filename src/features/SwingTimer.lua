-- features/SwingTimer.lua: when your last melee swing or ranged shot went off, and how
-- fast you swing, so ui/SwingTimer.lua can show the time to the next one.
--
-- Melee comes from the combat log: your white hits and misses (main hand only), plus
-- on-next-swing attacks like Heroic Strike that replace a white hit. Ranged comes from
-- Auto Shot and Shoot (wands) going off. Setting: "swing".
-- Events: COMBAT_LOG_EVENT_UNFILTERED, UNIT_SPELLCAST_SUCCEEDED.

local ADDON, ns = ...

-- at: when the last swing went off; speed: seconds between swings; ranged: a shot.
ns.swing = { at = nil, speed = nil, ranged = false }
local swing = ns.swing

local NEXT_MELEE = {}  -- on-next-swing attacks that replace a white hit, by name
for _, id in ipairs({ 78, 845, 2973, 6807 }) do  -- Heroic Strike, Cleave, Raptor Strike, Maul
  local n = ns.SpellName(id)
  if n then NEXT_MELEE[n] = true end
end
local RANGED = { [75] = true, [5019] = true }  -- Auto Shot, Shoot (wands)

local function OnMelee()
  swing.at, swing.speed, swing.ranged = GetTime(), (UnitAttackSpeed("player")), false
end

ns.Listen("timers", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  local _, sub, _, src = CombatLogGetCurrentEventInfo()
  if src ~= UnitGUID("player") then return end
  local info = ns.LogInfo()
  if sub == "SWING_DAMAGE" then
    if not info[21] then OnMelee() end            -- skip off-hand swings
  elseif sub == "SWING_MISSED" then
    if not info[13] then OnMelee() end
  elseif (sub == "SPELL_DAMAGE" or sub == "SPELL_MISSED") and NEXT_MELEE[info[13] or ""] then
    OnMelee()
  end
end)

ns.Listen("timers", { "UNIT_SPELLCAST_SUCCEEDED" }, function(_, unit, _, spellID)
  if unit == "player" and RANGED[spellID] then
    swing.at, swing.speed, swing.ranged = GetTime(), (UnitRangedDamage("player")), true
  end
end)
