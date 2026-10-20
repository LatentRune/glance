-- features/Execute.lua: whether you have an execute (Execute for warriors, Hammer of
-- Wrath for paladins), usable below 20% of the target's health.
-- Drawn by ui/ExecuteZone.lua. Setting: "execute". Events: SPELLS_CHANGED.

local ADDON, ns = ...

local EXECUTE = { WARRIOR = { 5308, 20658, 20660, 20661, 20662 }, PALADIN = { 24275, 24274, 24239 } }  -- every rank
ns.EXECUTE_AT = 0.2  -- share of max health where execute range starts
local canExecute  -- nil until checked; checked again when your spells change

---Whether you know any rank of your class's execute.
function ns.CanExecute()
  if canExecute == nil then
    canExecute = false
    local _, class = UnitClass("player")
    for _, id in ipairs(EXECUTE[class] or {}) do
      if (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id)) then canExecute = true; break end
    end
  end
  return canExecute
end

---Check again next time (you learned or unlearned spells).

ns.Listen("timers", { "SPELLS_CHANGED" }, function() canExecute = nil end)
