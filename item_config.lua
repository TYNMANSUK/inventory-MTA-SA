-- Item Categories
local CATEGORIES = {
    WEAPON = "weapon",
    AMMO = "ammo",
    FOOD = "food",
    MEDICAL = "medical",
    TOOL = "tool",
    CLOTHING = "clothing",
    MISC = "misc"
}

-- Category Colors
local CATEGORY_COLORS = {
    weapon = {200, 50, 50},   -- Red
    ammo = {200, 150, 50},    -- Orange
    food = {50, 200, 50},     -- Green
    medical = {200, 50, 200}, -- Purple
    tool = {50, 150, 200},    -- Blue
    clothing = {200, 200, 50},-- Yellow
    misc = {150, 150, 150}    -- Gray
}

Items = {
    [1511] = {
        name = "Pájka",
        image = "assets/items/1511.png",
        w = 1,
        h = 1,
        category = CATEGORIES.FOOD,
        description = "Традиционная мясная нарезка. Не испортится даже спустя много лет.",
        durability = 100, -- Максимальная прочность
        current_durability = 85 -- Текущая прочность
    },
    [1415] = {
        name = "Тушёные бобы",
        image = "assets/items/1415.png",
        w = 2,
        h = 2,
        category = CATEGORIES.FOOD,
        description = "Консервированные бобы. Восстанавливают голод.",
        nutrition = 30,
        durability = 100,
        current_durability = 100
    },
    [9999] = { -- Example stackable item
        name = "Трассирующие патроны 7,62х54 мм R",
        image = "assets/items/1804.png",
        w = 1,
        h = 1,
        category = CATEGORIES.AMMO,
        stackable = true,
        max_stack = 30,
        description = "Винтовочный патрон 7,62х54 мм R с пиротехническим зарядом. Используется в некоторых винтовках."
    },
    [2000] = { -- New item with durability
        name = "Охотничий нож",
        image = "assets/items/1511.png", -- Reusing image for now
        w = 1,
        h = 2,
        category = CATEGORIES.WEAPON,
        description = "Универсальный нож для охоты и выживания. Может использоваться как оружие или инструмент.",
        durability = 100,
        current_durability = 45,
        damage = 25
    }
}

-- Export the categories and colors
function getItemCategories()
    return CATEGORIES
end

function getCategoryColor(category)
    return CATEGORY_COLORS[category] or CATEGORY_COLORS.misc
end
