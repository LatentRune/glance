-- features/Bags.lua: full bags. No free slot left in your ordinary bags (quivers, ammo
-- and soul bags don't count). Right-click hides it until your bags have room again and
-- fill up. Setting: "bags".
-- Events: BAG_UPDATE, BAG_UPDATE_DELAYED, PLAYER_ENTERING_WORLD.

local ADDON, ns = ...

local bags = { dirty = true, full = false }

local function ScanBags()
  bags.dirty = false
  local free, any = 0, false
  for bag = 0, 4 do
    local n, kind = ns.FreeSlots(bag)
    if n and (kind or 0) == 0 then
      local size = ns.BagSlots(bag)
      if size > 0 then any = true; free = free + n end
    end
  end
  bags.full = any and free == 0
  if not bags.full then bags.hidden = nil end
end

ns.AddWarning({
  key = "bags",
  icon = "Interface\\Icons\\INV_Misc_Bag_10",
  edge = { 1, 0.5, 0.1, 1 },
  check = function()
    if bags.dirty then ScanBags() end
    return bags.full and not bags.hidden
  end,
  dismiss = function() bags.hidden = true end,
  tip = function(tip)
    tip:SetText("Bags full", 1, 0.5, 0.1)
    tip:AddLine("There's no room for loot. Sell, destroy or bank something.", 1, 1, 1, true)
    tip:AddLine("Right-click to hide it until your bags fill up again.", 0.7, 0.7, 0.7, true)
  end,
})

ns.Listen(nil, { "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "BAG_UPDATE" }, function()
  if ns.db then bags.dirty = true end
end)
