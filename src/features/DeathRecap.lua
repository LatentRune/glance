-- features/DeathRecap.lua: how you died. The last 10 seconds of damage you took before
-- dying, shown as a skull on your debuff row until you right-click it or die again.
-- Every hit is kept in a ring of 30 entries that are reused, so this costs nothing as
-- you play. Setting: "recap".
-- Events: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_DEAD.

local ADDON, ns = ...

local RING, WINDOW = 30, 10      -- hits kept; seconds shown
local ring, head = {}, 0          -- { t, src, what, amount, over }
local recap = { n = 0 }           -- copied from the ring when you die
local ENV = { Falling = "Falling", Drowning = "Drowning", Fatigue = "Fatigue", Fire = "Fire", Lava = "Lava", Slime = "Slime" }

local function Record(src, what, amount, over)
  head = head % RING + 1
  local e = ring[head]
  if not e then e = {}; ring[head] = e end
  e.t, e.src, e.what, e.amount, e.over = GetTime(), src, what, amount or 0, (over or 0) > 0
end

local function OnCombatLog()
  local _, sub, _, _, src, _, _, dst = CombatLogGetCurrentEventInfo()
  ns.myGUID = ns.myGUID or UnitGUID("player")
  if dst ~= ns.myGUID or type(sub) ~= "string" or sub:sub(-7) ~= "_DAMAGE" then return end
  local info = ns.LogInfo()
  if sub == "SWING_DAMAGE" then Record(src, "Melee", info[12], info[13])
  elseif sub == "ENVIRONMENTAL_DAMAGE" then Record(nil, ENV[info[12]] or info[12] or "Environment", info[13], info[14])
  elseif sub:find("^SPELL") or sub:find("^RANGE") then Record(src, info[13], info[15], info[16]) end
end

local function OnDeath()
  local t, n = GetTime(), 0
  for i = 0, RING - 1 do  -- oldest first
    local e = ring[(head + i) % RING + 1]
    if e and e.t and t - e.t <= WINDOW then
      n = n + 1
      local r = recap[n] or {}
      recap[n] = r
      r.ago, r.src, r.what, r.amount, r.over = t - e.t, e.src, e.what, e.amount, e.over
    end
  end
  recap.n, recap.shown = n, n > 0
  for _, e in ipairs(ring) do e.t = nil end  -- a new life starts with an empty ring
end

ns.AddWarning({
  key = "recap",
  icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  edge = { 0.85, 0.85, 0.85, 1 },
  check = function() return recap.shown end,
  dismiss = function() recap.shown = false end,
  tip = function(tip)
    tip:SetText("How you died", 1, 0.3, 0.3)
    local total = 0
    for i = 1, recap.n do
      local r = recap[i]
      total = total + r.amount
      local who = r.src and r.src ~= "" and (r.src .. ": " .. (r.what or "?")) or (r.what or "?")
      if r.over then  -- the killing blow, in red
        tip:AddDoubleLine(string.format("-%.1fs  %s", r.ago, who), r.amount, 1, 0.35, 0.35, 1, 0.35, 0.35)
      else
        tip:AddDoubleLine(string.format("-%.1fs  %s", r.ago, who), r.amount, 0.9, 0.9, 0.9, 1, 0.82, 0)
      end
    end
    tip:AddDoubleLine("Total in the last " .. WINDOW .. " seconds", total, 0.7, 0.7, 0.7, 1, 1, 1)
    tip:AddLine("The killing blow is in red. Right-click to hide this; your next death replaces it.", 0.7, 0.7, 0.7, true)
  end,
})

ns.Listen(nil, { "COMBAT_LOG_EVENT_UNFILTERED" }, function() if ns.db then OnCombatLog() end end)
ns.Listen(nil, { "PLAYER_DEAD" }, function() if ns.db then OnDeath() end end)
