-- features/PowerTicks.lua: when your next energy or mana tick comes.
--
-- Energy comes in a lump every 2 seconds. Mana regenerates in ticks every 2 seconds, but
-- only 5 seconds after you last spent some (the "five-second rule"). Glance can't ask the
-- game when a tick is due, so it watches your power: a jump of 15+ energy is a tick, any
-- mana gain is a tick, any mana loss is spending.
--
-- Drawn as sparks on your power and mana bars by ui/PowerTicks.lua. Setting: "tick".
-- Events: UNIT_POWER_UPDATE, UNIT_POWER_FREQUENT (yours only).

local ADDON, ns = ...

-- When each last happened (GetTime() seconds), or nil before the first.
ns.ticks = { energyAt = nil, manaTickAt = nil, spentAt = nil }
local tick = ns.ticks
local lastEnergy, lastMana

local function OnPower()
  local e, m = UnitPower("player", ns.ENERGY), UnitPower("player", ns.MANA)
  local t = GetTime()
  if lastEnergy and e - lastEnergy >= 15 then tick.energyAt = t end
  if lastMana then
    if m < lastMana then tick.spentAt = t
    elseif m > lastMana then tick.manaTickAt = t end
  end
  lastEnergy, lastMana = e, m
end

ns.Listen("timers", { "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT" }, function(_, unit)
  if unit == "player" then OnPower() end
end)

---How far through the 2-second energy cycle you are (0..1), or nil before a tick was seen.
function ns.EnergyTickFrac(t)
  if not tick.energyAt then return end
  return ((t - tick.energyAt) % 2) / 2
end

---Where mana regen stands: during the five-second rule, ("rule", how far through it);
---after it, ("tick", how far through the 2-second tick); nil before anything was seen.
---@return "rule"|"tick"|nil, number|nil
function ns.ManaTickFrac(t)
  if tick.spentAt and t - tick.spentAt < 5 then return "rule", (t - tick.spentAt) / 5 end
  if tick.manaTickAt then return "tick", ((t - tick.manaTickAt) % 2) / 2 end
end
