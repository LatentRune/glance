-- features/Loot.lua: your kills that still have loot on them, so you don't walk off and
-- leave it. Shown as a gold-edged bag on your debuff row (ui/LootIcon.lua), out of
-- combat only. Setting: "loot".
-- Events: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED, LOOT_OPENED.

local ADDON, ns = ...

local hitByMe = {}    -- mob GUID -> true once you or your pet damaged it
local unlooted = {}   -- your kills: mob GUID -> { died, confirmed (it has loot for you), dismissed }

ns.Listen("alerts", { "COMBAT_LOG_EVENT_UNFILTERED" }, function()
  if not ns.db then return end
  local _, sub0, _, src0, _, _, _, dst0 = CombatLogGetCurrentEventInfo()
  if not ns.Mine(sub0, src0, dst0) then return end
  local info = ns.LogInfo()
  local sub, src, dst = info[2], info[4], info[8]
  if sub == "UNIT_DIED" or sub == "UNIT_DESTROYED" then
    if hitByMe[dst or ""] then hitByMe[dst] = nil; unlooted[dst] = { died = GetTime() } end
    return
  end
  local me, pet = UnitGUID("player"), UnitGUID("pet")
  if (src == me or (pet and src == pet)) and dst and ns.NpcID(dst) and sub:find("_DAMAGE$") then hitByMe[dst] = true end
end)

ns.Listen("alerts", { "PLAYER_REGEN_ENABLED" }, function()
  if not ns.db then return end
  for k in pairs(hitByMe) do hitByMe[k] = nil end  -- anything still listed got away
end)

ns.Listen("alerts", { "LOOT_OPENED" }, function()
  if not ns.db then return end
  -- Whatever corpse you just opened is dealt with, looted clean or not.
  local any
  for slot = 1, (GetNumLootItems and GetNumLootItems() or 0) do
    local src = { GetLootSourceInfo and GetLootSourceInfo(slot) }
    for i = 1, #src, 2 do if src[i] then unlooted[src[i]] = nil; any = true end end
  end
  if not any and UnitGUID("target") then unlooted[UnitGUID("target")] = nil end
end)

---How many of your kills still have loot for you. Forgets kills after 3 minutes.
function ns.LootCount()
  if not CanLootUnit then return 0 end
  local n, t = 0, GetTime()
  for guid, e in pairs(unlooted) do
    if t - e.died > 180 then
      unlooted[guid] = nil
    elseif not e.confirmed and t - e.died > 1 then
      -- Checked just after the kill while you're still close: no loot for you means nothing to remind.
      local hasLoot = CanLootUnit(guid)
      if hasLoot then e.confirmed = true
      elseif t - e.died > 4 then unlooted[guid] = nil end
    end
    if unlooted[guid] and e.confirmed and not e.dismissed then n = n + 1 end
  end
  return n
end

---Right-click on the loot icon: hide it for the corpses there now. Your next kill with
---loot brings it back.
function ns.DismissLoot()
  for _, e in pairs(unlooted) do if e.confirmed then e.dismissed = true end end
end
