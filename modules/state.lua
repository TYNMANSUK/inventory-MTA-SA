-- State management for Inventory System

screenW, screenH = guiGetScreenSize()

inventoryOpen = false

InventoryRegistry = {}
DragDrop = {
    isDragging = false,
    isSplitting = false,
    item = nil,
    splitSourceItem = nil,
    offsetX = 0, offsetY = 0,
    originalSource = nil,
    originalX = 0, originalY = 0,
    dropTarget = nil,
}
ContextMenu = {
    isOpen = false,
    item = nil,
    x = 0, y = 0,
    w = 150, h = 0,
    options = {},
    hoveredOption = nil,
}
Animations = {
    items = {},
    moveSpeed = 15,
    fadeSpeed = 0.08,
    hoverEffects = {},
    dropEffects = {},
    particles = {},
}
Tooltip = {
    item = nil,
    x = 0, y = 0,
    padding = 12,
    maxWidth = 280,
    backgroundColor = tocolor(0, 0, 0, 230),
    borderColor = tocolor(100, 100, 100, 255),
    textColor = tocolor(255, 255, 255, 255),
    titleColor = tocolor(255, 255, 255, 255)
}

Scroll = {
    vicinity = 0, targetVicinity = 0,
    inventory = 0, targetInventory = 0,
    speed = 0.2,
}

Fonts = {} -- This will hold our font elements
RenderTargets = {
    inventory = nil,
    vicinity = nil,
    needsUpdate = {}
}

Panels = {}

COLORS = {
    background = tocolor(0, 0, 0, 200), panel = tocolor(24, 24, 24, 220),
    header = tocolor(18, 18, 18, 230), slot = tocolor(44, 44, 44, 255),
    text_light = tocolor(220, 220, 220, 255), text_dark = tocolor(120, 120, 120, 255),
    dot_green = tocolor(106, 176, 76, 255), dot_red = tocolor(231, 76, 60, 255),
    drop_valid = tocolor(0, 255, 0, 70), drop_invalid = tocolor(255, 0, 0, 70),
}

totalW, totalH = 1150, 750
startX, startY = (screenW - totalW) / 2, (screenH - totalH) / 2
panelGap, panelW = 5, (totalW - 5 * 2) / 3

function initializeInventories()
    outputChatBox("DEBUG: Initializing inventories...")
    InventoryRegistry = {}

    InventoryRegistry.vicinity = Container:new("vicinity", "VICINITY", 6, 11)
    InventoryRegistry.vicinity.render = { x = startX, y = startY, w = panelW, h = totalH, isPanel = true }
    InventoryRegistry.vicinity.getScroll = function() return Scroll.vicinity end

    InventoryRegistry.jacket = Container:new("jacket", "TTSKO JACKET", 4, 2)
    InventoryRegistry.vest = Container:new("vest", "TACTICAL VEST", 4, 2)
    InventoryRegistry.pants = Container:new("pants", "CANVAS PANTS SHORT", 4, 2)
    InventoryRegistry.belt = Container:new("belt", "UNDER BELT", 6, 1)
    InventoryRegistry.backpack = Container:new("backpack", "HUNTING BACKPACK", 6, 4)
    
    -- Add test items
    InventoryRegistry.vicinity:addItem({ id = 1415, x = 2, y = 2 })
    InventoryRegistry.vicinity:addItem({ id = 1511, x = 5, y = 3 })
    InventoryRegistry.vicinity:addItem({ id = 9999, x = 1, y = 1, count = 15 })
    InventoryRegistry.vicinity:addItem({ id = 9999, x = 2, y = 1, count = 20 })
    InventoryRegistry.vicinity:addItem({ id = 2000, x = 4, y = 1 })

    -- Create Panel Objects
    Panels.vicinity = VicinityPanel:new(startX, startY, panelW, totalH, InventoryRegistry.vicinity)
    
    local playerContainers = {
        InventoryRegistry.jacket,
        InventoryRegistry.vest,
        InventoryRegistry.pants,
        InventoryRegistry.belt,
        InventoryRegistry.backpack
    }
    Panels.player = PlayerInventoryPanel:new(startX + (panelW + panelGap) * 2, startY, panelW, totalH, playerContainers)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    initializeInventories()
    createFonts()
end)
