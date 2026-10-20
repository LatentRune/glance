-- features/Spotted.lua: while you're stealthed, a mob turning to you (its target becomes
-- you) has spotted you: a flashing warning on your debuff row for 3 seconds. Seen on your
-- target and, with enemy nameplates on, any mob near you. Setting: "detected".

local ADDON, ns = ...

local FLASH = 3
local RED = { 1, 0.15, 0.15, 1 }
local seen = {}          -- mobs already flagged this time in stealth
local spottedAt, spotter

local function Check(unit, target)
  if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then return end
  if not UnitIsUnit(target, "player") then return end
  local guid = UnitGUID(unit)
  if guid and not seen[guid] then
    seen[guid] = true
    spottedAt, spotter = GetTime(), UnitName(unit)
  end
end

ns.AddWarning({
  key = "detected",
  icon = "Interface\\Icons\\Ability_Stealth",
  edge = RED,
  check = function()
    if IsStealthed and IsStealthed() then
      Check("target", "targettarget")
      for i = 1, 40 do Check(ns.PLATES[i], ns.PLATE_TARGETS[i]) end
    elseif next(seen) then
      for k in pairs(seen) do seen[k] = nil end
    end
    if spottedAt and GetTime() - spottedAt < FLASH then return true, 0, "!", nil, true end
  end,
  tip = function(tip)
    tip:SetText("Spotted", 1, 0.3, 0.3)
    tip:AddLine((spotter or "A mob") .. " has turned to you while you're stealthed.", 1, 1, 1, true)
  end,
})
