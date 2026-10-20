-- ui/MobAbilities.lua: casts this kind of mob has been seen to use, dimmed at the right
-- end of the target's debuff row, so you know what's coming before it starts. A blue edge
-- if it can be interrupted, gray if not; the one it's casting now lights up. Learned by
-- features/MobAbilities.lua. Setting: "abilities".

local ADDON, ns = ...

local CAST_OK, CAST_LOCKED = { 0.3, 0.6, 1, 1 }, { 0.45, 0.45, 0.45, 1 }

---The tooltip for a known cast's icon.
function ns.AbilityTip(tip, ic)
  tip:SetText(ic.spell or "", 1, 1, 1)
  tip:AddLine(ic.ok and "Can be interrupted." or "Can't be interrupted.", ic.ok and 0.4 or 0.7, ic.ok and 0.75 or 0.7, ic.ok and 1 or 0.7)
  tip:AddLine("This kind of mob has cast it before. Lights up while it's casting it.", 0.7, 0.7, 0.7, true)
end
ns.iconKinds.ability = { tip = ns.AbilityTip }

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  f.abilityRow = CreateFrame("Frame", nil, f.debuffs)
  f.abilityRow:SetPoint("TOPLEFT"); f.abilityRow:SetPoint("TOPRIGHT")
  f.abilityRow:SetHeight(1)
  f.abilityRow.icons = {}
end)

---Draw the target's known casts in the room left on its debuff row (called by
---ui/DebuffRow.lua). Returns how many are shown.
---@param room integer icons that fit
function ns.UpdateAbilities(f, room)
  local row = f.abilityRow
  local n = 0
  if ns.On(f, "abilities") and f.exists and UnitCanAttack("player", f.unit) and not UnitIsPlayer(f.unit) then
    local k = ns.ReadCasts(ns.NpcID(UnitGUID(f.unit)))
    n = math.min(k.n, room)
    local size = f.debuffs.size or 18
    for i = 1, n do
      local e = k[i]
      local ic = ns.AuraIcon(row, i)
      local x = -(n - i) * (size + 2)
      if ic.placedX ~= x or ic.placedSize ~= size then
        ic.placedX, ic.placedSize = x, size
        ic:SetSize(size, size)
        ic:ClearAllPoints()
        ic:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, 0)
      end
      if ic.icon ~= e.icon then ic.icon = e.icon; ic.tex:SetTexture(e.icon) end
      local edge = e.ok and CAST_OK or CAST_LOCKED
      if ic.edge ~= edge then ic.edge = edge; ic.bg:SetColorTexture(edge[1], edge[2], edge[3], edge[4]) end
      ic.fake, ic.spell, ic.ok = "ability", e.name, e.ok
      if not ic:IsShown() then ic:Show() end
    end
  end
  for i = n + 1, #row.icons do if row.icons[i]:IsShown() then row.icons[i]:Hide() end end
  row.n = n
  return n
end

-- Every frame: the cast it's on now pulses; the rest stay dim.
ns.EveryFrame("timers", function(f)
  local row = f.abilityRow
  if not (row and f.exists) or (row.n or 0) == 0 then return end
  local casting = f.castInfo and f.castInfo.name
  for i = 1, row.n do
    local ic = row.icons[i]
    ns.Alpha(ic, ic.spell == casting and (0.6 + 0.4 * math.abs(math.sin(GetTime() * 8))) or 0.45)
  end
end)
