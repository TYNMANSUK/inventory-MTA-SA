Container = class()

function Container:constructor(id, label, cols, rows)
    self.id = id
    self.label = label
    self.grid = { cols = cols, rows = rows }
    self.items = {}
    self.render = {}
end

function Container:addItem(item)
    table.insert(self.items, item)
    -- TODO: Add logic to find a free spot
end

function Container:removeItem(item)
    for i, existingItem in ipairs(self.items) do
        if existingItem == item then
            table.remove(self.items, i)
            return true
        end
    end
    return false
end

function Container:getItemAt(col, row)
    for _, item in ipairs(self.items) do
        local itemInfo = Items[item.id]
        if col >= item.x and col < item.x + itemInfo.w and
           row >= item.y and row < item.y + itemInfo.h then
            return item
        end
    end
    return nil
end
