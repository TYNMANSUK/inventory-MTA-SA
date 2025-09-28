local screenW, screenH = guiGetScreenSize()
local inventoryOpen = false

local InventoryRegistry = {}
local DragDrop = {
    isDragging = false,
    isSplitting = false,
    item = nil,
    splitSourceItem = nil,
    offsetX = 0, offsetY = 0,
    originalSource = nil,
    originalX = 0, originalY = 0,
    dropTarget = nil,
}
local ContextMenu = {
    isOpen = false,
    item = nil,
    x = 0, y = 0,
    w = 150, h = 0,
    options = {},
    hoveredOption = nil,
}
local Animations = {
    items = {},
    moveSpeed = 15,
    fadeSpeed = 0.08,
    hoverEffects = {},
    dropEffects = {},
    particles = {},
}
local Tooltip = {
    item = nil,
    x = 0, y = 0,
    padding = 12,
    maxWidth = 280,
    backgroundColor = tocolor(0, 0, 0, 230),
    borderColor = tocolor(100, 100, 100, 255),
    textColor = tocolor(255, 255, 255, 255),
    titleColor = tocolor(255, 255, 255, 255)
}

local Scroll = {
    vicinity = 0, targetVicinity = 0,
    inventory = 0, targetInventory = 0,
    speed = 0.2,
}

local FONT_SIZE, FONT = 0.8, "default-bold"
local COLORS = {
    background = tocolor(0, 0, 0, 200), panel = tocolor(24, 24, 24, 220),
    header = tocolor(18, 18, 18, 230), slot = tocolor(44, 44, 44, 255),
    text_light = tocolor(220, 220, 220, 255), text_dark = tocolor(120, 120, 120, 255),
    dot_green = tocolor(106, 176, 76, 255), dot_red = tocolor(231, 76, 60, 255),
    drop_valid = tocolor(0, 255, 0, 70), drop_invalid = tocolor(255, 0, 0, 70),
}

local totalW, totalH = 1150, 750
local startX, startY = (screenW - totalW) / 2, (screenH - totalH) / 2
local panelGap, panelW = 5, (totalW - 5 * 2) / 3

-- Make sure renderMain is available before binding
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Wait a frame to make sure all resources are loaded
    setTimer(function()
        bindKey("i", "down", toggleInventory)
        bindKey("tab", "down", toggleInventory)
    end, 50, 1)
end)
