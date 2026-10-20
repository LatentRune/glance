-- ui/ClickThrough.lua: lets left and right drags that start on the bars still turn the
-- camera.
--
-- Clicks reach the bars only while Shift, Ctrl or Alt is held, except your own bars while
-- they rest faded (out of combat, nothing targeted): a plain click there targets you and
-- wakes them (ui/Fade.lua). Plain right-click still
-- opens the unit menu, through a right-button-only layer over the bars. Both work in
-- combat: the mouse is switched by a secure state driver, not by Glance's own code.
-- Setting: "clickthrough".

local ADDON, ns = ...

---Turn modifier-only clicks on or off for a click-to-target button. Out of combat only.
---wakeable: plain clicks also get through out of combat with nothing targeted.
function ns.ClickThrough(btn, enabled, wakeable)
  if not btn.modDriver then
    local h = CreateFrame("Frame", nil, btn, "SecureHandlerStateTemplate")
    h:SetFrameRef("btn", btn)
    h:SetAttribute("_onstate-mod", [[ self:GetFrameRef("btn"):EnableMouse(newstate == "on") ]])
    btn.modDriver = h
  end
  if enabled then
    RegisterStateDriver(btn.modDriver, "mod", wakeable and "[mod] on; [nocombat,noexists] on; off" or "[mod] on; off")
  else
    UnregisterStateDriver(btn.modDriver, "mod")
    btn:EnableMouse(true)
  end
end

---Give a click-to-target button a layer that takes only right-clicks (for its menu) and
---lets left presses fall through to the camera. Skipped on clients without pass-through.
function ns.RightClickLayer(btn)
  if not btn.SetPassThroughButtons then return end
  local r = CreateFrame("Button", nil, btn, "SecureUnitButtonTemplate")
  r:SetAllPoints(btn)
  r:SetAttribute("unit", btn.unit)
  r:SetAttribute("*type2", (UnitPopup_OpenMenu or (Menu and Menu.ModifyMenu)) and "togglemenu" or "menu")
  r.unit = btn.unit
  if btn.menu then r.menu = function() btn.menu(btn) end end
  r:RegisterForClicks("RightButtonUp")
  if not pcall(r.SetPassThroughButtons, r, "LeftButton") then r:EnableMouse(false) end
  btn.rightLayer = r
end

ns.Hook("create", function(f) ns.RightClickLayer(f) end)

-- While unlocked the bars take every click (to be dragged); otherwise as set.
ns.Hook("geometry", function(f)
  if not f.mover:IsShown() and not InCombatLockdown() then ns.ClickThrough(f, ns.On(f, "clickthrough"), f.unit == "player") end
end)
