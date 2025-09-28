-- Rendering functions for Inventory System

function renderMain()
    if not inventoryOpen then return end
    
    -- Guard against nil value during resource start/restart
    if not InventoryRegistry.vicinity then return end

    -- Update render targets if needed
    if RenderTargets.needsUpdate.inventory and isElement(RenderTargets.inventory) then
        updateInventoryPanelRenderTarget()
        RenderTargets.needsUpdate.inventory = false
    end

    -- Update animations
    if _G.updateAnimations then
        _G.updateAnimations()
    end
    
    -- Update scroll positions
    Scroll.vicinity = Scroll.vicinity + (Scroll.targetVicinity - Scroll.vicinity) * Scroll.speed
    Scroll.inventory = Scroll.inventory + (Scroll.targetInventory - Scroll.inventory) * Scroll.speed

    dxDrawRectangle(0, 0, screenW, screenH, COLORS.background)
    drawEquipmentPanel(startX + panelW + panelGap, startY, panelW, totalH)
    
    -- Draw Panels
    Panels.vicinity:draw()
    Panels.player:draw()
    
    -- Draw particles
    drawParticles()

    if DragDrop.isDragging and DragDrop.dropTarget then
        local target = DragDrop.dropTarget
        local container = target.container
        local itemInfo = Items[DragDrop.item.id]
        
        local slotSize, slotGap = 48, 2
        
        -- Используем простейший подход: нарисуем одни и те же расчеты, как в handlers.lua
        local ghostX, ghostY
        
        if container.id == "vicinity" then
            -- Для окружения
            local panel = Panels.vicinity
            local p, headerH = 8, 40
            local scrollY = container.getScroll and container.getScroll() or 0
            ghostX = panel.x + p + (target.col - 1) * (slotSize + slotGap)
            ghostY = panel.y + headerH + p + (target.row - 1) * (slotSize + slotGap) - scrollY
        else
            -- Для инвентаря игрока - используем точно такую же функцию как в utils.lua
            ghostX, ghostY = getScreenCoordinatesForCell(container, target.col, target.row)
        end
        
        -- Проверяем размеры предмета
        local itemW = itemInfo.w or 1
        local itemH = itemInfo.h or 1
        
        -- Рассчитываем размер прямоугольника с учетом размера предмета
        local ghostW = itemW * slotSize + (itemW - 1) * slotGap
        local ghostH = itemH * slotSize + (itemH - 1) * slotGap
        
        local color = target.valid and COLORS.drop_valid or COLORS.drop_invalid
        
        local clipRect
        if container.id == "vicinity" then
            local p = Panels.vicinity
            clipRect = { x = p.x, y = p.y + 40, w = p.w, h = p.h - 40 }
        else
            local p = Panels.player
            clipRect = { x = p.x, y = p.y + 40, w = p.w, h = p.h - 40 }
        end
        drawClippedRectangle(ghostX, ghostY, ghostW, ghostH, color, clipRect)
    end

    if DragDrop.isDragging and DragDrop.item then
        local mouseX, mouseY = getCursorPosition()
        mouseX, mouseY = mouseX * screenW, mouseY * screenH
        
        local itemInfo = Items[DragDrop.item.id]
        if not itemInfo then return end

        local slotSize, slotGap = 48, 2
        -- Проверяем размеры предмета
        local itemW = (itemInfo.w or 1) * slotSize + ((itemInfo.w or 1) - 1) * slotGap
        local itemH = (itemInfo.h or 1) * slotSize + ((itemInfo.h or 1) - 1) * slotGap

        dxDrawImage(mouseX - DragDrop.offsetX, mouseY - DragDrop.offsetY, itemW, itemH, itemInfo.image)
    end

    if ContextMenu.isOpen then
        drawContextMenu()
    end
    
    if Tooltip.item then
        drawItemTooltip()
        end
    end
    
function drawItemTooltip()
    local item = Tooltip.item
    local itemInfo = Items[item.id]
    if not itemInfo then return end
    
    -- Calculate tooltip dimensions
    local titleFont = Fonts.tooltipTitle
    local textFont = Fonts.tooltipText
    local titleFontSize = 1 -- Scale is now 1, size is controlled by dxCreateFont
    local textFontSize = 1
    
    local title = itemInfo.name
    local description = itemInfo.description or "Нет описания"
    local category = itemInfo.category or "misc"
    local categoryName = string.upper(category)
    
    -- Get formatted text dimensions
    local titleWidth = dxGetTextWidth(title, titleFontSize, titleFont)
    local descWidth = dxGetTextWidth(description, textFontSize, textFont)
    local catWidth = dxGetTextWidth("Категория: " .. categoryName, textFontSize, textFont)
    
    local contentWidth = math.min(Tooltip.maxWidth, math.max(titleWidth, descWidth, catWidth)) + (Tooltip.padding * 2)
    local titleHeight = dxGetFontHeight(titleFontSize, titleFont)
    local textHeight = dxGetFontHeight(textFontSize, textFont)
    
    local contentHeight = Tooltip.padding + titleHeight + Tooltip.padding/2 + textHeight
    
    -- Add extra lines
    if itemInfo.stackable then
        contentHeight = contentHeight + textHeight
    end
    
    -- Add durability line if applicable
    if itemInfo.durability then
        contentHeight = contentHeight + textHeight
    end
    
    -- Add category line
    contentHeight = contentHeight + textHeight
    
    -- Calculate approximate number of lines for description based on word wrapping
    local words = {}
    for word in string.gmatch(description, "[^%s]+") do
        table.insert(words, word)
    end
    
    local descLines = 1
    local currentLineWidth = 0
    local maxLineWidth = contentWidth - (Tooltip.padding * 2)
    
    for _, word in ipairs(words) do
        local wordWidth = dxGetTextWidth(word, textFontSize, textFont)
        local spaceWidth = currentLineWidth > 0 and dxGetTextWidth(" ", textFontSize, textFont) or 0
        
        if currentLineWidth + spaceWidth + wordWidth <= maxLineWidth then
            currentLineWidth = currentLineWidth + spaceWidth + wordWidth
        else
            descLines = descLines + 1
            currentLineWidth = wordWidth
            end
        end
    
    contentHeight = contentHeight + (descLines * textHeight) + Tooltip.padding
    
    -- Position tooltip near cursor but ensure it stays on screen
    local x, y = Tooltip.x + 15, Tooltip.y
    if x + contentWidth > screenW then
        x = screenW - contentWidth - 5
    end
    if y + contentHeight > screenH then
        y = screenH - contentHeight - 5
    end
    
    -- Draw tooltip background and border
    dxDrawRectangle(x - 2, y - 2, contentWidth + 4, contentHeight + 4, tocolor(0, 0, 0, 255)) -- Внешняя черная рамка
    dxDrawRectangle(x - 1, y - 1, contentWidth + 2, contentHeight + 2, Tooltip.borderColor)   -- Внутренняя светлая рамка
    dxDrawRectangle(x, y, contentWidth, contentHeight, Tooltip.backgroundColor)               -- Основной фон
    
    -- Draw item title with category color
    local categoryColor = getCategoryColor(category)
    local titleColor = tocolor(categoryColor[1], categoryColor[2], categoryColor[3], 255)
    dxDrawText(title, x + Tooltip.padding, y + Tooltip.padding, 
               x + contentWidth - Tooltip.padding, 0, titleColor, 
               titleFontSize, titleFont, "left", "top", false, false, false, false, true) -- Включаем subPixelPositioning
    
    -- Draw category
    local yOffset = y + Tooltip.padding + titleHeight + Tooltip.padding/2
    dxDrawText("Категория: " .. categoryName, x + Tooltip.padding, yOffset, 
               x + contentWidth - Tooltip.padding, 0, Tooltip.textColor, 
               textFontSize, textFont, "left", "top", false, false, false, false, true) -- Включаем subPixelPositioning
    yOffset = yOffset + textHeight
    
    -- Draw durability info if applicable
    if itemInfo.durability and itemInfo.current_durability then
        local durabilityPercent = math.floor((itemInfo.current_durability / itemInfo.durability) * 100)
        local durabilityText = "Состояние: " .. durabilityPercent .. "%"
        
        -- Choose color based on durability percentage
        local durabilityColor
        if durabilityPercent > 75 then
            durabilityColor = tocolor(50, 200, 50, 255) -- Green
        elseif durabilityPercent > 40 then
            durabilityColor = tocolor(200, 200, 50, 255) -- Yellow
        else
            durabilityColor = tocolor(200, 50, 50, 255) -- Red
        end
        
        -- Draw durability text
        dxDrawText(durabilityText, x + Tooltip.padding, yOffset, 
                   x + contentWidth - Tooltip.padding, 0, durabilityColor, 
                   textFontSize, textFont, "left", "top", false, false, false, false, true)
        
        -- Draw durability bar (with more space between text and bar)
        local barWidth = contentWidth - (Tooltip.padding * 2)
        local barHeight = 6
        local barX = x + Tooltip.padding
        local barY = yOffset + textHeight + 2 -- Increased spacing
        
        -- Background bar (dark)
        dxDrawRectangle(barX, barY, barWidth, barHeight, tocolor(40, 40, 40, 200))
        
        -- Filled portion of bar
        local filledWidth = (durabilityPercent / 100) * barWidth
        dxDrawRectangle(barX, barY, filledWidth, barHeight, durabilityColor)
        
        -- Add border around the bar
        dxDrawRectangle(barX - 1, barY - 1, barWidth + 2, 1, tocolor(60, 60, 60, 200)) -- Top
        dxDrawRectangle(barX - 1, barY + barHeight, barWidth + 2, 1, tocolor(60, 60, 60, 200)) -- Bottom
        dxDrawRectangle(barX - 1, barY, 1, barHeight, tocolor(60, 60, 60, 200)) -- Left
        dxDrawRectangle(barX + barWidth, barY, 1, barHeight, tocolor(60, 60, 60, 200)) -- Right
        
        yOffset = yOffset + textHeight + barHeight + 6 -- Increase offset to account for bar height
    end
    
    -- Draw stack info if applicable
    if itemInfo.stackable then
        local stackText = "Количество: " .. (item.count or 1) .. " / " .. itemInfo.max_stack
        dxDrawText(stackText, x + Tooltip.padding, yOffset, 
                   x + contentWidth - Tooltip.padding, 0, Tooltip.textColor, 
                   textFontSize, textFont, "left", "top", false, false, false, false, true) -- Включаем subPixelPositioning
        yOffset = yOffset + textHeight
    end
    
    -- Draw description with word wrapping
    local descriptionY = yOffset
    local descriptionMaxWidth = contentWidth - (Tooltip.padding * 2)
    
    -- Manually handle word wrapping for better control
    local words = {}
    for word in string.gmatch(description, "[^%s]+") do
        table.insert(words, word)
    end
    
    local line = ""
    local lineHeight = textHeight
    
    for i, word in ipairs(words) do
        local testLine = line .. (line ~= "" and " " or "") .. word
        local testWidth = dxGetTextWidth(testLine, textFontSize, textFont)
        
        if testWidth > descriptionMaxWidth then
            -- Draw the current line and start a new one
            dxDrawText(line, x + Tooltip.padding, descriptionY, 
                       x + contentWidth - Tooltip.padding, 0, 
                       Tooltip.textColor, textFontSize, textFont, "left", "top", false, false, false, false, true)
            descriptionY = descriptionY + lineHeight
            line = word
        else
            line = testLine
        end
    end
    
    -- Draw the last line
    if line ~= "" then
        dxDrawText(line, x + Tooltip.padding, descriptionY, 
                   x + contentWidth - Tooltip.padding, 0, 
                   Tooltip.textColor, textFontSize, textFont, "left", "top", false, false, false, false, true)
    end
end


function drawContextMenu()
    local x, y, w, h = ContextMenu.x, ContextMenu.y, ContextMenu.w, ContextMenu.h
    local optionH = 25
    
    -- Draw background
    dxDrawRectangle(x, y, w, h, COLORS.panel)
    
    -- Draw options
    for i, option in ipairs(ContextMenu.options) do
        local optY = y + (i - 1) * optionH
        local textColor = COLORS.text_light
        
        -- Highlight hovered option
        if ContextMenu.hoveredOption == option then
            dxDrawRectangle(x, optY, w, optionH, tocolor(60, 60, 60, 255))
        end
        
        dxDrawText(option.label, x + 10, optY, x + w, optY + optionH, textColor, 1, Fonts.main, "left", "center", false, false, false, false, true)
                    end
                end

function drawContainerGrid(gridX, gridY, container, clipRect)
    local slotSize, slotGap = 48, 2
    -- Draw grid slots
    if container.grid then
        for row = 0, container.grid.rows - 1 do
            for col = 0, container.grid.cols - 1 do
                local sx = gridX + col * (slotSize + slotGap)
                local sy = gridY + row * (slotSize + slotGap)
                drawClippedRectangle(sx, sy, slotSize, slotSize, COLORS.slot, clipRect)
            end
        end
    end

    -- Draw items
    if container.items then
        for _, itemData in ipairs(container.items) do
            if not (DragDrop.isDragging and itemData == DragDrop.item) then
                local itemInfo = Items[itemData.id]
                local col, row = itemData.x - 1, itemData.y - 1
                -- Проверяем размеры предмета
                local itemW = itemInfo.w or 1
                local itemH = itemInfo.h or 1
                
                local itemAreaW = itemW * slotSize + (itemW - 1) * slotGap
                local itemAreaH = itemH * slotSize + (itemH - 1) * slotGap
                local areaX = gridX + col * (slotSize + slotGap)
                local areaY = gridY + row * (slotSize + slotGap)
                
                -- Check if this item has an active animation
                local isAnimating = false
                local renderX, renderY, alpha = areaX, areaY, 255
                
                for _, anim in ipairs(Animations.items) do
                    if anim.item == itemData then
                        isAnimating = true
                        renderX, renderY = anim.currentX, anim.currentY
                        alpha = anim.currentAlpha
                        break
                    end
                end
                
                -- Get category color for the item
                local categoryColor = {20, 20, 20} -- Default dark gray
                if itemInfo.category then
                    categoryColor = getCategoryColor(itemInfo.category)
                end
                
                -- Check if item is being hovered
                local isHovered = false
                if Tooltip.item == itemData then
                    isHovered = true
                end
                
                -- Calculate hover effect (glow)
                local glowIntensity = 0
                if isHovered then
                    -- Create hover effect entry if it doesn't exist
                    if not Animations.hoverEffects[itemData] then
                        Animations.hoverEffects[itemData] = 0
                    end
                    -- Increase glow intensity
                    Animations.hoverEffects[itemData] = math.min(1, Animations.hoverEffects[itemData] + 0.1)
                else
                    -- Decrease glow intensity if exists
                    if Animations.hoverEffects[itemData] then
                        Animations.hoverEffects[itemData] = math.max(0, Animations.hoverEffects[itemData] - 0.1)
                        if Animations.hoverEffects[itemData] == 0 then
                            Animations.hoverEffects[itemData] = nil
                        end
                    end
                end
    
                -- Get glow intensity if it exists
                glowIntensity = Animations.hoverEffects[itemData] or 0
                
                -- Draw item background with category color and animation alpha
                local bgColor = tocolor(categoryColor[1], categoryColor[2], categoryColor[3], 150 * (alpha / 255))
                drawClippedRectangle(renderX, renderY, itemAreaW, itemAreaH, bgColor, clipRect)
                
                -- Draw durability bar if applicable
                if itemInfo.durability and itemInfo.current_durability then
                    local durabilityPercent = itemInfo.current_durability / itemInfo.durability
                    local barHeight = 3
                    local barWidth = itemAreaW * durabilityPercent
                    
                    -- Choose color based on durability percentage
                    local durabilityColor
                    if durabilityPercent > 0.75 then
                        durabilityColor = tocolor(50, 200, 50, 200 * (alpha / 255)) -- Green
                    elseif durabilityPercent > 0.4 then
                        durabilityColor = tocolor(200, 200, 50, 200 * (alpha / 255)) -- Yellow
                    else
                        durabilityColor = tocolor(200, 50, 50, 200 * (alpha / 255)) -- Red
                    end
                    
                    -- Draw durability bar at the bottom of the item
                    drawClippedRectangle(renderX, renderY + itemAreaH - barHeight, barWidth, barHeight, durabilityColor, clipRect)
                end
                
                -- Draw glow effect if hovered
                if glowIntensity > 0 then
                    local glowColor = tocolor(255, 255, 255, 50 * glowIntensity * (alpha / 255))
                    drawClippedRectangle(renderX - 2, renderY - 2, itemAreaW + 4, itemAreaH + 4, glowColor, clipRect)
                end
                
                -- Draw a small category indicator in the top-left corner
                local indicatorSize = 6
                local indicatorColor = tocolor(categoryColor[1], categoryColor[2], categoryColor[3], 255 * (alpha / 255))
                drawClippedRectangle(renderX + 2, renderY + 2, indicatorSize, indicatorSize, indicatorColor, clipRect)
                
                -- Draw item image with potential animation alpha and scale effect for hover
                local imageW, imageH = itemAreaW - 15, itemAreaH - 15
                local imgAlpha = alpha
                -- Check if this item has a scale animation
                local scale = 1 + (0.05 * glowIntensity)
                local rotation = 0
                
                for _, anim in ipairs(Animations.items) do
                    if anim.item == itemData and anim.currentScale then
                        scale = anim.currentScale
                        rotation = anim.currentRotation or 0
                        break
                    end
                end

                local imgX = renderX + 7.5 - ((imageW * scale - imageW) / 2)
                local imgY = renderY + 7.5 - ((imageH * scale - imageH) / 2)
                dxDrawImage(imgX, imgY, imageW * scale, imageH * scale, itemInfo.image, rotation, 0, 0, tocolor(255, 255, 255, imgAlpha))
                
                -- Draw stack count if needed
                if itemData.count and itemData.count > 1 then
                    local textColor = tocolor(220, 220, 220, alpha)
                    dxDrawText(itemData.count, renderX, renderY, renderX + itemAreaW - 4, renderY + itemAreaH - 2, textColor, 1, Fonts.main, "right", "bottom", false, false, false, false, true)
                end
            end
        end
    end
end

function updateInventoryPanelRenderTarget()
    if not isElement(RenderTargets.inventory) then return end
    
    local w, h = dxGetMaterialSize(RenderTargets.inventory)
    dxSetRenderTarget(RenderTargets.inventory, true)
    
    -- Очищаем рендер-таргет полностью
    dxDrawRectangle(0, 0, w, h, tocolor(0, 0, 0, 0))
    
    local currentY = 0
    local p = 5

    for _, container in ipairs(Panels.player.containers) do
        container.render = { x = 0, y = currentY, w = w }
        currentY = drawContainerSection(container, nil) -- Passing nil for clipRect as we draw the whole thing
    end

    dxSetRenderTarget()
    
    -- Отметить как обновленный
    RenderTargets.needsUpdate.inventory = false
end

function drawContainerSection(container, panelClipRect)
    local p, headerH, slotSize, slotGap = 10, 40, 48, 2
    local x, y, w = container.render.x, container.render.y, container.render.w

    local gridH = container.grid.rows * (slotSize + slotGap) - slotGap
    local totalH = headerH + gridH + (p * 2)
    
    if panelClipRect and (y + totalH < panelClipRect.y or y > panelClipRect.y + panelClipRect.h) then
        return y + totalH + 10
    end
    
    drawClippedRectangle(x, y, w, totalH, COLORS.header, panelClipRect)
    
    if container.dot then
        dxDrawCircle(x + p + 5, y + headerH/2, 4, COLORS["dot_"..container.dot])
    end
    dxDrawText(container.label, x + p + 15, y, x + w - p, y + headerH, COLORS.text_light, 1, Fonts.sectionHeader, "left", "center", false, false, panelClipRect ~= nil, false, true)

    local contentX = x + p
    local contentY = y + headerH + p

    local clipRectForGrid
    if panelClipRect then
        local nestedClip = {
            x = x, y = y, w = w, h = totalH,
            intersect = function(self, other)
                local newX = math.max(self.x, other.x)
                local newY = math.max(self.y, other.y)
                local newW = math.min(self.x + self.w, other.x + other.w) - newX
                local newH = math.min(self.y + self.h, other.y + other.h) - newY
                return { x = newX, y = newY, w = newW, h = newH }
            end
        }
        clipRectForGrid = nestedClip:intersect(panelClipRect)
    else
        clipRectForGrid = nil
    end

    drawContainerGrid(contentX, contentY, container, clipRectForGrid)
    
    return y + totalH + 10
end

-- Helper for clipping rectangles, essential for scrolling UI
function drawClippedRectangle(x, y, w, h, color, clip)
    if not clip then dxDrawRectangle(x, y, w, h, color); return end
    local visibleYStart = math.max(y, clip.y)
    local visibleYEnd = math.min(y + h, clip.y + clip.h)
    if visibleYEnd > visibleYStart then
        dxDrawRectangle(x, visibleYStart, w, visibleYEnd - visibleYStart, color)
    end
end

function drawEquipmentPanel(x, y, w, h)
    -- (This is static and can be left as is for now)
    dxDrawRectangle(x, y, w, h, COLORS.panel)
    dxDrawRectangle(x, y, w, 40, COLORS.header)
    dxDrawText("EQUIPMENT", x, y, x + w, y + 40, COLORS.text_light, 1, Fonts.main, "center", "center", false, false, false, false, true)
end
