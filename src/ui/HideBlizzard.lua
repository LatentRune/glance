-- ui/HideBlizzard.lua: tucks Blizzard's own player and target frames away, since Glance
-- replaces them. They're moved into a hidden parent rather than hidden, so nothing that
-- shows them again brings them back. /glance blizzard switches this off (after /reload).

local ADDON, ns = ...

local hider = CreateFrame("Frame", nil, UIParent)
hider:Hide()

---Move Blizzard's player, target and combo point frames into the hidden parent, if
---the setting is on. Waits for combat to end (ui/Group.lua calls it again then).
function ns.HideBlizzard()
  if not ns.db.hideBlizzard or InCombatLockdown() then return end
  for _, fr in ipairs({ PlayerFrame, TargetFrame, ComboFrame, ComboPointPlayerFrame }) do
    if fr then fr:SetParent(hider) end
  end
end

ns.Hook("login", function() ns.HideBlizzard() end)
