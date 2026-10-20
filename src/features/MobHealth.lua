-- features/MobHealth.lua: the target's recent health, sampled with each redraw.
--
-- A fight's starting health is still known after the first hit lands, which is what
-- features/KnownDamage.lua needs to learn how much health a mob has on clients that only
-- give percentages.

local ADDON, ns = ...

-- The samples: { t = time, v = fraction of max health }, oldest first, for one GUID.
ns.ttd = { samples = {} }
local ttd = ns.ttd

local function SampleHealth(unit)
  local max = UnitHealthMax(unit) or 0
  if max <= 0 then return end
  local guid, now = UnitGUID(unit), GetTime()
  local frac = (UnitHealth(unit) or 0) / max
  local S = ttd.samples
  if guid ~= ttd.guid or (S[#S] and frac > S[#S].v + 0.05) then
    ttd.guid = guid  -- new target, or a big heal: start over
    for i = #S, 1, -1 do S[i] = nil end
  end
  -- Samples that age out (8 seconds) are reused for new ones, at most five a second.
  local spare
  while S[1] and now - S[1].t > 8 do spare = table.remove(S, 1) end
  if not S[#S] or now - S[#S].t >= 0.2 then
    spare = spare or {}
    spare.t, spare.v = now, frac
    S[#S + 1] = spare
  end
end

ns.Hook("redraw", function(f)
  if f.unit ~= "player" then SampleHealth(f.unit) end
end)
