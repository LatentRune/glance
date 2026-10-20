-- ui/PetBar.lua: your pet's health, in a slim bar above the inner half of your bars, by
-- the spine (mirroring the target of target on the other side), with its own click target:
-- left-click targets your pet, right-click opens its menu. For hunters the bar takes the
-- color of the pet's mood: red unhappy, yellow content, green happy.
-- Settings: "pet", "hunter" (the mood color).

local ADDON, ns = ...

local HAPPINESS = { { 1, 0.25, 0.2 }, { 1, 0.85, 0.2 }, { 0.3, 0.85, 0.3 } }  -- by ns.PetHappiness()

ns.Hook("create", function(f, mirrored)
  if f.unit ~= "player" then return end
  f.pet = ns.SlimBar(f, mirrored)
  f.pet.halfWidth = true
  local pb = CreateFrame("Button", "Glance_pet", f, "SecureUnitButtonTemplate")
  pb:SetAttribute("unit", "pet")
  pb:SetAttribute("*type1", "target")
  if UnitPopup_OpenMenu or (Menu and Menu.ModifyMenu) then
    pb:SetAttribute("*type2", "togglemenu")
  else
    pb:SetAttribute("*type2", "menu")
    pb.menu = function()
      if PetFrameDropDown and ToggleDropDownMenu then ToggleDropDownMenu(1, nil, PetFrameDropDown, "cursor") end
    end
  end
  pb:RegisterForClicks("AnyUp")
  pb.unit = "pet"
  pb:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4)  -- over the bar; its width is set with the geometry
  pb:SetSize(100, 8)
  pb:Hide()
  f.petBtn = pb
  ns.RightClickLayer(pb)
  f.pet:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4)
end)

ns.Hook("geometry", function(f)
  if f.unit ~= "player" then return end
  local pos = ns.db.player
  local slimH, minimal = ns.SlimHeight(pos), ns.Minimal()
  f.pet:SetHeight(slimH); f.pet.hgt = slimH; ns.SetBarFont(f.pet, math.max(pos.fontSize - 2, 6))
  f.pet:SetWidth(pos.width * 0.55); f.pet.w = pos.width * 0.55
  f.pet.showPct = not minimal; ns.Backing(f.pet, not minimal)
  if not InCombatLockdown() then  -- the pet's click area waits for combat to end
    f.petBtn:SetSize(pos.width * 0.55, slimH)
    if ns.On(f, "pet") then RegisterUnitWatch(f.petBtn) else UnregisterUnitWatch(f.petBtn); f.petBtn:Hide() end
    ns.ClickThrough(f.petBtn, ns.On(f, "clickthrough"))
  end
end)

ns.Hook("redraw", function(f)
  if f.unit ~= "player" then return end
  ns.UnitBar(f, f.pet, "pet", ns.On(f, "pet"))
  if ns.CLASS ~= "HUNTER" or not ns.On(f, "hunter") or not f.pet:IsShown() then return end
  local mood = ns.PetHappiness()
  local c = mood and HAPPINESS[mood]
  if c then ns.SetBar(f.pet, UnitHealth("pet"), UnitHealthMax("pet"), UnitName("pet") or "", c[1], c[2], c[3]) end
end)

ns.EveryFrame("timers", function(f, dt)
  if f.unit == "player" then ns.Animate(f.pet, dt) end
end)
