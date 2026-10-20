-- ui/Slide.lua: where the two groups sit on screen, and the slide between centered and
-- spread out.
--
-- With no target, no fight and nothing coming for you, your bars sit centered on the
-- screen and the target's tuck in under them. A target, combat or a mob targeting you
-- spreads them out to where you placed them. The game won't move click-to-target frames
-- in combat, so they snap apart as combat starts and only come back together once it's
-- over. Setting: "slide" (on your group).

local ADDON, ns = ...

local groups = ns.groups
local spread, spreadGoal = 1, 1  -- 0 centered .. 1 where you placed them

local function Sliding()
  return ns.db.player.labels.slide ~= false and not groups.player.unlocked
end

---Anchor a group where it belongs right now: where you placed it, or part way to the
---middle of the screen while the bars slide.
function ns.PlaceGroup(f)
  local pos = ns.db[f.unit]
  f:ClearAllPoints()
  if not Sliding() then f:SetPoint(pos.point, UIParent, "CENTER", pos.x, pos.y); return end
  local x = pos.x  -- from screen center to the top middle of the bars where you placed them
  if pos.point == "TOPLEFT" then x = x + pos.width / 2 elseif pos.point == "TOPRIGHT" then x = x - pos.width / 2 end
  local e = spread * spread * (3 - 2 * spread)  -- eased: starts and ends gently
  f:SetPoint("TOP", UIParent, "CENTER", x * e, pos.y)
end

-- A hostile nameplate targeting you: something is coming even before combat starts.
local function TargetingMe()
  if not C_NamePlate then return false end
  for i = 1, 40 do
    local u = ns.PLATES[i]
    if UnitExists(u) and UnitCanAttack("player", u) and UnitIsUnit(ns.PLATE_TARGETS[i], "player") then return true end
  end
  return false
end

-- Every frame: the slide takes 0.3 seconds. Whether to spread is looked at five times a
-- second; frames with nothing to do return at once.
local lookAgain = 0
ns.Hook("frame", function(dt)
  if not ns.db or not groups.player then return end
  lookAgain = lookAgain - dt
  if lookAgain > 0 and spread == spreadGoal then return end
  if InCombatLockdown() then return end
  if lookAgain <= 0 then
    lookAgain = 0.2
    spreadGoal = (UnitExists("target") or UnitAffectingCombat("player") or TargetingMe()) and 1 or 0
  end
  if not Sliding() then spread = 1; return end
  if spread == spreadGoal then return end
  local step = dt / 0.3
  spread = spread < spreadGoal and math.min(spreadGoal, spread + step) or math.max(spreadGoal, spread - step)
  for _, f in pairs(groups) do ns.PlaceGroup(f) end
end)

-- Combat starting is the last moment the bars can still move: spread them now.
ns.Listen("bars", { "PLAYER_REGEN_DISABLED" }, function()
  if ns.db and spread ~= 1 then
    spread, spreadGoal = 1, 1
    for _, f in pairs(groups) do ns.PlaceGroup(f) end
  end
end)
