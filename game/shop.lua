local shop = {}

function shop.load_interiors()
    return utils.load_json_file("assets/data/interiors.json", "Interiors file")
end

function shop.display_interior(building_id, player)
    local interiors_data = shop.load_interiors()
    for _, interior in ipairs(interiors_data.interiors or {}) do
        if interior.id == building_id then
            output.add(interior.name .. "\n")
            if interior.description and interior.description ~= "" then
                output.add(interior.description .. "\n")
            end
            if interior.id ~= "" then
                local items_data = items.load_items()
                output.add(shop.get_items_string(items_data, interior.id, player.level))
            end
            output.add("\n")
            return
        end
    end
    output.add("Unknown building: " .. building_id .. "\n")
end

function shop.get_items_string(items_data, shop_type, player_level)
    local shop_items = {}
    for _, item in ipairs(items_data.items) do
        local item_level = nil
        local price = nil
        local is_shop_item = false
        for _, tag in ipairs(item.tags) do
            if tag == shop_type then
                is_shop_item = true
            end
            if tag:match("^level=") then
                item_level = tonumber(tag:match("^level=(%d+)"))
            end
            if tag:match("^price=") then
                price = tonumber(tag:match("^price=(%d+)"))
            end
        end
        if is_shop_item and price then
            if shop_type == "tavern" or not item_level or (item_level and item_level <= player_level) then
                table.insert(shop_items, { name = item.name, price = price })
            end
        end
    end
    local selected_items = {}
    local count = math.min(3, #shop_items)
    for i = 1, count do
        if #shop_items == 0 then break end
        local index = math.random(1, #shop_items)
        table.insert(selected_items, shop_items[index])
        table.remove(shop_items, index)
    end
    local item_list = {}
    for _, item in ipairs(selected_items) do
        table.insert(item_list, item.name .. " (" .. item.price .. ")")
    end
    local str = table.concat(item_list, ", ")
    if str ~= "" then
        return "\nThe shopkeeper's gaze follows you as you examine his goods: " .. str .. ".\n"
    end
    return ""
end

return shop