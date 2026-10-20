-- features/Supplies.lua: what you carry that a fight uses up, and combo points.
--   Ammo for hunters, soul shards for warlocks: how many you carry, out of what your
--   quiver, ammo pouch or soul bags hold. Shown as the ammo bar (ui/Group.lua).
--   Combo points: shown along the top of the target's health (ui/ComboBar.lua).
-- Settings: "ammo" (the name on the bar), "combo".

local ADDON, ns = ...

local SHARD = 6265  -- Soul Shard's item ID

-- Slots in the bags of a kind (quiver, ammo pouch, soul bag), from their kind bits.
local function SpecialSlots(family)
  local n = 0
  for bag = 1, 4 do
    local _, kind = ns.FreeSlots(bag)
    if kind and kind ~= 0 and bit and bit.band(kind, family) ~= 0 then n = n + (ns.BagSlots(bag) or 0) end
  end
  return n
end

---Ammo or soul shards: how many you have and how many you have room for, with the bar's
---label and color. Without a special bag the bar is full at one stack of ammo (200), or
---five shards.
---@return integer have, integer room, string label, number r, number g, number b
function ns.Supplies()
  if ns.CLASS == "WARLOCK" then
    local have = GetItemCount(SHARD) or 0
    local room = SpecialSlots(4)
    return have, math.max(room > 0 and room or 5, 1), "Soul Shards", 0.6, 0.3, 0.9
  end
  local id = GetInventoryItemID("player", 0)
  local have = id and GetInventoryItemCount("player", 0) or 0
  local family = id and ns.ItemFamily(id)
  local room = SpecialSlots((family and family > 0) and family or 3) * 200
  return have, room > 0 and room or 200, "Ammo", 0.8, 0.7, 0.45
end

---Whether you carry ammo or shards at all, so the ammo bar is worth showing.
function ns.UsesSupplies()
  return ns.CLASS == "WARLOCK" or (ns.CLASS == "HUNTER" and GetInventoryItemID and GetInventoryItemID("player", 0) ~= nil)
end

---Your combo points and how many you can have.
---@return integer cur, integer max
function ns.ComboPoints()
  -- Classic Era keeps combo points on the target; newer clients expose them as a power type.
  local onTarget = GetComboPoints and GetComboPoints("player", "target") or 0
  local asPower = UnitPower("player", ns.COMBO) or 0
  local max = UnitPowerMax("player", ns.COMBO) or 0
  return math.max(onTarget, asPower), max > 0 and max or 5
end

---Whether you build combo points right now: rogues, and druids in cat form.
function ns.UsesCombo()
  return ns.CLASS == "ROGUE" or (ns.CLASS == "DRUID" and UnitPowerType("player") == ns.ENERGY)
end
