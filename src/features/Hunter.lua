-- features/Hunter.lua: what a hunter needs to keep an eye on: pet happiness, ammo, and
-- the dead zone (too close to shoot, too far to melee; Classic only).
-- Shown on your pet bar and alerts row (ui/PetBar.lua, ui/AlertsRow.lua). Setting: "hunter".

local ADDON, ns = ...

---Your pet's happiness: 1 unhappy, 2 content, 3 happy; nil when the client has none.
function ns.PetHappiness()
  return GetPetHappiness and GetPetHappiness()
end

---A warning about ammo as colored text ("AMMO 140", "NO AMMO"), or nil when you have
---enough (200, one stack). Red under 50.
function ns.AmmoAlert()
  local id = GetInventoryItemID and GetInventoryItemID("player", 0)
  if id then
    local n = GetInventoryItemCount("player", 0) or 0
    if n < 200 then return string.format("|cff%sAMMO %d|r", n < 50 and "ff4433" or "ffcc33", n) end
    return
  end
  -- No ammo equipped: a problem unless your ranged weapon is a thrown one.
  local ranged = ns.CLASSIC and GetInventoryItemID and GetInventoryItemID("player", 18)
  if ranged and select(9, GetItemInfo(ranged)) ~= "INVTYPE_THROWN" then return "|cffff4433NO AMMO|r" end
end

---Whether the target is in the dead zone: too close for Auto Shot, too far for Raptor
---Strike.
function ns.DeadZone()
  if not ns.CLASSIC or not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then return end
  if ns.SpellInRange(75, "target") ~= false or ns.SpellInRange(2973, "target") ~= false then return end
  local ok, close = pcall(CheckInteractDistance, "target", 3)  -- 3: about 10 yards (duel range)
  return ok and close
end
