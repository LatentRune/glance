-- features/ManaCost.lua: what your casts cost in mana. Drawn by ui/ManaCost.lua as a
-- pale strip on your mana bar while you cast, and "Frostbolt x12": how many more of your
-- last spell your mana covers. Setting: "manacost".
-- Events: the UNIT_SPELLCAST_* events (yours), SPELLS_CHANGED, PLAYER_LEVEL_UP.

local ADDON, ns = ...

-- The spell ID of your cast in progress, and the last spell you used that costs mana.
ns.mana = { casting = nil, last = nil }
local mana = ns.mana

-- Looked up once per spell: the game builds a fresh table each time it's asked. Cleared
-- when your spells change (a new rank costs more).
local costCache = {}
local function LookUpCost(id)
  local costs
  if C_Spell and C_Spell.GetSpellPowerCost then costs = C_Spell.GetSpellPowerCost(id)
  elseif GetSpellPowerCost then costs = GetSpellPowerCost(id) end
  for _, c in ipairs(costs or {}) do
    if c.type == ns.MANA and (c.cost or 0) > 0 then return c.cost end
  end
  return false
end

---A spell's mana cost, or nil if it costs no mana.
function ns.ManaCost(id)
  if not id then return end
  local c = costCache[id]
  if c == nil then c = LookUpCost(id); costCache[id] = c end
  return c or nil
end

local nameCache = {}
---A spell's name, cached (it's asked for each time the cast count changes).
function ns.CachedSpellName(id)
  local n = nameCache[id]
  if n == nil then
    n = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or (GetSpellInfo and (GetSpellInfo(id))) or false
    nameCache[id] = n
  end
  return n or nil
end

ns.Listen("alerts", { "SPELLS_CHANGED", "PLAYER_LEVEL_UP" }, function()
  if not ns.db then return end
  for k in pairs(costCache) do costCache[k] = nil end
end)

ns.Listen("alerts", { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED",
  "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" },
  function(event, unit, _, spellID)
    if not ns.db or unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
      mana.casting = spellID
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
      if ns.ManaCost(spellID) then mana.last = spellID end
      if mana.casting == spellID then mana.casting = nil end
    else  -- stopped, failed or interrupted
      mana.casting = nil
    end
  end)
