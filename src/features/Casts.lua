-- features/Casts.lua: what you and your target are casting, read for the cast bars
-- (ui/CastBar.lua) and the interrupt cue (ui/Interrupt.lua).
--
-- The game is asked about a cast ten times a second, and at once when the unit starts,
-- stops or changes a cast; in between the bar runs on from what it said. Each new cast
-- a hostile mob starts is also remembered for its kind (features/MobAbilities.lua).
-- Setting: "cast". Events: PLAYER_TARGET_CHANGED and the UNIT_SPELLCAST_* events.

local ADDON, ns = ...

-- Units whose cast should be read on the next frame rather than waiting for the 0.1s.
local castAsk = { player = true, target = true }

ns.Listen(nil, { "PLAYER_TARGET_CHANGED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START",
  "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_CHANNEL_UPDATE" }, function(event, unit)
  if event == "PLAYER_TARGET_CHANGED" then castAsk.target = true
  elseif unit == "target" or unit == "player" then castAsk[unit] = true end
end)

---Bring a unit's cast info up to date, if it's time to ask again. c is kept by the
---caller between frames and gets: name, icon, startMS, endMS (game milliseconds),
---locked (can't be interrupted) and channel. c.name is nil when nothing is being cast.
---@param unit "player"|"target"
---@param c table
---@param dt number|nil seconds since the last call
---@param enabled boolean false skips asking (the cast bar is switched off)
function ns.ReadCast(unit, c, dt, enabled)
  c.wait = (c.wait or 0) - (dt or 0.05)
  if not (castAsk[unit] or c.wait <= 0) then return end
  castAsk[unit], c.wait = false, 0.1
  c.name = nil
  if not (enabled and UnitExists(unit)) then return end
  local n, _, ic, s, e, _, _, ni = UnitCastingInfo(unit)
  if n then c.name, c.icon, c.startMS, c.endMS, c.locked, c.channel = n, ic, s, e, ni == true, false
  elseif UnitChannelInfo then
    local cn, _, cic, cs, ce, _, cni = UnitChannelInfo(unit)
    if cn then c.name, c.icon, c.startMS, c.endMS, c.locked, c.channel = cn, cic, cs, ce, cni == true, true end
  end
  if c.name and unit ~= "player" and c.learned ~= c.startMS then c.learned = c.startMS; ns.LearnCast(unit, c.name, c.icon, c.locked) end
end
