PlayerInventoryPanel = class(Panel)

function PlayerInventoryPanel:constructor(x, y, w, h, containers)
    Panel.constructor(self, x, y, w, h)
    self.containers = containers
end

function PlayerInventoryPanel:draw()
    -- Запрашиваем обновление рендер-таргета на каждом кадре
    requestRenderTargetUpdate("inventory")
    
    dxDrawRectangle(self.x, self.y, self.w, self.h, COLORS.panel)
    dxDrawRectangle(self.x, self.y, self.w, 40, COLORS.header)
    dxDrawText("INVENTORY", self.x, self.y, self.x + self.w, self.y + 40, COLORS.text_light, 1, Fonts.main, "center", "center", false, false, false, false, true)
    
    local p = 10
    local headerH = 40
    local contentStartY = self.y + headerH
    local viewableH = self.h - headerH
    
    if isElement(RenderTargets.inventory) then
        dxDrawImageSection(self.x + p, contentStartY, self.w - (p*2), viewableH, 0, Scroll.inventory, self.w - (p*2), viewableH, RenderTargets.inventory)
    end
    
    local totalContentH = 0
    for _, container in ipairs(self.containers) do
        totalContentH = totalContentH + calculateSectionHeight(container.grid.cols, container.grid.rows, false)
    end
    self:_drawScrollbar(self.x + self.w - 10, contentStartY, viewableH, viewableH, totalContentH, Scroll.inventory)
end

function PlayerInventoryPanel:_drawScrollbar(x, y, trackH, viewableH, contentH, currentScrollY)
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
