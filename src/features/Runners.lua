-- features/Runners.lua: mobs about to run away. Humanoids flee near 20% health; any mob
-- seen running ("... attempts to run away in fear!") is remembered by type in
-- GlanceDB.runners, whatever its creature type.
-- Shown as RUNNER on the target's tag (ui/TargetTag.lua). Setting: "runner".
-- Events: CHAT_MSG_MONSTER_EMOTE.

local ADDON, ns = ...

---Whether a unit is likely to run soon: a runner (humanoid, or seen running) at 30% or less.
function ns.IsRunner(unit)
  if UnitIsPlayer(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then return false end
  local npc = ns.NpcID(UnitGUID(unit))
  local known = npc and ns.db.runners and ns.db.runners[npc]
  if not known and UnitCreatureType(unit) ~= "Humanoid" then return false end
  local max = UnitHealthMax(unit) or 0
  return max > 0 and UnitHealth(unit) / max <= 0.3
end

local function OnEmote(text, sender)
  if not text or not sender then return end
  local lower = text:lower()
  if not (lower:find("run away") or lower:find("flee")) then return end
  for _, unit in ipairs({ "target", "mouseover" }) do
    if UnitExists(unit) and UnitName(unit) == sender then
      local npc = ns.NpcID(UnitGUID(unit))
      if npc then ns.db.runners = ns.db.runners or {}; ns.db.runners[npc] = true end
      return
    end
  end
end

ns.Listen("alerts", { "CHAT_MSG_MONSTER_EMOTE" }, function(_, text, sender)
  if ns.db then OnEmote(text, sender) end
end)
