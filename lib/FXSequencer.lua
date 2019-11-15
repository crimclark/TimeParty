local FXSequencer = {}
FXSequencer.__index = FXSequencer

local buttonLevels = { BRIGHT = 15, MEDIUM = 4, DIM = 2 }

function FXSequencer.new(options)
  local seq = {
    grid = options.grid,
    modVals = options.modVals,
    set_fx = options.set_fx,
    visible = options.visible or false,
    currentVal = 1,
    lengthOffset = 0,
    rate = 1.0,
    steps = {},
    positionX = 1,
    metro = metro.init(),
    held = {x = 0, y = 0}
  }
  setmetatable(seq, FXSequencer)
  setmetatable(seq, {__index = FXSequencer})
  seq:init_steps()
  seq.metro.event = seq:count()
  return seq
end

function FXSequencer:start()
  self:update_tempo(params:get('bpm'))
  self.metro:start()
end

function FXSequencer:init()
  self:redraw()
  self.grid.key = function(x,y,z)
    if z == 1 then
      if self.held.y == y then
        local first,last = math.min(x, self.held.x), math.max(x, self.held.x)
        for i=first,last do self.steps[i] = y end
      else
        self.steps[x] = y
      end
      self.held = {x = x, y = y}
      self:redraw()
    end
    if z == 0 then self.held = {x = 0, y = 0} end
  end
end

function FXSequencer:update_tempo(bpm)
  self.metro.time = 60 / bpm / self.rate
end

function FXSequencer:update_rate(val)
  self.rate = val
  self:update_tempo(params:get('bpm'))
end

function FXSequencer:set_length_offset(delta)
  self.lengthOffset = util.clamp(self.lengthOffset - delta, 0, self.grid.cols - 1)
end

function FXSequencer:length()
  return self.grid.cols - self.lengthOffset
end

function FXSequencer:count()
  return function()
    self.positionX = (self.positionX % self:length()) + 1
    self:redraw()
  end
end

function FXSequencer:redraw()
  local visible = self.visible

  if visible then self.grid:all(0) end

  for i = 1, self:length() do
    local y = self.steps[i]
    -- count down from bottom row 8 to current height
    for j = self.grid.rows, y, -1 do

      if visible then self.grid:led(i, j, buttonLevels.MEDIUM) end

      if i == self.positionX then
        self.currentVal = self.modVals[y]
        self.set_fx(self.currentVal)

        if visible then self.grid:led(i, j, buttonLevels.BRIGHT) end
      end
    end
  end

  if self.visible then self.grid:refresh() end
end

function FXSequencer:init_steps()
  for i = 1, self.grid.cols do
    table.insert(self.steps, self.grid.rows)
  end
end

return FXSequencer
