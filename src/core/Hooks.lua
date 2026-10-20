-- core/Hooks.lua: how the parts of Glance plug in, without one file wrapping another.
--
-- Three kinds of plug:
--
--   ns.Hook(stage, fn)          run fn at a stage of a group's life (see STAGES below)
--   ns.Listen(name, events, fn) run fn when the game sends one of these events
--   ns.EveryFrame(name, fn)     run fn every frame for each group that's on screen
--
-- Everything runs in the order it was added, which is the order of the files in
-- Glance.toc. That order is deliberate: ui/ files are listed in the order their parts
-- are built and stacked, so moving a line in the .toc can change what draws over what.

local ADDON, ns = ...

------------------------------------------------------------------------------
-- Stages
------------------------------------------------------------------------------

-- What each stage is given and when it runs:
--   login     ()          once, after settings are loaded; ui/Group.lua makes the groups here
--   create    (f, mirrored) a group was just made; make your widgets on it. mirrored is
--                         true for the target's group, which reads right to left
--   geometry  (f)         sizes or settings changed; size and place your widgets. Out of
--                         combat, or in combat for what isn't protected
--   redraw    (f)         5 to 10 times a second while the unit exists; read the game and
--                         update what you show
--   preview   (f)         instead of redraw while the bars are unlocked and nothing is
--                         targeted; show a sample so the bars can be placed
--   frame     (dt)        every frame, once (not per group), from the heartbeat
--   minimal   (on)        minimal mode was switched on or off
local hooks = {}

---Add fn to a stage. Hooks run in the order they were added.
---@param stage "login"|"create"|"geometry"|"redraw"|"preview"|"frame"|"minimal"
---@param fn function
function ns.Hook(stage, fn)
  local list = hooks[stage]
  if not list then list = {}; hooks[stage] = list end
  list[#list + 1] = fn
end

---Run every hook of a stage, in order.
function ns.RunHooks(stage, ...)
  local list = hooks[stage]
  if not list then return end
  for i = 1, #list do list[i](...) end
end

------------------------------------------------------------------------------
-- Event and update frames
------------------------------------------------------------------------------

-- A named frame is one line in /glance cpu and /glance debug, so its cost can be seen.
-- Several parts can share one: what they do adds up under that name. Unnamed frames
-- (name nil) are for cheap listeners not worth a line of their own.
local named = {}

---The frame that handles events (and maybe every-frame updates) under a name, made the
---first time it's asked for. nil makes a new unnamed frame each time.
---@param name string|nil
function ns.HandlerFrame(name)
  if name and named[name] then return named[name] end
  local fr = CreateFrame("Frame")
  fr.listeners = {}  -- event -> functions to call, in order
  fr:SetScript("OnEvent", function(self, event, ...)
    local list = self.listeners[event]
    for i = 1, #list do list[i](event, ...) end
  end)
  if name then named[name] = fr; ns.handlers[name] = fr end
  return fr
end

local function Add(fr, event, fn)
  local list = fr.listeners[event]
  if not list then list = {}; fr.listeners[event] = list end
  list[#list + 1] = fn
end

---Call fn(event, ...) when the game sends any of these events. Events a client doesn't
---have are skipped quietly, so one list can name events from every client.
---@param name string|nil the handler this counts under in /glance cpu, or nil
---@param events string[]
---@param fn fun(event: string, ...)
function ns.Listen(name, events, fn)
  local fr = ns.HandlerFrame(name)
  for _, e in ipairs(events) do
    if not fr.listeners[e] then pcall(fr.RegisterEvent, fr, e) end
    Add(fr, e, fn)
  end
end

---Like ns.Listen, for unit events, but only for these units (where the client can
---filter them; otherwise for every unit, and fn should check).
---@param units string[] one or two units, e.g. { "player", "target" }
function ns.ListenUnits(name, events, units, fn)
  local fr = ns.HandlerFrame(name)
  for _, e in ipairs(events) do
    if not fr.listeners[e] then
      if fr.RegisterUnitEvent then pcall(fr.RegisterUnitEvent, fr, e, units[1], units[2])
      else pcall(fr.RegisterEvent, fr, e) end
    end
    Add(fr, e, fn)
  end
end

-- Every-frame work, per named frame: for each group that's on screen (it exists, or the
-- bars are unlocked), each function in order.
local perFrame = {}

---Call fn(f, dt) every frame for each group on screen, under a handler name. Keep it
---cheap: it runs 60 or more times a second. Read what the last redraw stored on the group
---(f.hp, f.exists...) rather than asking the game.
---@param name string
---@param fn fun(f: table, dt: number)
function ns.EveryFrame(name, fn)
  -- "bars" runs the heartbeat itself (core/Loop.lua); use a "frame" hook there instead.
  assert(name ~= "bars", "ns.EveryFrame: use ns.Hook(\"frame\", fn) for the bars")
  local fr = ns.HandlerFrame(name)
  local list = perFrame[name]
  if not list then
    list = {}
    perFrame[name] = list
    fr:SetScript("OnUpdate", function(_, dt)
      if not ns.db then return end
      for _, f in pairs(ns.groups) do
        if f.exists or f.unlocked then  -- shown, without asking the game every frame
          for i = 1, #list do list[i](f, dt) end
        end
      end
    end)
  end
  list[#list + 1] = fn
end
