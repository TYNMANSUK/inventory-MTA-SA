VicinityPanel = class(Panel)

function VicinityPanel:constructor(x, y, w, h, container)
    Panel.constructor(self, x, y, w, h)
    self.container = container
end

function VicinityPanel:draw()
    dxDrawRectangle(self.x, self.y, self.w, self.h, COLORS.panel)
    dxDrawRectangle(self.x, self.y, self.w, 40, COLORS.header)
    dxDrawText(self.container.label, self.x, self.y, self.x + self.w, self.y + 40, COLORS.text_light, 1, Fonts.main, "center", "center", false, false, true, false, true)
    
    -- Inlined drawContainerContents logic
    local p = 8
    local headerH = 40
    local scrollY = self.container.getScroll and self.container.getScroll() or 0
    local viewableH = self.h - headerH
    local clipRect = { x = self.x, y = self.y + headerH, w = self.w, h = viewableH }

    local gridX = self.x + p
    local gridY = self.y + headerH + p - scrollY

    drawContainerGrid(gridX, gridY, self.container, clipRect)
    
    -- Inlined drawScrollbar logic
    local contentH = self.container.grid.rows * (48 + 2) - 2 + (p * 2)
    self:_drawScrollbar(self.x + self.w - 10, self.y + headerH, viewableH, viewableH, contentH, scrollY)
end

function VicinityPanel:_drawScrollbar(x, y, trackH, viewableH, contentH, currentScrollY)
    if contentH <= viewableH then return end

    local scrollbarW = 5
    local trackColor = tocolor(18, 18, 18, 230)
    local handleColor = tocolor(60, 60, 60, 255)

    dxDrawRectangle(x, y, scrollbarW, trackH, trackColor)

    local handleH = math.max(trackH * (viewableH / contentH), 20)
    local maxScroll = contentH - viewableH
    if maxScroll > 0 then
        local scrollRatio = currentScrollY / maxScroll
        local handleY = y + (trackH - handleH) * scrollRatio
        dxDrawRectangle(x, handleY, scrollbarW, handleH, handleColor)
    end
end
