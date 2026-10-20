-- core/Compat.lua: one name for game functions that moved between clients. Classic Era
-- has the old global functions (GetContainerNumSlots, UnitAura...); newer clients moved
-- them into tables (C_Container, C_UnitAuras...). Each helper uses whichever exists, so
-- the rest of the addon never has to check.

local ADDON, ns = ...

---A spell's name from its ID.
function ns.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

---A spell's icon from its ID.
function ns.SpellIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
  if GetSpellTexture then return GetSpellTexture(id) end
  if GetSpellInfo then return (select(3, GetSpellInfo(id))) end
end

---Shade a texture from bottom to top in one color, from alpha `bottom` to alpha `top`.
---Older clients take plain numbers (SetGradientAlpha); newer ones take color objects.
function ns.VerticalFade(tex, r, g, b, bottom, top)
  tex:SetColorTexture(1, 1, 1, 1)
  if tex.SetGradientAlpha then
    tex:SetGradientAlpha("VERTICAL", r, g, b, bottom, r, g, b, top)
  elseif CreateColor then
    tex:SetGradient("VERTICAL", CreateColor(r, g, b, bottom), CreateColor(r, g, b, top))
  else
    tex:SetColorTexture(r, g, b, (bottom + top) / 2)
  end
end

---Free slots in a bag, and its kind (0 for an ordinary bag; quivers, ammo pouches and
---soul bags have their own bits).
---@param bag integer 0 (backpack) to 4
---@return integer|nil free, integer|nil kind
function ns.FreeSlots(bag)
  if C_Container and C_Container.GetContainerNumFreeSlots then return C_Container.GetContainerNumFreeSlots(bag) end
  if GetContainerNumFreeSlots then return GetContainerNumFreeSlots(bag) end
end

---How many slots a bag has (0 when there's no bag there).
function ns.BagSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

---The item ID in a bag slot, if any.
function ns.BagItem(bag, slot)
  if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
  return GetContainerItemID and GetContainerItemID(bag, slot)
end

---Which kinds of bag an item fits (ammo for quivers, shards for soul bags), as bits.
function ns.ItemFamily(id)
  if C_Item and C_Item.GetItemFamily then return C_Item.GetItemFamily(id) end
  return GetItemFamily and GetItemFamily(id)
end

---An item's name, or nil while the game hasn't loaded it yet.
function ns.ItemName(id)
  if C_Item and C_Item.GetItemNameByID then return C_Item.GetItemNameByID(id) end
  return (GetItemInfo(id))
end

---An item's icon.
function ns.ItemIcon(id)
  if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
  return GetItemIcon and GetItemIcon(id)
end

---An item's cooldown: when it started and how long it lasts (0 when it's ready).
function ns.ItemCooldown(id)
  if C_Container and C_Container.GetItemCooldown then return C_Container.GetItemCooldown(id) end
  if GetItemCooldown then return GetItemCooldown(id) end
end

---The i-th aura on a unit, as the old UnitAura gave it.
---Newer clients build a table for every call; see features/Auras.lua for the cached list
---that hot paths read instead.
---@param filter string "HELPFUL", "HARMFUL", "HARMFUL|PLAYER"...
---@return string|nil name, any icon, integer count, number duration, number expires
function ns.Aura(unit, i, filter)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    local a = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    if a then return a.name, a.icon, a.applications, a.duration, a.expirationTime end
    return
  end
  local name, icon, count, _, duration, expires = UnitAura(unit, i, filter)
  return name, icon, count, duration, expires
end
