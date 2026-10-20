-- ui/Interrupt.lua: a bright blue frame pulsing around the target's cast bar while its
-- cast can be interrupted and you have an interrupt ready. From features/Interrupts.lua.
-- Setting: "interrupt".

local ADDON, ns = ...

ns.Hook("create", function(f)
  if f.unit == "player" then return end
  local glow = f.cast:CreateTexture(nil, "BACKGROUND", nil, -7)
  glow:SetPoint("TOPLEFT", -3, 3)
  glow:SetPoint("BOTTOMRIGHT", 3, -3)
  glow:SetColorTexture(0.35, 0.9, 1, 1)
  glow:Hide()
  f.glowOn = false
  f.cast.glow = glow
end)

-- Checked with each redraw; the glow pulses every frame.
ns.Hook("redraw", function(f)
  if f.unit == "player" then return end
  f.interruptOn = ns.On(f, "interrupt") and f.cast.vis and UnitCanAttack("player", f.unit)
    and ns.Interruptible(f.unit) and ns.InterruptReady() and true or false
end)

ns.EveryFrame("alerts", function(f)
  if not f.classFrame then return end  -- the target's group
  local want = f.interruptOn and f.cast.vis or false
  if want then ns.Alpha(f.cast.glow, 0.3 + 0.7 * math.abs(math.sin(GetTime() * 10))) end
  if f.glowOn ~= want then f.glowOn = want; f.cast.glow:SetShown(want) end
end)
