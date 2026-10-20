-- core/Util.lua: small helpers every other file uses. Nothing here draws or keeps state
-- of its own beyond a cache.

local ADDON, ns = ...

---A value as a whole percent of its maximum (0 when there's no maximum).
---@param cur number
---@param max number|nil
---@return integer
function ns.Pct(cur, max)
  if not max or max <= 0 then return 0 end
  return math.floor(cur / max * 100 + 0.5)
end

-- These three only call into the game when something changed: setting the same text,
-- alpha or visibility again still makes the game redo its layout, and they run many
-- times a second. Don't replace them with plain SetText/SetAlpha/SetShown.

---Set a font string's text, only if it changed.
---@param fs table FontString
---@param s any text, number or nil (shown as empty)
function ns.Text(fs, s)
  s = s == nil and "" or tostring(s)
  if fs:GetText() ~= s then fs:SetText(s) end
end

---Show or hide, remembering which in w.vis, so hot paths can check w.vis instead of
---asking the game. Only for widgets that are only ever shown or hidden through here.
---@return boolean changed true when it was shown and is now hidden, or the other way
function ns.Vis(w, on)
  on = on and true or false
  if w.vis == on then return false end
  w.vis = on
  w:SetShown(on)
  return true
end

---Set alpha (rounded to 0.01), only if it changed. For widgets whose alpha is only ever
---set through here.
function ns.Alpha(w, a)
  a = math.floor(a * 100 + 0.5) / 100
  if w.glanceAlpha ~= a then w.glanceAlpha = a; w:SetAlpha(a) end
end

---Whether minimal mode is on: slim bars, no backgrounds, almost no text.
---@return boolean
function ns.Minimal() return ns.db and ns.db.minimal or false end

-- Deep colors: the same hues, darker and a little more saturated, so the effects drawn
-- over the fills (hit flash, chunks, ember, combo points) have something dark to stand on.
-- Off with /glance colors. Cached per color: bars ask for the same few colors constantly.
local deepCache = {}

---A bar color as deep colors would show it (unchanged when deep colors are off).
---@return number r, number g, number b
function ns.Deep(r, g, b)
  if not (ns.db and ns.db.deepColors) then return r, g, b end
  local key = r * 1e6 + g * 1e3 + b
  local c = deepCache[key]
  if not c then
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local v, s = mx, mx > 0 and (mx - mn) / mx or 0
    local v2, s2 = v * 0.8, s < 0.05 and s or math.min(1, s * 1.35 + 0.05)
    local function ch(x)  -- each channel keeps its place between the min and max
      local t = mx > mn and (x - mn) / (mx - mn) or 1
      return v2 * (1 - s2 * (1 - t))
    end
    c = { ch(r), ch(g), ch(b) }
    deepCache[key] = c
  end
  return c[1], c[2], c[3]
end

---The NPC ID in a creature's GUID ("Creature-0-1-2-3-<npc>-<spawn>"): the same for
---every mob of a kind, which is what learned data (drops, health, casts) is kept by.
---@param guid string|nil
---@return integer|nil npc nil for players, pets and anything that isn't a creature
function ns.NpcID(guid)
  if not guid then return end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

-- Nameplate unit names ("nameplate1".."nameplate40" and what each targets), made once
-- rather than built as strings every time something looks through the nameplates.
ns.PLATES, ns.PLATE_TARGETS = {}, {}
for i = 1, 40 do ns.PLATES[i] = "nameplate" .. i; ns.PLATE_TARGETS[i] = "nameplate" .. i .. "target" end

---Print a line in chat, prefixed with Glance in blue.
function ns.Say(msg) print("|cff66ccffGlance|r " .. msg) end
