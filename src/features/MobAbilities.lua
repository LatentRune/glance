-- features/MobAbilities.lua: the casts each kind of mob has been seen to use, so you know
-- what's coming before it starts.
--
-- Kept per NPC in GlanceDB.abilities as one short string ("Fireball:135812:1;Frost
-- Nova:135848:0", the last digit 1 when it can be interrupted), at most four casts each,
-- and only read back into a table when you target that kind of mob.
-- Drawn right of the target's debuffs by ui/MobAbilities.lua. Setting: "abilities".

local ADDON, ns = ...

ns.MAX_CASTS = 4
local known = { n = 0 }  -- the current target's casts: { name, icon, ok }, reused

---The casts known for a mob type, as a list of { name, icon, ok } with n entries.
---The same table is reused for every call; don't keep it.
function ns.ReadCasts(npc)
  if known.npc == npc then return known end
  known.npc, known.n = npc, 0
  local s = npc and ns.db.abilities and ns.db.abilities[npc]
  if s then
    for name, icon, ok in s:gmatch("([^:;]+):([^:;]*):(%d)") do
      known.n = known.n + 1
      local e = known[known.n] or {}
      known[known.n] = e
      e.name, e.icon, e.ok = name, tonumber(icon) or icon, ok == "1"
    end
  end
  return known
end

---Remember a cast a hostile mob started (features/Casts.lua calls this).
---@param locked boolean the cast can't be interrupted
function ns.LearnCast(unit, name, icon, locked)
  if UnitIsPlayer(unit) or not UnitCanAttack("player", unit) then return end
  local npc = ns.NpcID(UnitGUID(unit))
  if not npc then return end
  local k = ns.ReadCasts(npc)
  local ok = not locked
  for i = 1, k.n do
    local e = k[i]
    if e.name == name then
      if e.ok == ok then return end
      e.ok = ok
      break
    end
    if i == k.n then
      if k.n >= ns.MAX_CASTS then return end  -- the first four seen are kept
      k.n = k.n + 1
      k[k.n] = k[k.n] or {}
      local e2 = k[k.n]
      e2.name, e2.icon, e2.ok = name, icon, ok
    end
  end
  if k.n == 0 then k.n = 1; k[1] = k[1] or {}; k[1].name, k[1].icon, k[1].ok = name, icon, ok end
  local parts = {}
  for i = 1, k.n do
    local e = k[i]
    parts[i] = e.name:gsub("[:;]", "") .. ":" .. tostring(e.icon or "") .. ":" .. (e.ok and "1" or "0")
  end
  ns.db.abilities = ns.db.abilities or {}
  ns.db.abilities[npc] = table.concat(parts, ";")
end
