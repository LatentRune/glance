-- ui/Stack.lua: what hangs under each group's bars, stacked top to bottom with 4px
-- between, whatever is showing.
--
--   yours:          swing timer, cast lane, debuffs (and buffs), alerts, debug panel
--   the target's:   cast lane, debuffs (and known casts), quest progress
--
-- The target's raid-mark skull sits beside its debuff row (ui/RaidMarks.lua).
-- A cast lane counts while it's reserved (ui/CastBar.lua), so a cast starting or ending
-- never moves what's below it. Anything that shows or hides something in the stack calls
-- ns.ChainBelow. To add to it, append to f.below in a "create" hook listed after this
-- file in Glance.toc (ui/AlertsRow.lua does).

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit == "player" then f.below = { f.swing, f.cast, f.debuffs }
  else f.below = { f.cast, f.debuffs, f.quest } end
end)

---Restack what hangs under a group's bars. In combat the group may keep its old height
---for a while (f.slack, ui/Group.lua); the stack follows the bars, not the group.
function ns.ChainBelow(f)
  if not f.below then return end
  local y = -4 + (f.slack or 0)
  for _, el in ipairs(f.below) do
    if el == f.debuffs and ns.PlaceMarks then ns.PlaceMarks(f, y) end  -- the target's skull
    if el:IsShown() or el.reserved then
      el:ClearAllPoints()
      el:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, y)
      if not el.halfWidth then el:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, y) end
      y = y - el:GetHeight() - 4
    end
  end
end

-- The preview shows and hides several things at once: restack once they're all done.
ns.Hook("preview", function(f) ns.ChainBelow(f) end)
