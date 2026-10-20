-- ui/PetDebuffs.lua: debuffs on your pet, in a row above its bar, newest at the right.
-- Shown with the pet bar and the "debuffs" setting.

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  f.petDebuffs = CreateFrame("Frame", nil, f)
  f.petDebuffs.icons = {}
  f.petDebuffs.alignRight = true
  f.petDebuffs.above = true  -- not in the stack under the bars (ui/Stack.lua)
  f.petDebuffs:SetPoint("BOTTOMLEFT", f.pet, "TOPLEFT", 0, 3)
  f.petDebuffs:SetPoint("BOTTOMRIGHT", f.pet, "TOPRIGHT", 0, 3)
  f.petDebuffs:Hide()
end)

ns.Hook("geometry", function(f)
  if not f.petDebuffs then return end
  f.petDebuffs.size = ns.db[f.unit].powerHeight + 4
  f.petDebuffs:SetHeight(f.petDebuffs.size)
end)

ns.Hook("redraw", function(f)
  if not f.petDebuffs then return end
  if f.pet:IsShown() and ns.On(f, "debuffs") then ns.RedrawDebuffs(f, false, f.petDebuffs, "pet")
  else f.petDebuffs:Hide() end
end)

ns.EveryFrame("timers", function(f)
  if f.petDebuffs and f.timesDue then ns.UpdateIconTimes(f, f.petDebuffs) end
end)
