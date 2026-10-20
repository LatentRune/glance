-- settings/Help.lua: help mode. Hover any part of the bars to learn what it shows. On
-- after install; the "?" under your level turns it off, and /glance help turns it back
-- on. It only watches the mouse, so clicks still target as usual.
--
-- Adding a part: add a line to TOPICS ({ widget key, title, text }) for the group it's
-- on. The key is a field on the group (f.cast), one of its bars (health, power...), or
-- one of the names Element() knows.

local ADDON, ns = ...

local TOPICS = {
  player = {
    { "minimalButton", "Minimal mode", "Slim bars with no backgrounds and almost no text: only the target's name stays. Click to switch; /glance minimal does the same." },
    { "help", "Help mode", "Hover any part of the bars to see what it shows. Click this ? to turn help off; /glance help brings it back." },
    { "resting", "Resting", "You're in an inn or a city, earning rested experience." },
    { "level", "Your level", "Crossed swords take its place while you're in combat, shrinking in and flashing red as the fight starts and shattering when it ends, and a dark track runs down the middle between your bars and the target's for the threat flame to climb." },
    { "health", "Your health", "Class color; your name turns green while you're flagged for PvP. Each hit leaves a red chunk where your health was, which shrinks and fades away. Flashes red below 30%. Gold segments along its top, filling from the middle outward, are the combo points an enemy rogue or cat druid has built on you. Shift/Ctrl/Alt-click to target yourself (a plain click works while your bars rest faded), right-click for your menu." },
    { "power", "Power", "Energy, rage or mana. A spark marks the next energy tick, or for mana the five-second rule and then regen ticks. While you cast, the pale strip at the end of the fill is the mana that cast will spend. Frostbolt x12 at the bar's left end means your mana covers 12 more of your last spell." },
    { "mana", "Mana", "Your mana while shapeshifted. While you cast, the pale strip at the end of the fill is the mana that cast will spend. Frostbolt x12 at the bar's left end means your mana covers 12 more of your last spell." },
    { "ammo", "Ammo or soul shards", "How many you carry against what your quiver, ammo pouch or soul bags hold." },
    { "swing", "Swing timer", "Time to your next melee swing (white) or ranged shot (green)." },
    { "debuffs", "Buffs and debuffs on you", "Debuffs from the right, newest at the edge. From the left, one of your long buffs with a blue edge (the one running out soonest, +N for how many more): hover it to see them all. Then your short buffs (procs, Slice and Dice, trinkets) with a green edge. After them, your crowd control on mobs (purple edge) and your totems (teal) with their timers; one that breaks or ends flashes red for 3 seconds. A paladin's aura or a hunter's aspect always takes the long-buff slot. A dark sweep with a bright hand goes around each timed icon over its whole duration, darkening the time already gone. A gold-edged bag means kills of yours still have loot. A blue-edged one counts down your breath underwater and flashes faster as it runs out (red while drowning). Flashing warnings: an eye when a mob spots you in stealth, a taunt icon when a groupmate nears pulling aggro off you (tanks), and a heal icon while the last player you healed is under half health. An anvil means worn or broken gear, an orange-edged bag full bags, and a skull how you died (hover it for the last 10 seconds of damage). Right-click the loot, gear, bag or skull icon to hide it. Real debuffs have a red edge. New icons shrink into place as they fade in, and ones that end break apart. Hover an icon for its tooltip." },
    { "alerts", "Alerts", "A potion or healthstone when you're low, buffs you usually keep up that dropped (right-click one to dismiss it), +N INCOMING for mobs heading your way, and hunter ammo and range warnings." },
    { "cast", "Your cast", "In its own lane under your bars: the spell and the seconds left. The lane stays put through a fight, so nothing below it jumps when you cast." },
    { "aggroBadge", "Mobs on you", "Counts the mobs on you or your pet once there are 2 or more, in the middle under the threat flame. Flashes above 2." },
    { "pet", "Your pet", "Above the inner end of your bars: health, with its debuffs above. Hits on it flash red like on your own bar." },
  },
  target = {
    { "level", "Target level", "Beside the bars' outer end, colored by difficulty. + means elite, ?? means far above you." },
    { "tag", "Classification", "Above the bars' outer end: ELITE, RARE, BOSS, the enemy faction, or your own faction in green for a player on your side, and PVP when it's flagged. Corner brackets around the bars take the color of the first. RUNNER flashes above everything else, over the bars' outer end, when the mob is about to flee." },
    { "health", "Target health", "Class color, gray when someone else tagged it; the panel's edge shows friend or foe. The name is green for a friend flagged for PvP and red for a flagged foe. Green and pale strips are damage already on its way: your DoTs and the spell you're casting. DOTS KILL or KILL means that's enough; xN is how many more of your usual attack it takes. For warriors and paladins, a gold tick marks 20% and orange corner brackets pulse once it's below, in Execute or Hammer of Wrath range. Each hit leaves a red chunk where its health was, which shrinks and fades away." },
    { "power", "Target power" },
    { "combo", "Combo points", "Yours on this target, one segment per point along the top of its health." },
    { "threat", "Threat", "The flame in the middle between your bars and the target's: it climbs the whole dark track and heats up with your share of threat on this mob, with the number beside it when there's room. Flashes red for two seconds when you pull aggro." },
    { "pace", "Kill pace", "Above the bars' outer end: time in this fight against your usual time for this kind of mob (~12s before the fight starts)." },
    { "cast", "Target's cast", "In its own lane under the target's bars, kept while you fight a hostile target so its debuffs never jump. Glows blue only when the cast can be interrupted." },
    { "debuffs", "Your debuffs on it", "Red-edged, from the left, with a dark sweep for the time gone; they pulse when about to run out. On the right, dimmed, are casts this kind of mob has used before: blue-edged if they can be interrupted, gray if not. The one it's casting lights up." },
    { "quest", "Quest progress", "Kills and items this mob counts for, with drop rates learned from your own kills. Hover one for its quest." },
    { "tot", "Target of target", "Who your target is attacking, above the target's inner end. When it's you it says YOU in red, blinking for a few seconds as it turns to you. Hits on it flash red like on the main bars." },
    { "marks", "Raid marks", "Beside the target's debuffs. Click the skull to mark the target with it; hover it for all eight. Shows the target's mark when it has another." },
  },
}

-- The widget each topic points at.
local function Element(f, key)
  if key == "help" then return f.helpButton end
  if key == "level" then return f.level end
  if key == "tag" then return f.classFrame and f.classFrame:IsShown() and f.classFrame.tag end
  if key == "marks" then return f.markBtns end
  if key == "threat" then return f.threatMeter end
  if f.bars[key] then return f.bars[key] end
  return f[key]
end

local showing  -- the topic in the tooltip, if it's ours

local function Over(el)
  if not el or not el.IsVisible or not el:IsVisible() then return false end
  if el.IsMouseOver then
    local ok, over = pcall(el.IsMouseOver, el)
    return ok and over
  end
  return MouseIsOver and MouseIsOver(el)
end

-- The first topic under the mouse, in the order listed.
local function Find()
  for unit, topics in pairs(TOPICS) do
    local f = ns.groups[unit]
    if f and f:IsVisible() then
      for _, t in ipairs(topics) do
        if Over(Element(f, t[1])) then return t end
      end
    end
  end
end

-- Looks at the mouse ten times a second while help is on.
local watcher = CreateFrame("Frame")
local wait = 0
watcher:SetScript("OnUpdate", function(_, dt)
  wait = wait - dt
  if wait > 0 then return end
  wait = 0.1
  -- Leave the tooltip alone while something else (a debuff, an item) owns it. The game's
  -- own unit tooltip (anchored to UIParent, or to the bars) gives way to help.
  local shown = GameTooltip:IsShown()
  local owner = shown and GameTooltip:GetOwner()
  if owner and owner ~= UIParent and owner ~= ns.groups.player and owner ~= ns.groups.target then
    showing = nil
    return
  end
  -- Something replaced or hid our text since: show it again.
  local first = _G.GameTooltipTextLeft1
  if showing and (not shown or (first and first:GetText() ~= showing[2])) then showing = nil end
  local topic = Find()
  if topic == showing then return end
  showing = topic
  if not topic then GameTooltip:Hide(); return end
  GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
  GameTooltip:SetText(topic[2], 1, 0.82, 0)
  if topic[3] then GameTooltip:AddLine(topic[3], 1, 1, 1, true) end
  GameTooltip:Show()
end)
watcher:Hide()

local function SetHelp(on)
  ns.db.help = on
  local f = ns.groups.player
  if f and f.helpButton then f.helpButton:SetShown(on) end
  if ns.PlaceMinimalButton then ns.PlaceMinimalButton(f) end  -- it moves up when the ? hides
  watcher:SetShown(on)
  if not on and showing then showing = nil; GameTooltip:Hide() end
end

---Switch help mode; returns whether it's now on (/glance help).
function ns.ToggleHelp()
  SetHelp(not ns.db.help)
  return ns.db.help
end

-- The "?" under your level, shown while help is on.
local function MakeButton(f)
  local b = CreateFrame("Button", nil, f)
  b:SetSize(14, 14)
  b:SetPoint("TOPRIGHT", f.bars.health, "BOTTOMLEFT", -4, -3)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.8)
  local q = b:CreateFontString(nil, "OVERLAY")
  q:SetFont(ns.FONT, 11, "OUTLINE")
  q:SetPoint("CENTER", 0, 0)
  q:SetText("?")
  q:SetTextColor(0.4, 0.8, 1)
  b:SetScript("OnClick", function()
    SetHelp(false)
    ns.Say("help off. Type /glance help to turn it back on.")
  end)
  f.helpButton = b
end

ns.Hook("login", function()
  if ns.db.help == nil then ns.db.help = true end  -- on for a fresh install
  if ns.groups.player then MakeButton(ns.groups.player) end
  SetHelp(ns.db.help)
end)
