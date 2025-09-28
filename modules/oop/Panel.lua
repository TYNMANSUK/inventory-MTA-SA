Panel = class()

function Panel:constructor(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function Panel:draw()
    -- Base draw method, to be overridden by subclasses
end
