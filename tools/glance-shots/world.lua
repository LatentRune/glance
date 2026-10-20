-- The game world a scenario describes: who you are, what you're targeting, auras,
-- threat, quests. The game's API functions below answer from it.

NOW = 1000
function GetTime() return NOW end
-- Real time spent in Lua here, so the debug panel has something to show.
function debugprofilestop() return os.clock() * 1000 end
-- compare.py needs the same output on every run: a fake clock for timings, a fixed seed.
if DETERMINISTIC then
  local ms = 0
  function debugprofilestop() ms = ms + 0.01; return ms end
  math.randomseed(42)
end
function time() return 1700000000 + math.floor(NOW) end

WORLD = {
  units = {},          -- "player", "target", "targettarget", "pet" -> unit table
  combat = false,
  threat = nil,        -- { tanking, status, pct } for you on your target
  quests = {},         -- { title, level, id, text, description, objectives = { {text, type, finished} } }
  bags = { shards = 0, ammo = 0 },
}

-- A unit: name, guid, class (token), level, classification, hp, hpMax, powerType
-- (0 mana, 1 rage, 3 energy), power, powerMax, mana, manaMax, reaction (1-8), player,
-- pvp, dead, tapped, casting = { name, icon, started, ends, shielded }, auras = { ... }.
-- Aura: { name, icon, count, duration, left, mine, help }.
local function U(unit)
  if type(unit) ~= "string" then return end
  return WORLD.units[unit]
end
WORLD.U = U

local POWER_TOKENS = { [0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY", [4] = "COMBO_POINTS" }
MANA, RAGE, ENERGY, FOCUS = "Mana", "Rage", "Energy", "Focus"
COMBO_POINTS = "Combo Points"
PowerBarColor = {
  MANA = { r = 0, g = 0, b = 1 }, RAGE = { r = 1, g = 0, b = 0 }, FOCUS = { r = 1, g = 0.5, b = 0.25 },
  ENERGY = { r = 1, g = 1, b = 0 }, [0] = { r = 0, g = 0, b = 1 }, [1] = { r = 1, g = 0, b = 0 },
  [3] = { r = 1, g = 1, b = 0 },
}
RAID_CLASS_COLORS = {
  WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 },
  ROGUE = { r = 1, g = 0.96, b = 0.41 }, DRUID = { r = 1, g = 0.49, b = 0.04 },
  HUNTER = { r = 0.67, g = 0.83, b = 0.45 }, SHAMAN = { r = 0, g = 0.44, b = 0.87 },
  PRIEST = { r = 1, g = 1, b = 1 }, WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
  PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
}
FACTION_BAR_COLORS = {
  [1] = { r = 0.8, g = 0.3, b = 0.22 }, [2] = { r = 0.8, g = 0.3, b = 0.22 }, [3] = { r = 0.75, g = 0.27, b = 0 },
  [4] = { r = 0.9, g = 0.7, b = 0 }, [5] = { r = 0, g = 0.6, b = 0.1 }, [6] = { r = 0, g = 0.6, b = 0.1 },
  [7] = { r = 0, g = 0.6, b = 0.1 }, [8] = { r = 0, g = 0.6, b = 0.1 },
}
local CLASS_NAMES = { WARRIOR = "Warrior", MAGE = "Mage", ROGUE = "Rogue", DRUID = "Druid", HUNTER = "Hunter",
  SHAMAN = "Shaman", PRIEST = "Priest", WARLOCK = "Warlock", PALADIN = "Paladin" }

function UnitExists(u) return U(u) ~= nil end
function UnitGUID(u) local x = U(u); return x and x.guid end
function UnitName(u) local x = U(u); return x and x.name end
function UnitClass(u) local x = U(u); if x then return CLASS_NAMES[x.class or "WARRIOR"], x.class or "WARRIOR" end end
function UnitLevel(u) local x = U(u); return x and x.level or 0 end
function UnitClassification(u) local x = U(u); return x and x.classification or "normal" end
function UnitHealth(u) local x = U(u); return x and (x.dead and 0 or x.hp) or 0 end
function UnitHealthMax(u) local x = U(u); return x and x.hpMax or 0 end
function UnitPowerType(u)
  local x = U(u); local t = x and x.powerType or 0
  return t, POWER_TOKENS[t]
end
function UnitPower(u, t)
  local x = U(u); if not x then return 0 end
  if t == 4 then return 0 end
  if t == 0 and x.powerType ~= 0 then return x.mana or 0 end
  return x.power or 0
end
function UnitPowerMax(u, t)
  local x = U(u); if not x then return 0 end
  if t == 4 then return 0 end
  if t == 0 and x.powerType ~= 0 then return x.manaMax or 0 end
  return x.powerMax or 0
end
function UnitReaction(u) local x = U(u); return x and (x.reaction or 2) end
function UnitIsPlayer(u) local x = U(u); return x and x.player or false end
function UnitIsPVP(u) local x = U(u); return x and x.pvp or false end
function UnitIsPVPFreeForAll() return false end
function UnitIsFriend(a, b) local x = U(b) or U(a); return x ~= nil and (x.reaction or 2) >= 5 end
function UnitCanAttack(a, b) local x = U(b); return x ~= nil and (x.reaction or 2) <= 4 end
function UnitIsDeadOrGhost(u) local x = U(u); return x and x.dead or false end
function UnitIsDead(u) return UnitIsDeadOrGhost(u) end
function UnitIsTapDenied(u) local x = U(u); return x and x.tapped or false end
function UnitAffectingCombat(u) if u == "player" then return WORLD.combat end local x = U(u); return x and x.combat or false end
function UnitIsUnit(a, b)
  local x, y = U(a), U(b)
  return x ~= nil and x == y or (x and y and x.guid == y.guid) or false
end
function UnitCreatureType(u) local x = U(u); return x and x.creatureType or "Beast" end
function UnitCreatureFamily(u) local x = U(u); return x and x.family end
function UnitFactionGroup(u) local x = U(u); return x and x.faction end
function UnitInParty() return false end
function UnitInRaid() return false end
function UnitInRange() return true end
function UnitOnTaxi() return false end
function UnitAttackSpeed() return WORLD.swingSpeed or 2.0 end
function UnitRangedDamage() return 2.8 end
function InCombatLockdown() return WORLD.lockdown or false end
function IsInGroup() return false end
function IsInRaid() return false end
function GetNumPartyMembers() return 0 end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end

function UnitDetailedThreatSituation(me, u)
  local mine = WORLD.threatOf and WORLD.threatOf[me]  -- a groupmate's threat, by unit
  if mine and u == "target" then return false, mine.status or 1, mine.pct, mine.pct, 0 end
  if me ~= "player" and WORLD.threatOf then return end
  local t = WORLD.threat
  if not t or u ~= "target" then return end
  return t.tanking, t.status, t.pct, t.pct, 0
end
function UnitThreatSituation(me, u)
  local t = WORLD.threat
  if t and u == "target" then return t.status end
end

function UnitCastingInfo(u)
  local x = U(u); local c = x and x.casting
  if not c or c.channel then return end
  return c.name, c.name, c.icon or 136197, c.started * 1000, c.ends * 1000, false, "cast1", c.shielded or false, c.spellID or 0
end
function UnitChannelInfo(u)
  local x = U(u); local c = x and x.casting
  if not c or not c.channel then return end
  return c.name, c.name, c.icon or 136197, c.started * 1000, c.ends * 1000, false, c.shielded or false, c.spellID or 0
end

-- Auras: filter "HARMFUL" / "HELPFUL", with "PLAYER" for yours only.
local function auraList(u, filter)
  local x = U(u)
  local out = {}
  if not x then return out end
  local wantHelp = filter and filter:find("HELPFUL")
  local mineOnly = filter and filter:find("PLAYER")
  for _, a in ipairs(x.auras or {}) do
    if (a.help and wantHelp or not a.help and not wantHelp) and (not mineOnly or a.mine) then out[#out + 1] = a end
  end
  return out
end
function UnitAura(u, i, filter)
  local a = auraList(u, filter)[i]
  if not a then return end
  local expires = a.left and (NOW + a.left) or 0
  return a.name, a.icon, a.count or 0, nil, a.duration or 0, expires, a.mine and "player" or nil
end
UnitDebuff = function(u, i, f) return UnitAura(u, i, "HARMFUL" .. (f and ("|" .. f) or "")) end
UnitBuff = function(u, i, f) return UnitAura(u, i, "HELPFUL" .. (f and ("|" .. f) or "")) end
AURA_TEXT = {}

function GetComboPoints() local x = U("player"); return x and x.combo or 0 end
function GetRaidTargetIndex(u) local x = U(u); return x and x.mark end
function SetRaidTarget() end
function SetRaidTargetIconTexture(t, i) t._raid = i; t._path = nil; t._color = nil end
function GetQuestDifficultyColor(level)
  local me = UnitLevel("player")
  local d = level - me
  if d >= 5 then return { r = 1, g = 0.1, b = 0.1 } end
  if d >= 3 then return { r = 1, g = 0.5, b = 0.25 } end
  if d >= -2 then return { r = 1, g = 1, b = 0 } end
  if d >= -7 then return { r = 0.25, g = 0.75, b = 0.25 } end
  return { r = 0.5, g = 0.5, b = 0.5 }
end

-- Spells and items.
SPELLS = SPELLS or {}
function GetSpellInfo(id)
  local s = SPELLS[id]
  if s then return s.name, nil, s.icon, s.cast or 0, 0, 40, id end
  if type(id) == "string" then return id, nil, 136197, 0, 0, 40, 0 end
end
function IsPlayerSpell(id) return SPELLS[id] ~= nil end
function IsSpellKnown(id) return SPELLS[id] ~= nil end
function GetSpellCooldown() return 0, 0, 1 end
function IsSpellInRange() return WORLD.outOfRange and 0 or 1 end
function CheckInteractDistance() return not WORLD.outOfRange end
C_Spell = { IsSpellInRange = function() return not WORLD.outOfRange end }
function GetSpellPowerCost(id) local s = SPELLS[id]; if s and s.cost then return { { type = 0, cost = s.cost } } end return {} end
function GetItemCount(id) if id == 6265 then return WORLD.bags.shards end return 0 end
function GetItemInfo(id) return "Item " .. tostring(id) end
function GetItemIcon() return 134400 end
function GetItemCooldown() return 0, 0, 1 end
function GetInventoryItemID(u, slot) if slot == 0 and WORLD.bags.ammo > 0 then return 2512 end end
function GetInventoryItemCount() return WORLD.bags.ammo end
function GetPetHappiness() return 3 end
-- Durability per equipped slot: WORLD.gear[slot] = { current, max }; unlisted slots are like new.
function GetInventoryItemDurability(slot)
  local d = WORLD.gear and WORLD.gear[slot]
  if d then return d[1], d[2] end
  return 50, 50
end
C_Container = {
  GetContainerNumSlots = function(b) return b == 4 and (WORLD.bags.soulBag or 0) or 16 end,
  GetContainerNumFreeSlots = function(b) if b == 4 and WORLD.bags.soulBag then return 0, 4 end return WORLD.bags.full and 0 or 4, 0 end,
  GetContainerItemID = function() end,
  GetItemCooldown = function() return 0, 0, 1 end,
}
bit = bit or { band = function(a, b)
  local r, p = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then r = r + p end
    a, b, p = math.floor(a / 2), math.floor(b / 2), p * 2
  end
  return r
end }

-- Quests, the old (Classic) way.
function GetNumQuestLogEntries() return #WORLD.quests end
function GetQuestLogTitle(i)
  local q = WORLD.quests[i]
  if q then return q.title, q.level, nil, false, false, false, nil, q.id end
end
function GetNumQuestLeaderBoards(i) local q = WORLD.quests[i]; return q and #q.objectives or 0 end
function GetQuestLogLeaderBoard(j, i)
  local o = WORLD.quests[i] and WORLD.quests[i].objectives[j]
  if o then return o.text, o.type, o.finished end
end
local selected = 0
function GetQuestLogSelection() return selected end
function SelectQuestLogEntry(i) selected = i end
function GetQuestLogQuestText(i)
  local q = WORLD.quests[i or selected]
  if q then return q.description or "", q.text or "" end
end

-- Stealth: WORLD.stealthed. Totems: WORLD.totems[slot] = { name, start, duration, icon }.
function IsStealthed() return WORLD.stealthed or false end
function GetTotemInfo(slot)
  local t = WORLD.totems and WORLD.totems[slot]
  if not t then return false, "", 0, 0, nil end
  return true, t.name, t.start, t.duration, t.icon
end

-- Resting (an inn or a city): WORLD.resting.
function IsResting() return WORLD.resting or false end
function GetMaxPlayerLevel() return 60 end

-- Loot.
function CanLootUnit(guid) return WORLD.loot and WORLD.loot[guid] or false end
function GetNumLootItems() return 0 end

-- The combat log: Log(sub, src, dst, ...) sends one line to everyone listening.
local line = {}
function CombatLogGetCurrentEventInfo() return table.unpack(line, 1, line.n) end
function Log(...)
  line = table.pack(...)
  FireEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
-- A mob swinging at you (or anyone).
function MeleeHit(src, dst, amount)
  Log(NOW, "SWING_DAMAGE", false, src, "Mob", 0xa48, 0, dst, "You", 0x511, 0, amount or 10, 0, 1, 0, 0, 0, false)
end

-- Misc.
C_Timer = { After = function(t, fn) fn() end, NewTicker = function() return { Cancel = function() end } end }
function strsplit(sep, s)
  local t = {}
  for p in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do t[#t + 1] = p end
  return table.unpack(t)
end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
tinsert, tremove = table.insert, table.remove
function GetAddOnMemoryUsage() return 400 end
function UpdateAddOnMemoryUsage() end
function SendChatMessage() end
function ReloadUI() end
function ToggleDropDownMenu() end
SlashCmdList = {}
PlayerFrame = CreateFrame("Frame", "PlayerFrame", UIParent)
TargetFrame = CreateFrame("Frame", "TargetFrame", UIParent)
PlayerFrame:Hide(); TargetFrame:Hide()
