local enemies = {}

function enemies.load_enemies()
    return utils.load_json_file("assets/data/enemies.json", "Enemies file")
end

function enemies.get_tile_enemies_string(map_data, x, y)
    local enemy_list = map_data.enemies[y][x]
    if not enemy_list or next(enemy_list) == nil then
        return ""
    end
    local enemies_string = "\nYou see enemies: "
    local enemies = {}
    for name, quantity in pairs(enemy_list) do
        if quantity > 1 then
            table.insert(enemies, name .. " (" .. quantity .. ")")
        else
            table.insert(enemies, name)
        end
    end
    enemies_string = enemies_string .. table.concat(enemies, ", ") .. ".\n"
    return enemies_string
end

function enemies.get_enemy_data(enemies_data, enemy_name)
    if not enemies_data or not enemies_data.enemies or not enemy_name then return nil end
    for _, enemy in ipairs(enemies_data.enemies) do
        if enemy.name == enemy_name then
            return enemy
        end
    end
    return nil
end

return enemies