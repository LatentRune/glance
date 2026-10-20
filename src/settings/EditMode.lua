-- settings/EditMode.lua: moving the bars. While unlocked each group shows a blue box:
-- drag it to move the group, click it for its settings (settings/Panel.lua). Unlocked
-- with Blizzard's Edit Mode where the client has it, or with /glance unlock.
--
-- On first run (and after /glance reset) the bars start at their defaults, meeting just
-- below the middle of the screen (core/Defaults.lua), so nothing needs setting up.

local ADDON, ns = ...

---Show or hide the blue boxes. Unlocked, the target's group shows even with no target,
---with sample bars (the "preview" hooks). Not in combat.
function ns.SetUnlocked(on)
  if InCombatLockdown() then return end
  -- Every group is marked first: placing one checks whether yours is unlocked (the bars
  -- don't slide while unlocked, ui/Slide.lua).
  for _, f in pairs(ns.groups) do f.unlocked = on end
  for _, f in pairs(ns.groups) do
    f.mover:SetShown(on)
    if on then UnregisterUnitWatch(f); f:Show() elseif f.unit == "target" then RegisterUnitWatch(f) end
    ns.ApplyGeometry(f)
  end
  if not on then ns.CloseSettings() end
end

-- Follow Blizzard's Edit Mode: entering shows the boxes, leaving locks them.
local function HookEditMode()
  local em = EditModeManagerFrame
  if not em or not em.HookScript then return end
  em:HookScript("OnShow", function() ns.SetUnlocked(true) end)
  em:HookScript("OnHide", function() ns.SetUnlocked(false) end)
end

ns.Hook("login", HookEditMode)
