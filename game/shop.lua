local shop = {}

local interiors_cache = nil
local items_cache = nil

function shop.load_interiors()
    if not interiors_cache then
        interiors_cache = utils.load_json_file("assets/data/interiors.json", "Interiors file")
    end
    return interiors_cache
end

local function load_items()
    if not items_cache then
        items_cache = items.load_items()
    end
    return items_cache
end

local function find_interior(shop_type)
    local interiors_data = shop.load_interiors()
    for _, interior in ipairs(interiors_data.interiors or {}) do
        if interior.id == shop_type then
            return interior
        end
    end
    return nil
end

function shop.display_interior(shop_type, player)
    local interior = find_interior(shop_type)
    
    if not interior then
        output.add("Unknown building: " .. shop_type .. "\n")
        return
    end
    
    output.add(interior.name .. "\n")
    
    if interior.description and interior.description ~= "" then
        output.add(interior.description .. "\n")
    end
    
    if interior.id ~= "" then
        local items_data = load_items()
        output.add(shop.get_items_string(items_data, shop_type, player.level))
    end
    
    output.add("\n")
end

local function create_shop_items(items_data, shop_type, player_level)
    local shop_items = {}
    
    for _, item in ipairs(items_data.items) do
        local item_level = nil
        local price = nil
        local is_shop_item = false
        
        for _, tag in ipairs(item.tags) do
            if tag == shop_type then
                is_shop_item = true
            elseif tag:match("^level=") then
                item_level = tonumber(tag:match("^level=(%d+)"))
            elseif tag:match("^price=") then
                price = tonumber(tag:match("^price=(%d+)"))
            end
        end
        
        if is_shop_item and price then
            if shop_type == "tavern" or not item_level or item_level <= player_level then
                table.insert(shop_items, { name = item.name, price = price })
            end
        end
    end
    
    return shop_items
end

local function select_random_items(shop_items, max_count)
    local selected_items = {}
    local available_items = {}
    
    for i, item in ipairs(shop_items) do
        available_items[i] = item
    end
    
    local count = math.min(max_count or 4, #available_items)
    
    for i = 1, count do
        if #available_items == 0 then break end
        
        local index = math.random(1, #available_items)
        table.insert(selected_items, available_items[index])
        table.remove(available_items, index)
    end
    
    return selected_items
end

local function format_items_list(selected_items, shop_type)
    if #selected_items == 0 then
        return ""
    end
    
    local item_list = {}
    for _, item in ipairs(selected_items) do
        table.insert(item_list, item.name .. " (" .. item.price .. ")")
    end
    
    local items_string = table.concat(item_list, ", ")
    local greeting = "The shopkeeper presents their wares:"
    
    local interior = find_interior(shop_type)
    if interior and interior.greeting and interior.greeting ~= "" then
        greeting = interior.greeting
    end
    
    return "\n" .. greeting .. " " .. items_string .. ".\n"
end

function shop.get_items_string(items_data, shop_type, player_level)
    if not game.shop_items_cache then
        game.shop_items_cache = {}
    end
    
    if game.shop_items_cache[shop_type] then
        return format_items_list(game.shop_items_cache[shop_type], shop_type)
    end
    
    local shop_items = create_shop_items(items_data, shop_type, player_level)
    local selected_items = select_random_items(shop_items, 4)
    
    game.shop_items_cache[shop_type] = selected_items
    
    return format_items_list(selected_items, shop_type)
end

function shop.reset_items()
    game.shop_items_cache = {}
end

function shop.clear_cache()
    interiors_cache = nil
    items_cache = nil
    game.shop_items_cache = {}
end

return shop