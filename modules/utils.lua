-- Utility functions for Inventory System

function calculateSectionHeight(cols, rows)
    local headerH, slotSize, slotGap, sectionPadding = 25, 48, 2, 5
    if not cols or not rows then return 0 end
    local gridH = rows * (slotSize + slotGap) - slotGap
    return headerH + gridH + (sectionPadding * 2) + 10
end

function isCursorInArea(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Helper function to find an element in a table
function table.find(tbl, el)
    for i, val in ipairs(tbl) do
        if val == el then
            return i
        end
    end
    return nil
end

-- Универсальная функция для расчета координат ячейки в любом контейнере
function getScreenCoordinatesForCell(container, col, row)
    local slotSize, slotGap = 48, 2
    
    if container.id == "vicinity" then
        -- Для окружения - простой расчет
        local panel = Panels.vicinity
        local p, headerH = 8, 40
        local gridX = panel.x + p
        local gridY = panel.y + headerH + p - (container.getScroll and container.getScroll() or 0)
        return gridX + (col - 1) * (slotSize + slotGap), gridY + (row - 1) * (slotSize + slotGap)
    else 
        -- Для инвентаря игрока - учитываем рендер-таргет и скролл
        local panel = Panels.player
        local panelPadding = 10
        local sectionPadding = 10 -- This is 'p' from drawContainerSection
        local headerH = 40
        
        -- Проверяем, что контейнер имеет данные рендера
        if not container.render then
            -- Если нет данных рендера, рассчитываем позицию
            local containerStartY = 0
            for _, c in ipairs(panel.containers) do
                if c == container then break end
                containerStartY = containerStartY + calculateSectionHeight(c.grid.cols, c.grid.rows) + 10
            end
            container.render = { x = 0, y = containerStartY, w = panel.w - (panelPadding * 2) }
        end
        
        -- Рассчитываем координаты в рендер-таргете
        local gridX = panel.x + panelPadding + sectionPadding
        local gridY = panel.y + headerH + container.render.y + 40 + sectionPadding - Scroll.inventory
        
        return gridX + (col - 1) * (slotSize + slotGap), gridY + (row - 1) * (slotSize + slotGap)
    end
end
