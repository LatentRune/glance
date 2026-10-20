-- ui/Breath.lua: your breath underwater, as the first icon on your debuff row (put there
-- by ui/DebuffRow.lua): it counts down the seconds of air, and under half it flashes,
-- faster as it runs out; red and fastest while drowning. The timer comes from
-- features/Breath.lua. Setting: "breath".

local ADDON, ns = ...

local BLUE, RED = { 0.3, 0.6, 1, 1 }, { 1, 0.15, 0.15, 1 }

ns.iconKinds.breath = {
  edge = BLUE,
  tip = function(tip)
    local left = ns.Breath()
    if left and left <= 0 then
      tip:SetText("Drowning", 1, 0.3, 0.3)
      tip:AddLine("You're out of breath and taking damage. Get to the surface.", 1, 1, 1, true)
    else
      tip:SetText("Breath", 0.4, 0.75, 1)
      tip:AddLine(string.format("%d seconds of air left.", math.ceil(left or 0)), 1, 1, 1, true)
      tip:AddLine("Flashes once you're under half, faster as it runs out.", 0.7, 0.7, 0.7, true)
    end
  end,
}

ns.EveryFrame("timers", function(f)
  local bi = f.breathIcon
  if f.unit ~= "player" or not (bi and bi.fake == "breath") then return end
  local left, max = ns.Breath()
  if not left then return end
  local frac = max > 0 and left / max or 0
  ns.Text(bi.time, left > 0 and math.ceil(left) or "!")
  local drowning = left <= 0
  if bi.drowning ~= drowning then
    bi.drowning = drowning
    bi.edge = nil  -- set here, not from the kind's edge
    if drowning then bi.time:SetTextColor(1, 0.3, 0.3); bi.bg:SetColorTexture(RED[1], RED[2], RED[3], RED[4])
    else bi.time:SetTextColor(1, 1, 1); bi.bg:SetColorTexture(BLUE[1], BLUE[2], BLUE[3], BLUE[4]) end
  end
  local rate = drowning and 12 or frac < 0.5 and (1.5 + 7 * (0.5 - frac) / 0.5) or 0
  ns.Alpha(bi, rate > 0 and (0.3 + 0.7 * math.abs(math.cos(GetTime() * rate))) or 1)
end)
