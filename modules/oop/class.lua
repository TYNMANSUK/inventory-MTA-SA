-- Simple class implementation
function class(base)
    local new_class = {}
    new_class.__index = new_class

    function new_class:new(...)
        local instance = setmetatable({}, new_class)
        if instance.constructor then
            instance:constructor(...)
        end
        return instance
    end

    if base then
        setmetatable(new_class, { __index = base })
    end

    return new_class
end
