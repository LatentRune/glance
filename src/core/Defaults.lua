-- core/Defaults.lua: the settings Glance starts with, and loading saved settings at login.
--
-- Saved variables (see Glance.toc):
--   GlanceDB      shared by all your characters: sizes, positions, checkboxes, and what's
--                 learned about mobs (drops, health, who runs, which casts they use)
--   GlanceCharDB  this character only: what's learned from your own play (the buffs you
--                 keep up, your spells' damage, how long your kills take)
--
-- Adding a feature with a checkbox: add its key to `labels` below (true = on by default)
-- and a line for it in settings/Panel.lua.

local ADDON, ns = ...

-- Each group has its own size, opacity and position (offsets are from screen CENTER).
-- Adjust them in Edit Mode, or with /glance unlock on clients without it.
local GROUP = { width = 180, healthHeight = 26, powerHeight = 12, fontSize = 11, scale = 1, alpha = 1 }

local DEFAULTS = {
  gap = 1,             -- pixels between stacked bars
  hideBlizzard = true, -- tuck away Blizzard's player and target frames (/glance blizzard)
  deepColors = true,   -- darker, richer bar colors (/glance colors)
  drops = {},          -- learned quest drops per mob type (features/Quests.lua)
  player = { point = "TOPRIGHT", x = -30, y = -90 },
  target = { point = "TOPLEFT",  x =  30, y = -90 },
}
for _, g in ipairs({ DEFAULTS.player, DEFAULTS.target }) do
  for k, v in pairs(GROUP) do g[k] = v end
  -- One checkbox per feature, by key. The same keys exist for both groups; the settings
  -- panel shows each only where it applies.
  g.labels = { health = true, power = false, mana = false, combo = true, enemycombo = true, ammo = true, quests = true, slide = true,
    tick = true, swing = true, pet = true, fade = true, marker = true,
    cast = true, debuffs = true, threat = true, tot = true, range = true, markbtns = true,
    lowflash = true, expireflash = true, preview = true,
    trail = true, adds = true, pace = true, loot = true, breath = true, buffbar = true, addwarn = true, manacost = true, potion = true, buffs = true, hunter = true,
    runner = true, interrupt = true, combat = true, execute = true, abilities = true, gear = true, bags = true, recap = true, clickthrough = true, resting = true, cc = true, totems = true, detected = true, aggrowarn = true, healwatch = true, aurafx = true, enemyfaction = true, pvptag = true }
end
ns.DEFAULTS = DEFAULTS

-- Fill in whatever a saved table is missing from the defaults, keeping what's there.
local function copyDefaults(src, dst)
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = type(dst[k]) == "table" and dst[k] or {}
      copyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

---Load saved settings into ns.db and ns.char, filling in defaults and moving settings
---saved by older versions forward. Called once, at login (core/Loop.lua).
function ns.LoadSettings()
  GlanceDB = GlanceDB or {}
  local db = GlanceDB
  copyDefaults(DEFAULTS, db)
  -- 0.31: taller health bars, unless you've already picked a height yourself.
  if not db.tallHealth then
    db.tallHealth = true
    for _, unit in ipairs({ "player", "target" }) do
      if db[unit].healthHeight == 18 then db[unit].healthHeight = 26 end
    end
  end
  ns.db = db
  -- What's learned from your own play stays with each character: the buffs you keep
  -- up, your spells' damage and how long your kills take. What's learned about mobs
  -- (health, drops, who runs) is shared.
  GlanceCharDB = GlanceCharDB or {}
  ns.char = GlanceCharDB
  if db.buffs or db.combat or db.spells then
    -- Before 0.54 these were shared, mixing every character's. They're relearned per
    -- character as you play.
    db.buffs, db.combat, db.spells = nil, nil, nil
  end
  if not db.wings then
    -- 0.60 (wings): power bars drop their names, and bars still at the old default spot
    -- open a wider spine for threat and the mob count.
    db.wings = true
    for _, key in ipairs({ "player", "target" }) do
      db[key].labels.power, db[key].labels.mana = false, false
      local old = key == "player" and -12 or 12
      if db[key].x == old then db[key].x = DEFAULTS[key].x end
    end
  end
  if db.placed ~= nil then
    -- Before 0.68 a first run copied the spots of Blizzard's own frames (the top left
    -- corner on the default UI). If both groups are still there (point "TOP"), they move
    -- to the middle; once you've dragged either one ("TOPLEFT"), both stay put.
    if db.player.point == "TOP" and db.target.point == "TOP" then
      for _, key in ipairs({ "player", "target" }) do
        db[key].point, db[key].x, db[key].y = DEFAULTS[key].point, DEFAULTS[key].x, DEFAULTS[key].y
      end
    end
    db.placed = nil
  end
end

---Put both groups' sizes, positions and checkboxes back to the defaults (/glance reset).
function ns.ResetGroups()
  local db = ns.db
  db.player, db.target = nil, nil
  copyDefaults(DEFAULTS, db)
end
