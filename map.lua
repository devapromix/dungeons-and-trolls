local map = {}

function map.load_locations()
    return utils.load_json_file("assets/data/locations.json", "Locations file")
end

function map.get_location_description(symbol)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return { name = location.name, description = location.description }
        end
    end
    return { name = "Unknown", description = "An unknown location." }
end

function map.noise(x, y, scale)
    local seed = 12345
    local value = math.sin(x * scale + seed) * math.cos(y * scale + seed)
    return (value + 1) / 2
end

function map.river_noise(x, y, scale)
    local seed = 54321
    local value = math.sin((x + y) * scale + seed) * math.cos((x - y) * scale + seed)
    return (value + 1) / 2
end

function map.get_biome_effects(symbol)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return location.effects or { thirst = 2, hunger = 0.5, fatigue = 1 }
        end
    end
    return { thirst = 2, hunger = 0.5, fatigue = 1 }
end

function map.initialize_game(locations_data)
    map_data = {
        tiles = {},
        visited = {},
        items = {},
        enemies = {},
        fire = { x = nil, y = nil, active = false }
    }
    
    player = {
        x = math.floor(config.map.width / 2),
        y = math.floor(config.map.height / 2),
        symbol = "@",
        health = 100,
        mana = 100,
        hunger = 0,
        fatigue = 0,
        thirst = 0,
        attack = 5,
        defense = 3,
        alive = true,
        gold = 0,
        inventory = { ["Short Sword"] = 1, ["Leather Armor"] = 1},
        equipment = { weapon = "Short Sword", armor = "Leather Armor" },
        skills = {},
        radius = 3,
        level = 1,
        experience = 0
    }
    
    game_time = {
        year = 1280,
        month = 4,
        day = 1,
        hour = 6,
        minute = 0
    }
    
    for y = 1, config.map.height do
        map_data.tiles[y] = {}
        map_data.visited[y] = {}
        map_data.items[y] = {}
        map_data.enemies[y] = {}
        for x = 1, config.map.width do
            local river_location = nil
            for _, loc in ipairs(locations_data.locations) do
                if loc.symbol == "r" then
                    river_location = loc
                    break
                end
            end
            local river_value = map.river_noise(x, y, river_location.river_noise_scale or 0.05)
            local symbol
            if river_location and river_value < river_location.threshold then
                symbol = "r"
            else
                local selected_location = locations_data.locations[#locations_data.locations]
                for _, loc in ipairs(locations_data.locations) do
                    local noise_value = map.noise(x, y, loc.noise_scale or 0.08)
                    if loc.threshold and noise_value <= loc.threshold then
                        selected_location = loc
                        break
                    end
                end
                symbol = selected_location.symbol
            end
            map_data.tiles[y][x] = symbol
            map_data.visited[y][x] = false
            map_data.items[y][x] = {}
            map_data.enemies[y][x] = {}
            local location_data
            for _, loc in ipairs(locations_data.locations) do
                if loc.symbol == symbol then
                    location_data = loc
                    break
                end
            end
            if location_data and location_data.items then
                for _, item in ipairs(location_data.items) do
                    if math.random() < item.chance then
                        local quantity = math.random(item.quantity[1], item.quantity[2])
                        map_data.items[y][x][item.name] = quantity
                    end
                end
            end
            if location_data and location_data.enemies then
                for _, enemy in ipairs(location_data.enemies) do
                    if math.random() < enemy.chance then
                        local quantity = math.random(enemy.quantity[1], enemy.quantity[2])
                        map_data.enemies[y][x][enemy.name] = quantity
                    end
                end
            end
        end
    end
    
    for y = utils.clamp(player.y - player.radius, 1, config.map.height), utils.clamp(player.y + player.radius, 1, config.map.height) do
        for x = utils.clamp(player.x - player.radius, 1, config.map.width), utils.clamp(player.x + player.radius, 1, config.map.width) do
            if math.sqrt((x - player.x)^2 + (y - player.y)^2) <= player.radius then
                map_data.visited[y][x] = true
            end
        end
    end
end

function map.display_location_and_items(player, map_data)
    local location = map.get_location_description(map_data.tiles[player.y][player.x])
    output.add("You are in " .. location.name .. ". " .. location.description .. "\n")
    local items_string = items.get_tile_items_string(map_data, player.x, player.y)
    output.add(items_string)
    local enemies_string = enemies.get_tile_enemies_string(map_data, player.x, player.y)
    output.add(enemies_string)
    if map_data.fire.active and map_data.fire.x == player.x and map_data.fire.y == player.y then
        output.add("A fire is burning here.\n")
    end
end

return map