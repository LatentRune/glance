-- features/Threat.lua: your share of the target's threat.
-- Drawn as the flame on the spine by ui/ThreatMeter.lua. Setting: "threat".

local ADDON, ns = ...

---Your threat on a unit you can attack: whether you're tanking it, its status (0 low,
---1 overtaking soon, 2 overtaking, 3 tanking) and your percent of what pulls it. nil when
---you have no threat on it or the client can't say.
---@return boolean|nil tanking, integer|nil status, number|nil pct
function ns.Threat(unit)
  if not (UnitDetailedThreatSituation and UnitCanAttack("player", unit)) then return end
  local tanking, status, pct = UnitDetailedThreatSituation("player", unit)
  if tanking then return true, 3, 100 end
  if pct and pct > 0 then return false, status, pct end
end
