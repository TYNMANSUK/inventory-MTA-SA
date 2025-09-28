-- Event handlers for Inventory System

function getPlacementInfo(draggedItem, targetContainer, targetCol, targetRow)
    local itemInfo = Items[draggedItem.id]
    if not itemInfo then
        return { valid = false, reason = "invalid_item" }
    end
    
    -- Проверяем размеры предмета
    local itemW = itemInfo.w or 1
    local itemH = itemInfo.h or 1
    
    if not targetContainer.grid then
        return { valid = false, reason = "no_grid" }
    end
    local targetGrid = targetContainer.grid

    -- 1. Boundary Check
    if targetCol < 1 or targetRow < 1 or (targetCol + itemW - 1) > targetGrid.cols or (targetRow + itemH - 1) > targetGrid.rows then
        return { valid = false, reason = "out_of_bounds" }
    end

    -- 2. Collision Check: Just find what's there. The handler will decide what to do.
    local collidingItems = {}
    if targetContainer.items then
        for _, existingItem in ipairs(targetContainer.items) do
            if existingItem ~= draggedItem then
                local existingItemInfo = Items[existingItem.id]
                if existingItemInfo then
                    -- Получаем размеры существующего предмета
                    local existingW = existingItemInfo.w or 1
                    local existingH = existingItemInfo.h or 1
                    
                    if (targetCol < existingItem.x + existingW and
                        targetCol + itemW > existingItem.x and
                        targetRow < existingItem.y + existingH and
                        targetRow + itemH > existingItem.y)
                    then
                        table.insert(collidingItems, existingItem)
                    end
                end
            end
        end
    end
    
    return { valid = true, collisions = collidingItems }
end

function handleMouseClick(button, state)
    if (DragDrop.isDragging and state == "down") then return end
    
    local mouseX, mouseY = getCursorPosition()
    mouseX, mouseY = mouseX * screenW, mouseY * screenH

    -- Handle context menu logic first
    if ContextMenu.isOpen then
        if state == "down" then
            if isCursorInArea(mouseX, mouseY, ContextMenu.x, ContextMenu.y, ContextMenu.w, ContextMenu.h) and button == "left" then
                if ContextMenu.hoveredOption then
                    outputChatBox("Action: "..ContextMenu.hoveredOption.label.." on item: "..Items[ContextMenu.item.id].name)
                    ContextMenu.isOpen = false
                end
            else
                ContextMenu.isOpen = false
            end
        end
        return
    end

    if state == "down" then
        local clickedItem, sourceContainer, areaX, areaY = findItemAtCursor(mouseX, mouseY)
        
        if clickedItem then
            if button == "left" then
                DragDrop.isDragging = true
                DragDrop.item = clickedItem
                DragDrop.originalSource = sourceContainer
                DragDrop.originalX, DragDrop.originalY = clickedItem.x, clickedItem.y
                DragDrop.offsetX, DragDrop.offsetY = mouseX - areaX, mouseY - areaY
            elseif button == "right" then
                ContextMenu.isOpen = true
                ContextMenu.item = clickedItem
                ContextMenu.x, ContextMenu.y = mouseX, mouseY
                ContextMenu.options = { { label = "Use", action = "use" }, { label = "Split", action = "split" }, { label = "Drop", action = "drop" } }
                ContextMenu.h = #ContextMenu.options * 25
            elseif button == "middle" then
                local itemInfo = Items[clickedItem.id]
                if itemInfo.stackable and clickedItem.count > 1 then
                    local amountToTake = math.floor(clickedItem.count / 2)
                    clickedItem.count = clickedItem.count - amountToTake
                    local newItem = { id = clickedItem.id, count = amountToTake }
                    DragDrop.isDragging, DragDrop.isSplitting = true, true
                    DragDrop.item = newItem
                    DragDrop.splitSourceItem = clickedItem
                    DragDrop.originalSource = sourceContainer
                    DragDrop.offsetX, DragDrop.offsetY = mouseX - areaX, mouseY - areaY
                end
            end
            return
        end
    elseif state == "up" and (button == "left" or button == "middle") then
        if DragDrop.isDragging then
            local target = DragDrop.dropTarget
            local draggedItem = DragDrop.item
            local sourceContainer = DragDrop.originalSource
            local isValidDrop = false

            if target and target.valid and target.collisions then
                local targetContainer = target.container
                local collidingItems = target.collisions
                
                if #collidingItems == 0 then
                    -- Расчет целевой позиции для анимации
                    local slotSize, slotGap = 48, 2
                    local targetX, targetY = getScreenCoordinatesForCell(targetContainer, target.col, target.row)

                    local mouseX, mouseY = getCursorPosition()
                    mouseX, mouseY = mouseX * screenW, mouseY * screenH
                    local startX = mouseX - DragDrop.offsetX
                    local startY = mouseY - DragDrop.offsetY
                    
                    -- Запоминаем новую позицию предмета
                    draggedItem.x, draggedItem.y = target.col, target.row
                    
                    if DragDrop.isSplitting then 
                        targetContainer:addItem(draggedItem)
                        -- Создаем анимацию с точными координатами
                        createItemAnimation(draggedItem, startX, startY, targetX, targetY, 150, 255)
                    else
                        if sourceContainer ~= targetContainer then
                            sourceContainer:removeItem(draggedItem)
                            targetContainer:addItem(draggedItem)
                        end
                        -- Создаем анимацию с точными координатами
                        createItemAnimation(draggedItem, startX, startY, targetX, targetY, 255, 255)
                    end

                    isValidDrop = true
                elseif #collidingItems == 1 then
                    local targetItem = collidingItems[1]
                    local draggedInfo = Items[draggedItem.id]
                    local targetInfo = Items[targetItem.id]

                    if draggedInfo.stackable and draggedItem.id == targetItem.id and (targetItem.count + draggedItem.count) <= targetInfo.max_stack then
                        local targetX, targetY = getScreenCoordinatesForCell(targetContainer, targetItem.x, targetItem.y)
                        
                        local pulseAnim = createItemAnimation(targetItem, targetX, targetY, targetX, targetY, 255, 400, function()
                            createItemAnimation(targetItem, targetX, targetY, targetX, targetY, 400, 255)
                        end)
                        pulseAnim.startScale, pulseAnim.endScale, pulseAnim.currentScale = 1.0, 1.2, 1.0
                        pulseAnim.startRotation, pulseAnim.endRotation, pulseAnim.currentRotation = -5, 5, 0
                        
                        targetItem.count = targetItem.count + draggedItem.count
                        if not DragDrop.isSplitting then sourceContainer:removeItem(draggedItem) end
                        isValidDrop = true
                    elseif not DragDrop.isSplitting and draggedInfo.w == targetInfo.w and draggedInfo.h == targetInfo.h then
                        
                        local targetItemX, targetItemY = getScreenCoordinatesForCell(targetContainer, targetItem.x, targetItem.y)
                        local sourceItemX, sourceItemY = getScreenCoordinatesForCell(sourceContainer, DragDrop.originalX, DragDrop.originalY)
                        
                        local mouseX, mouseY = getCursorPosition()
                        mouseX, mouseY = mouseX * screenW, mouseY * screenH
                        local draggedStartX = mouseX - DragDrop.offsetX
                        local draggedStartY = mouseY - DragDrop.offsetY
                        
                        if sourceContainer ~= targetContainer then
                            sourceContainer:removeItem(draggedItem)
                            targetContainer:addItem(draggedItem)
                            targetContainer:removeItem(targetItem)
                            sourceContainer:addItem(targetItem)
                        end
                        draggedItem.x, targetItem.x = targetItem.x, DragDrop.originalX
                        draggedItem.y, targetItem.y = targetItem.y, DragDrop.originalY
                        
                        createItemAnimation(draggedItem, draggedStartX, draggedStartY, targetItemX, targetItemY, 255, 255)
                        createItemAnimation(targetItem, targetItemX, targetItemY, sourceItemX, sourceItemY, 255, 255)
                        
                        isValidDrop = true
                    end
                end
            end

            if not isValidDrop and DragDrop.isSplitting then
                DragDrop.splitSourceItem.count = DragDrop.splitSourceItem.count + draggedItem.count
            end

            if isValidDrop then
                if sourceContainer.id ~= 'vicinity' or (target and target.container and target.container.id ~= 'vicinity') then
                    requestRenderTargetUpdate("inventory")
                end
            end

            DragDrop.isDragging, DragDrop.isSplitting, DragDrop.splitSourceItem, DragDrop.item, DragDrop.dropTarget, DragDrop.originalSource = false, false, nil, nil, nil, nil
        end
    end
end

function findItemAtCursor(mouseX, mouseY)
    -- 1. Check Vicinity Panel
    local panel = Panels.vicinity
    local container = panel.container
    if isCursorInArea(mouseX, mouseY, panel.x, panel.y, panel.w, panel.h) then
        local p, headerH, slotSize, slotGap = 8, 40, 48, 2
        local scrollY = container.getScroll()
        local gridX = panel.x + p
        local gridY = panel.y + headerH + p - scrollY
        
        for i = #container.items, 1, -1 do
            local item = container.items[i]
            local itemInfo = Items[item.id]
            local areaX = gridX + (item.x - 1) * (slotSize + slotGap)
            local areaY = gridY + (item.y - 1) * (slotSize + slotGap)
            local itemW = itemInfo.w * slotSize + (itemInfo.w - 1) * slotGap
            local itemH = itemInfo.h * slotSize + (itemInfo.h - 1) * slotGap
            if isCursorInArea(mouseX, mouseY, areaX, areaY, itemW, itemH) then
                return item, container, areaX, areaY
            end
        end
    end

    -- 2. Check Player Inventory Panel
    local panel = Panels.player
    if isCursorInArea(mouseX, mouseY, panel.x, panel.y, panel.w, panel.h) then
        local panelPadding = 10
        local sectionPadding = 10
        local headerH, slotSize, slotGap = 40, 48, 2
        local contentMouseY = mouseY - (panel.y + headerH) + Scroll.inventory

        for _, container in ipairs(panel.containers) do
            local sectionH = calculateSectionHeight(container.grid.cols, container.grid.rows)
            if contentMouseY >= container.render.y and contentMouseY < container.render.y + sectionH then
                local gridX = panel.x + panelPadding
                local gridY = panel.y + headerH + container.render.y + 25 + sectionPadding - Scroll.inventory
                
                for i = #container.items, 1, -1 do
                    local item = container.items[i]
                    local itemInfo = Items[item.id]
                    local areaX = gridX + (item.x - 1) * (slotSize + slotGap)
                    local areaY = gridY + (item.y - 1) * (slotSize + slotGap)
                    local itemW = itemInfo.w * slotSize + (itemInfo.w - 1) * slotGap
                    local itemH = itemInfo.h * slotSize + (itemInfo.h - 1) * slotGap
                    if isCursorInArea(mouseX, mouseY, areaX, areaY, itemW, itemH) then
                        return item, container, areaX, areaY
                    end
                end
            end
        end
    end

    return nil, nil, nil, nil
end

function handleMouseMove(mouseX, mouseY)
    local mouseX, mouseY = getCursorPosition()
    mouseX, mouseY = mouseX * screenW, mouseY * screenH
    
    Tooltip.item = nil
    
    if DragDrop.isDragging then
        DragDrop.dropTarget = nil
        
        -- 1. Check Vicinity Panel for drop target
        local panel = Panels.vicinity
        local container = panel.container
        if isCursorInArea(mouseX, mouseY, panel.x, panel.y, panel.w, panel.h) then
            local p, headerH, slotSize, slotGap = 8, 40, 48, 2
            local scrollY = container.getScroll()
            local gridX = panel.x + p
            local gridY = panel.y + headerH + p - scrollY
            local relativeMouseX = mouseX - gridX
            local relativeMouseY = mouseY - gridY
            local targetCol = math.floor(relativeMouseX / (slotSize + slotGap)) + 1
            local targetRow = math.floor(relativeMouseY / (slotSize + slotGap)) + 1
            
            local placement = getPlacementInfo(DragDrop.item, container, targetCol, targetRow)
            DragDrop.dropTarget = { container = container, col = targetCol, row = targetRow, valid = placement.valid, collisions = placement.collisions }
            return
        end

        -- 2. Check Player Inventory Panel for drop target
        local panel = Panels.player
        if isCursorInArea(mouseX, mouseY, panel.x, panel.y, panel.w, panel.h) then
            local panelPadding = 10
            local sectionPadding = 10
            local headerH, slotSize, slotGap = 40, 48, 2
            local contentMouseY = mouseY - (panel.y + headerH) + Scroll.inventory

            for _, container in ipairs(panel.containers) do
                local sectionH = calculateSectionHeight(container.grid.cols, container.grid.rows)
                if contentMouseY >= container.render.y and contentMouseY < container.render.y + sectionH then
                    local gridBodyY = container.render.y + 40 -- 40 is section header from render.lua
                    if contentMouseY > gridBodyY then
                        -- Полностью переработанный расчет координат для инвентаря
                        -- Рассчитываем координаты сетки для этого контейнера
                        local gridX, gridY = panel.x + panelPadding + sectionPadding, panel.y + headerH + container.render.y + 40 + sectionPadding - Scroll.inventory
                        
                        -- Рассчитываем колонку и строку на основе позиции мыши
                        local relativeMouseX = mouseX - gridX
                        local relativeMouseY = mouseY - gridY
                        local targetCol = math.floor(relativeMouseX / (slotSize + slotGap)) + 1
                        local targetRow = math.floor(relativeMouseY / (slotSize + slotGap)) + 1

                        local placement = getPlacementInfo(DragDrop.item, container, targetCol, targetRow)
                        DragDrop.dropTarget = { container = container, col = targetCol, row = targetRow, valid = placement.valid, collisions = placement.collisions }
                        return
                    end
                end
            end
        end

    elseif ContextMenu.isOpen then
        ContextMenu.hoveredOption = nil
        if isCursorInArea(mouseX, mouseY, ContextMenu.x, ContextMenu.y, ContextMenu.w, ContextMenu.h) then
            local relativeY = mouseY - ContextMenu.y
            local optionIndex = math.floor(relativeY / 25) + 1
            if ContextMenu.options[optionIndex] then
                ContextMenu.hoveredOption = ContextMenu.options[optionIndex]
            end
        end
    else
        local item, _ = findItemAtCursor(mouseX, mouseY)
        if item then
            Tooltip.item = item
            Tooltip.x, Tooltip.y = mouseX, mouseY
        end
    end
end

function handleScroll(key)
    if not inventoryOpen then return end
    
    local amount = 35
    local mouseX, mouseY = getCursorPosition()
    mouseX, mouseY = mouseX * screenW, mouseY * screenH

    if isCursorInArea(mouseX, mouseY, Panels.vicinity.x, Panels.vicinity.y, Panels.vicinity.w, Panels.vicinity.h) then
        local container = Panels.vicinity.container
        local p, headerH, slotSize, slotGap = 8, 40, 48, 2
        local contentH = container.grid.rows * (slotSize + slotGap) - slotGap + (p * 2)
        local viewableH = Panels.vicinity.h - headerH
        local maxScroll = math.max(0, contentH - viewableH)
        if key == "mouse_wheel_down" then
            Scroll.targetVicinity = math.min(Scroll.targetVicinity + amount, maxScroll)
        elseif key == "mouse_wheel_up" then
            Scroll.targetVicinity = math.max(Scroll.targetVicinity - amount, 0)
        end

    elseif isCursorInArea(mouseX, mouseY, Panels.player.x, Panels.player.y, Panels.player.w, Panels.player.h) then
        local panel = Panels.player
        local p, headerH = 10, 40
        local totalContentH = 0
        for _, container in ipairs(panel.containers) do
            totalContentH = totalContentH + calculateSectionHeight(container.grid.cols, container.grid.rows, false)
        end
        
        local viewableH = panel.h - headerH
        local maxScroll = math.max(0, totalContentH - viewableH + p)
        if key == "mouse_wheel_down" then
            Scroll.targetInventory = math.min(Scroll.targetInventory + amount, maxScroll)
        elseif key == "mouse_wheel_up" then
            Scroll.targetInventory = math.max(Scroll.targetInventory - amount, 0)
        end
    end
end

function requestRenderTargetUpdate(panelId)
    RenderTargets.needsUpdate[panelId] = true
end

function toggleInventory()
    local wasOpen = inventoryOpen
    inventoryOpen = not inventoryOpen
    
    if inventoryOpen then
        -- Opening animation effect
        addEventHandler("onClientRender", root, renderMain)
        addEventHandler("onClientClick", root, handleMouseClick)
        addEventHandler("onClientCursorMove", root, handleMouseMove)
        bindKey("mouse_wheel_up", "down", handleScroll)
        bindKey("mouse_wheel_down", "down", handleScroll)
        showCursor(true)
        
        -- Create Render Targets
        local p = 10
        local totalContentH = 0
        for _, id in ipairs({ "jacket", "vest", "pants", "belt", "backpack" }) do
            local container = InventoryRegistry[id]
            if container then
                totalContentH = totalContentH + calculateSectionHeight(container.grid and container.grid.cols, container.grid and container.grid.rows, false)
            end
        end
        totalContentH = totalContentH + p
        
        if isElement(RenderTargets.inventory) then destroyElement(RenderTargets.inventory) end
        RenderTargets.inventory = dxCreateRenderTarget(panelW - (p*2), totalContentH, true)
        requestRenderTargetUpdate("inventory")

    else
        removeEventHandler("onClientRender", root, renderMain)
        removeEventHandler("onClientClick", root, handleMouseClick)
        removeEventHandler("onClientCursorMove", root, handleMouseMove)
        unbindKey("mouse_wheel_up", "down", handleScroll)
        unbindKey("mouse_wheel_down", "down", handleScroll)
        showCursor(false)
        
        -- Destroy Render Targets
        if isElement(RenderTargets.inventory) then
            destroyElement(RenderTargets.inventory)
            RenderTargets.inventory = nil
        end

        -- Safety check: if inventory is closed while dragging, cancel drag
        if DragDrop.isDragging then
            DragDrop.isDragging = false
            DragDrop.isSplitting = false
            DragDrop.splitSourceItem = nil
            DragDrop.item = nil
            DragDrop.dropTarget = nil
            DragDrop.originalSource = nil
        end
        
        -- Clear any remaining animations
        Animations.items = {}
        Animations.hoverEffects = {}
        
        -- Reset tooltip
        Tooltip.item = nil
        
        -- Close context menu if open
        ContextMenu.isOpen = false
    end
end
