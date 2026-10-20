-- ui/DamageTrail.lua: the hit flash. Each hit leaves a red chunk on the health bar where
-- the health was, which at once starts shrinking toward the bar's middle line and fading
-- out. On both main health bars, the target of target and your pet. Setting: "trail".

local ADDON, ns = ...

local TRAIL = 1.0      -- seconds a chunk takes to shrink and fade away
local MAX_GHOSTS = 6   -- chunks per bar at once; a seventh hit reuses the oldest

-- Each trail's state lives on s: the group itself for its health bar, or the slim bar
-- for the target of target and the pet. s.ghosts is its pool of chunks.
ns.Hook("create", function(f)
  f.ghosts, f.ghostsLive = {}, 0
  for _, slim in ipairs({ f.tot or false, f.pet or false }) do
    if slim then slim.ghosts, slim.ghostsLive = {}, 0 end
  end
end)

local function Ghost(s, bar, i)
  local g = s.ghosts[i]
  if not g then
    g = bar:CreateTexture(nil, "BORDER")  -- under the fill's sheen, over the empty part
    g:SetColorTexture(1, 0.25, 0.2, 1)
    g:Hide()
    s.ghosts[i] = g
  end
  return g
end

local function ClearGhosts(s)
  for _, g in ipairs(s.ghosts) do g.at = nil; ns.Vis(g, false) end
  s.ghostsLive = 0
end

-- hp and max as of the last redraw; a drop since the last frame is a hit.
local function Trail(s, bar, enabled, hp, max, guid, alive)
  max = max or 0
  if not enabled or max <= 0 or not alive then
    if s.ghostsLive > 0 then ClearGhosts(s) end
    s.trailFrac = nil
    return
  end
  local frac = math.min(hp / max, 1)
  if s.trailGuid ~= guid then  -- a new unit starts clean
    ClearGhosts(s)
    s.trailGuid, s.trailFrac = guid, frac
  end
  local t = GetTime()
  -- A hit: a new chunk from the new health to where it was.
  if s.trailFrac and frac < s.trailFrac - 0.001 then
    local slot
    for i = 1, MAX_GHOSTS do
      local g = Ghost(s, bar, i)
      if not g.at then slot = g; break end
    end
    slot = slot or s.ghosts[1]  -- all busy: reuse the oldest
    if not slot.at then s.ghostsLive = s.ghostsLive + 1 end
    slot.at, slot.from, slot.to = t, frac, s.trailFrac
  end
  s.trailFrac = frac
  if s.ghostsLive == 0 then return end
  local w, bh = bar.w or bar:GetWidth(), bar.hgt or bar:GetHeight()
  for _, g in ipairs(s.ghosts) do
    if g.at then
      local k = 1 - (t - g.at) / TRAIL
      if k <= 0 then
        g.at = nil
        s.ghostsLive = s.ghostsLive - 1
        ns.Vis(g, false)
      else
        local x1, x2 = w * g.from, w * g.to
        if bar.reversed then x1, x2 = w - x2, w - x1 end
        g:ClearAllPoints()
        g:SetPoint("LEFT", bar, "LEFT", x1, 0)
        g:SetPoint("RIGHT", bar, "LEFT", x2, 0)
        g:SetHeight(math.max(bh * k, 1))
        ns.Alpha(g, 0.75 * k)
        ns.Vis(g, true)
      end
    end
  end
end

ns.EveryFrame("alerts", function(f)
  local enabled = ns.On(f, "trail")
  Trail(f, f.bars.health, enabled, f.hp, f.hpMax, f.guid, f.exists and not f.dead)
  local slim = f.tot or f.pet
  if slim then
    Trail(slim, slim, enabled, slim.hp, slim.hpMax, slim.guid, slim.exists and not slim.dead)
  end
end)
