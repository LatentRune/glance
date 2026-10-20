-- features/Consumables.lua: a healing potion or healthstone in your bags that's ready to
-- use. Prompted on your alerts row when you're low (ui/AlertsRow.lua). Setting: "potion".
-- Events: BAG_UPDATE, BAG_UPDATE_DELAYED, PLAYER_ENTERING_WORLD.

local ADDON, ns = ...

-- Item names that heal, in every client's English names. Matched as part of the name, so
-- "Major Healing Potion" and "Major Healthstone" count.
local HEAL_WORDS = { "Healing Potion", "Healthstone", "Healing Draught", "Healing Injector" }
local healItems, bagsDirty, scannedAt = {}, true, 0

-- Your bags are looked through only after they change, and at most once a second.
local function ScanBags()
  bagsDirty, scannedAt = false, GetTime()
  healItems = {}
  local seen = {}
  for bag = 0, 4 do
    for slot = 1, ns.BagSlots(bag) or 0 do
      local id = ns.BagItem(bag, slot)
      if id and not seen[id] then
        seen[id] = true
        local name = ns.ItemName(id)
        if not name then bagsDirty = true end  -- not cached yet; look again shortly
        for _, w in ipairs(HEAL_WORDS) do
          if name and name:find(w, 1, true) then healItems[#healItems + 1] = id; break end
        end
      end
    end
  end
end

local function ItemReady(id)
  local start, duration = ns.ItemCooldown(id)
  return not start or start == 0 or start + (duration or 0) <= GetTime()
end

---The item ID of a healing item you have that's off cooldown, or nil.
function ns.ReadyHeal()
  if bagsDirty and GetTime() - scannedAt > 1 then ScanBags() end
  for _, id in ipairs(healItems) do
    if (GetItemCount(id) or 0) > 0 and ItemReady(id) then return id end
  end
end

ns.Listen("alerts", { "BAG_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD" }, function()
  if ns.db then bagsDirty = true end
end)
