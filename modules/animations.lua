-- Animation and particle effects for Inventory System

-- Экспортируем функцию в глобальную область видимости
_G.updateAnimations = nil

function createItemAnimation(item, startX, startY, endX, endY, startAlpha, endAlpha, onComplete, options)
    options = options or {}
    
    -- Проверка координат для предотвращения ошибок
    if not startX or not startY or not endX or not endY then
        outputChatBox("ERROR: Invalid animation coordinates")
        return nil
    end
    
    local anim = {
        item = item,
        startX = startX, startY = startY,
        endX = endX, endY = endY,
        currentX = startX, currentY = startY,
        startAlpha = startAlpha or 255,
        endAlpha = endAlpha or 255,
        currentAlpha = startAlpha or 255,
        onComplete = onComplete,
        progress = 0,
        
        -- Animation properties with defaults that can be overridden by options
        scale = options.scale or 1.0,
        startScale = options.startScale or options.scale or 1.0,
        endScale = options.endScale or options.scale or 1.0,
        currentScale = options.startScale or options.scale or 1.0,
        
        rotation = options.rotation or 0,
        startRotation = options.startRotation or options.rotation or 0,
        endRotation = options.endRotation or options.rotation or 0,
        currentRotation = options.startRotation or options.rotation or 0,
        
        bounceHeight = options.bounceHeight or 0,
        bounceFactor = options.bounceFactor or 0,
        
        -- Animation type
        animType = options.animType or "normal",
        isDone = false
    }
    
    table.insert(Animations.items, anim)
    return anim
end

function updateAnimations()
    if not Animations then return end
    if not Animations.items then Animations.items = {} end
    
    -- Экспортируем функцию в глобальную область видимости
    _G.updateAnimations = updateAnimations
    local i = 1
    while i <= #Animations.items do
        local anim = Animations.items[i]
        
        -- Проверка на некорректные значения
        if not anim or not anim.currentX or not anim.currentY or not anim.endX or not anim.endY then
            table.remove(Animations.items, i)
            i = i - 1
        else
        
        -- Increment progress
        anim.progress = math.min(1, anim.progress + 0.05)
        
        -- Handle different animation types
        if anim.animType == "drop" then
            -- Special drop animation with bounce
            updateDropAnimation(anim)
        else
            -- Standard animation
            -- Update position with easing
            if anim.currentX ~= nil and anim.endX ~= nil then
                local dx = anim.endX - anim.currentX
                local dy = anim.endY - anim.currentY
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance > Animations.moveSpeed then
                    -- Apply easing for smoother movement
                    local ratio = Animations.moveSpeed / distance
                    -- Cubic easing: slower at start and end, faster in middle
                    local easeRatio = ratio * (1 - math.cos((anim.progress * math.pi) / 2))
                    anim.currentX = anim.currentX + dx * easeRatio
                    anim.currentY = anim.currentY + dy * easeRatio
                else
                    anim.currentX = anim.endX
                    anim.currentY = anim.endY
                end
            end
        end
        
        -- Update alpha with smoother transition
        if anim.currentAlpha ~= nil and anim.endAlpha ~= nil then
            if anim.currentAlpha < anim.endAlpha then
                anim.currentAlpha = math.min(anim.currentAlpha + Animations.fadeSpeed * 255, anim.endAlpha)
            elseif anim.currentAlpha > anim.endAlpha then
                anim.currentAlpha = math.max(anim.currentAlpha - Animations.fadeSpeed * 255, anim.endAlpha)
        end
    end
    
        -- Update scale
        if anim.startScale and anim.endScale then
            local scaleProgress = anim.progress or 0.5
            -- Sinusoidal easing for scale
            anim.currentScale = anim.startScale + (anim.endScale - anim.startScale) * 
                                (math.sin(scaleProgress * math.pi - math.pi/2) + 1) / 2
        end
        
        -- Update rotation
        if anim.startRotation and anim.endRotation then
            local rotProgress = anim.progress or 0.5
            -- Sinusoidal oscillation for rotation
            anim.currentRotation = anim.startRotation + 
                                  (anim.endRotation - anim.startRotation) * math.sin(rotProgress * math.pi * 2)
        end
        
        -- Check if animation is complete
        local isComplete = true
        if anim.currentX ~= nil and anim.endX ~= nil and anim.currentX ~= anim.endX then
            isComplete = false
        end
        if anim.currentY ~= nil and anim.endY ~= nil and anim.currentY ~= anim.endY then
            isComplete = false
        end
        if anim.currentAlpha ~= nil and anim.endAlpha ~= nil and anim.currentAlpha ~= anim.endAlpha then
            isComplete = false
        end
        
        -- Force completion if progress is at 100%
        if anim.progress >= 1 then
            isComplete = true
        end
        
        if isComplete then
            anim.isDone = true
            if anim.onComplete then
                anim.onComplete()
            end
            table.remove(Animations.items, i)
        else
            i = i + 1
        end
        end
        i = i + 1
    end
    
    -- Update particles
    updateParticles()
end

function updateDropAnimation(anim)
    -- Calculate a path with a bounce effect
    local progress = anim.progress
    local dx = anim.endX - anim.startX
    local dy = anim.endY - anim.startY
    
    -- Horizontal movement (linear)
    anim.currentX = anim.startX + dx * progress
    
    -- Vertical movement with bounce
    local bounceHeight = anim.bounceHeight or 40
    local bounceFactor = anim.bounceFactor or 0.5
    
    -- First half of animation: item goes up and then down
    if progress < 0.5 then
        local bounceProgress = progress * 2 -- Scale to 0-1 for first half
        -- Parabolic arc: y = 4h * x * (1-x) where h is max height
        local bounceOffset = 4 * bounceHeight * bounceProgress * (1 - bounceProgress)
        anim.currentY = anim.startY + dy * progress - bounceOffset
    else
        -- Second half: smaller bounce
        local bounceProgress = (progress - 0.5) * 2 -- Scale to 0-1 for second half
        -- Smaller parabolic arc
        local bounceOffset = 4 * bounceHeight * bounceFactor * bounceProgress * (1 - bounceProgress)
        anim.currentY = anim.startY + dy * progress - bounceOffset
    end
    
    -- Add rotation during the drop
    anim.currentRotation = anim.startRotation + (anim.endRotation - anim.startRotation) * progress
end

function updateParticles()
    -- Process all particle effects
    local i = 1
    while i <= #Animations.particles do
        local particle = Animations.particles[i]
        
        -- Update particle position and properties
        particle.life = particle.life - 0.05
        particle.x = particle.x + particle.speedX
        particle.y = particle.y + particle.speedY
        particle.alpha = math.max(0, particle.alpha * 0.9)
        particle.size = particle.size * 0.95
        
        -- Remove dead particles
        if particle.life <= 0 or particle.alpha < 10 or particle.size < 1 then
            table.remove(Animations.particles, i)
        else
            i = i + 1
            end
        end
    end
    
-- Create particles for an item
function createItemParticles(itemInfo, x, y, width, height, particleType)
    particleType = particleType or "drop"
    
    local particleCount = 0
    local particleColor = {255, 255, 255}
    
    -- Determine particle color and count based on type
    if particleType == "drop" then
        particleCount = 10
        -- Use category color if available
        if itemInfo.category then
            particleColor = getCategoryColor(itemInfo.category)
        end
    elseif particleType == "use" then
        particleCount = 15
        particleColor = {50, 200, 50} -- Green for use
    elseif particleType == "combine" then
        particleCount = 20
        particleColor = {50, 150, 255} -- Blue for combine
    end
    
    -- Create particles
    for i = 1, particleCount do
        local particle = {
            x = x + math.random(0, width),
            y = y + math.random(0, height),
            speedX = (math.random() - 0.5) * 3,
            speedY = (math.random() - 0.5) * 3 - 1, -- Slight upward bias
            size = math.random(3, 8),
            color = particleColor,
            alpha = 200 + math.random(0, 55),
            life = math.random(5, 15) / 10, -- 0.5 to 1.5 seconds
            rotation = math.random(0, 360)
        }
        table.insert(Animations.particles, particle)
    end
end

-- Create a drop animation for an item
function createDropAnimation(item, container, col, row)
    local itemInfo = Items[item.id]
    if not itemInfo then return end
    
    local p, headerH, slotSize, slotGap = getGridAndItemMetrics(container)
    local gridX = container.render.x + p
    local gridY = container.render.y + headerH + p - (container.getScroll and container.getScroll() or 0)
    
    -- Calculate target position
    local targetX = gridX + (col - 1) * (slotSize + slotGap)
    local targetY = gridY + (row - 1) * (slotSize + slotGap)
    
    -- Calculate start position (above the target)
    local startX = targetX
    local startY = targetY - 100 -- Start above the target
    
    -- Create the item animation with bounce
    local options = {
        animType = "drop",
        bounceHeight = 40,
        bounceFactor = 0.3,
        startRotation = -30,
        endRotation = 0,
        startScale = 0.7,
        endScale = 1.0
    }
    
    local anim = createItemAnimation(item, startX, startY, targetX, targetY, 150, 255, function()
        -- Create particles when the item lands
        local itemAreaW = itemInfo.w * slotSize + (itemInfo.w - 1) * slotGap
        local itemAreaH = itemInfo.h * slotSize + (itemInfo.h - 1) * slotGap
        createItemParticles(itemInfo, targetX, targetY, itemAreaW, itemAreaH, "drop")
    end, options)
    
    return anim
end

-- Draw all active particles
function drawParticles()
    for _, particle in ipairs(Animations.particles) do
        local color = tocolor(particle.color[1], particle.color[2], particle.color[3], particle.alpha)
        local size = particle.size
        
        -- Draw the particle as a small rectangle or circle
        if particle.size > 5 then
            -- For larger particles, draw as a rotated rectangle
            dxDrawRectangle(particle.x - size/2, particle.y - size/2, size, size, color)
        else
            -- For smaller particles, draw as a simple rectangle
            dxDrawRectangle(particle.x - size/2, particle.y - size/2, size, size, color)
        end
    end
end
