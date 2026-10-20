-- ui/LowHealthFlash.lua: a red pulse over your health bar while it's below 30%.
-- Setting: "lowflash".

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit ~= "player" then return end
  local hb = f.bars.health
  hb.flash = hb:CreateTexture(nil, "OVERLAY", nil, -3)
  hb.flash:SetAllPoints()
  hb.flash:SetColorTexture(1, 0, 0, 1)
  hb.flash:SetAlpha(0)
end)

ns.EveryFrame("timers", function(f)
  if f.unit ~= "player" then return end
  local hb, max = f.bars.health, f.hpMax or 0  -- health as of the last redraw
  if ns.On(f, "lowflash") and max > 0 and f.hp / max < 0.3 and not f.dead then
    ns.Alpha(hb.flash, 0.55 * math.abs(math.sin(GetTime() * 4)))
  else
    ns.Alpha(hb.flash, 0)
  end
end)
