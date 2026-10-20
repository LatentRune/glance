-- dev/Debug.lua: /glance debug. What Glance costs, live, in bars under yours: CPU per
-- named frame (ns.handlers), memory and how fast it grows, combat log lines, and the mob
-- count. Each bar is scaled to the highest value of the last 30 seconds, so a spike fills
-- it. Updated once a second; the panel's own upkeep isn't counted. Stays on across
-- /reload until switched off.

local ADDON, ns = ...

local WINDOW = 30         -- seconds of history each bar is scaled against
local ROW_H, GAP = 12, 2

local panel
local rows = {}           -- in display order, and by key
local spent = {}          -- handler name -> milliseconds this second
local originals = {}      -- { frame, script, fn } while timing
local combatLines = 0     -- combat log lines this second
local lastMem

-- Wrap each named frame's scripts so their time adds up per name.
local function StartTiming()
  if not debugprofilestop then return end
  for name, fr in pairs(ns.handlers) do
    spent[name] = 0
    for _, script in ipairs({ "OnUpdate", "OnEvent" }) do
      local fn = fr:GetScript(script)
      if fn then
        originals[#originals + 1] = { fr, script, fn }
        fr:SetScript(script, function(...)
          local t = debugprofilestop()
          fn(...)
          spent[name] = spent[name] + debugprofilestop() - t
        end)
      end
    end
  end
end

local function StopTiming()
  for i = #originals, 1, -1 do
    local o = originals[i]
    o[1]:SetScript(o[2], o[3])
    originals[i] = nil
  end
end

local function Memory()
  if not (UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then return end
  UpdateAddOnMemoryUsage()
  return GetAddOnMemoryUsage(ADDON)
end

-- floor: the least the bar is scaled to, so small numbers don't fill it.
local function NewRow(key, label, unit, floor)
  local b = CreateFrame("StatusBar", nil, panel)
  b:SetStatusBarTexture(ns.TEX)
  b:SetHeight(ROW_H)
  b:SetMinMaxValues(0, 1)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)
  b.label = b:CreateFontString(nil, "OVERLAY")
  b.label:SetFont(ns.FONT, 9, "OUTLINE")
  b.label:SetPoint("LEFT", 3, 0)
  b.label:SetText(label)
  b.value = b:CreateFontString(nil, "OVERLAY")
  b.value:SetFont(ns.FONT, 9, "OUTLINE")
  b.value:SetPoint("RIGHT", -3, 0)
  b.key, b.unit, b.floor, b.history = key, unit, floor, {}
  b.fmt = unit == "ms/s" and "%.2f" or "%.0f"
  b:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(#rows * (ROW_H + GAP)))
  b:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -(#rows * (ROW_H + GAP)))
  rows[#rows + 1] = b
  rows[key] = b
  return b
end

-- Green while low, amber, then red as it nears the top of its recent range.
local function Show(b, v, extra)
  local h = b.history
  h[#h + 1] = v
  if #h > WINDOW then table.remove(h, 1) end
  local peak = b.floor
  for _, x in ipairs(h) do if x > peak then peak = x end end
  b:SetMinMaxValues(0, peak)
  b:SetValue(v)
  local frac = v / peak
  if frac > 0.8 then b:SetStatusBarColor(0.9, 0.25, 0.2)
  elseif frac > 0.5 then b:SetStatusBarColor(0.95, 0.7, 0.2)
  else b:SetStatusBarColor(0.25, 0.7, 0.35) end
  local fmt = b.fmt
  b.value:SetText((fmt .. " %s%s  |cff909090peak " .. fmt .. "|r"):format(v, b.unit, extra or "", peak))
end

-- Once a second.
local function Tick()
  local total = 0
  for name, ms in pairs(spent) do
    total = total + ms
    if rows[name] then Show(rows[name], ms) end
    spent[name] = 0
  end
  Show(rows.total, total, string.format(" (%.2f%%)", total / 10))
  local mem = Memory()
  if mem then
    local change = lastMem and mem - lastMem or 0
    -- A drop is the garbage collector sweeping up, not negative garbage.
    Show(rows.memory, mem, change < 0 and " (swept)" or "")
    Show(rows.garbage, math.max(change, 0))
    lastMem = mem
  end
  Show(rows.combatlog, combatLines)
  Show(rows.aggro, ns.groups.player and ns.groups.player.aggro or 0)
  combatLines = 0
end

local function Build(f)
  panel = CreateFrame("Frame", nil, f)
  local back = panel:CreateTexture(nil, "BACKGROUND", nil, -8)
  back:SetPoint("TOPLEFT", -1, 1)
  back:SetPoint("BOTTOMRIGHT", 1, -1)
  back:SetColorTexture(0, 0, 0, 0.7)
  NewRow("total", "Glance CPU", "ms/s", 2)
  local names = {}
  for name in pairs(ns.handlers) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do NewRow(name, "  " .. name, "ms/s", 1) end
  NewRow("memory", "Memory", "KB", 500)
  NewRow("garbage", "New memory", "KB/s", 10)
  NewRow("combatlog", "Combat log lines", "/s", 20)
  NewRow("aggro", "Mobs on you", "", 3)
  panel:SetHeight(#rows * (ROW_H + GAP) - GAP)
  panel:Hide()
  if f.below then f.below[#f.below + 1] = panel end  -- last under your bars (ui/Stack.lua)

  local wait = 0
  panel:SetScript("OnUpdate", function(_, dt)
    wait = wait + dt
    if wait >= 1 then wait = 0; Tick() end
  end)
  panel:SetScript("OnEvent", function() combatLines = combatLines + 1 end)
end

local function SetDebug(on)
  local f = ns.groups.player
  if not f then return end
  if on and not panel then Build(f) end
  if not panel or on == panel:IsShown() then return end
  if on then
    StartTiming()
    lastMem = Memory()
    pcall(panel.RegisterEvent, panel, "COMBAT_LOG_EVENT_UNFILTERED")
    panel:Show()
  else
    StopTiming()
    panel:UnregisterAllEvents()
    panel:Hide()
  end
  ns.ChainBelow(f)
end

---Switch the debug panel; returns whether it's now on (/glance debug).
function ns.ToggleDebug()
  if ns.profiling then return false end
  ns.db.debug = not (panel and panel:IsShown())
  SetDebug(ns.db.debug)
  return ns.db.debug
end

---Whether the debug panel is showing.
function ns.Debugging() return panel ~= nil and panel:IsShown() end

ns.Hook("login", function()
  if ns.db.debug then SetDebug(true) end
end)
