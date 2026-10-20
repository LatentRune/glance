-- features/Marks.lua: quick raid marks. Ctrl-click the target bars for skull, Alt-click
-- for cross (ui/RaidMarks.lua), or use the Glance key bindings (Bindings.xml), which mark
-- your mouseover first, then your target. Marking again clears it.

local ADDON, ns = ...

-- Names in the game's Key Bindings window.
BINDING_HEADER_GLANCE = "Glance"
BINDING_NAME_GLANCE_SKULL = "Mark skull (mouseover or target)"
BINDING_NAME_GLANCE_CROSS = "Mark cross (mouseover or target)"

---Put a raid mark on a unit, or take it off if it already has that one.
---@param idx integer 1 star ... 7 cross, 8 skull
function ns.Mark(unit, idx)
  if not unit or not UnitExists(unit) then return end
  SetRaidTarget(unit, GetRaidTargetIndex(unit) == idx and 0 or idx)
end

-- Called by the key bindings in Bindings.xml.
function Glance_Mark(idx)
  ns.Mark(UnitExists("mouseover") and "mouseover" or "target", idx)
end
