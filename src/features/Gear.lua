-- features/Gear.lua: worn gear. Your most worn item at 25% durability or less, red once
-- something breaks. Right-click hides it until it gets worse (something else breaks, or
-- another 10%). Setting: "gear".
-- Events: UPDATE_INVENTORY_DURABILITY, PLAYER_ENTERING_WORLD.

local ADDON, ns = ...

local WORN_AT, WORSE_BY = 0.25, 0.10
local WORN, BROKEN = { 1, 0.6, 0.1, 1 }, { 1, 0.15, 0.15, 1 }
local gear = { dirty = true, low = 1, broken = 0 }  -- low: the most worn item's durability, 0..1

local function ScanGear()
  gear.dirty = false
  local low, broken = 1, 0
  for slot = 1, GetInventoryItemDurability and 18 or 0 do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 then
      if cur / max < low then low = cur / max end
      if cur == 0 then broken = broken + 1 end
    end
  end
  gear.low, gear.broken = low, broken
  if low > WORN_AT then gear.hidden = nil end  -- repaired: the next wear warns again
end

ns.AddWarning({
  key = "gear",
  icon = "Interface\\Icons\\Trade_BlackSmithing",
  check = function()
    if gear.dirty then ScanGear() end
    if gear.low > WORN_AT then return end
    local h = gear.hidden
    if h and gear.broken <= h.broken and gear.low > h.low - WORSE_BY then return end
    return true, gear.broken, math.floor(gear.low * 100) .. "%", gear.broken > 0 and BROKEN or WORN
  end,
  dismiss = function() gear.hidden = { low = gear.low, broken = gear.broken } end,
  tip = function(tip)
    if gear.broken > 0 then
      tip:SetText(gear.broken == 1 and "Broken gear" or (gear.broken .. " pieces of broken gear"), 1, 0.3, 0.3)
      tip:AddLine("Broken gear gives you none of its stats. Repair at a vendor.", 1, 1, 1, true)
    else
      tip:SetText("Worn gear", 1, 0.6, 0.1)
      tip:AddLine(string.format("Your most worn item is at %d%% durability. Repair at a vendor before it breaks.",
        math.floor(gear.low * 100)), 1, 1, 1, true)
    end
    tip:AddLine("Right-click to hide it until it gets worse. Repairing resets it.", 0.7, 0.7, 0.7, true)
  end,
})

ns.Listen(nil, { "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD" }, function()
  if ns.db then gear.dirty = true end
end)
