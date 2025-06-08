local map = {}

function map.load_locations()
    return utils.load_json_file("assets/data/locations.json", "Locations file")
end

function map.get_location_description(symbol)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return { name = location.name, description = location.description, passable = location.passable }
        end
    end
    return { name = "Unknown", description = "An unknown location.", passable = true }
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

function map.cellular_automaton(tiles, width, height, iterations)
    local new_tiles = {}
    for y = 1, height do
        new_tiles[y] = {}
        for x = 1, width do
            new_tiles[y][x] = tiles[y][x]
        end
    end
    for _ = 1, iterations do
        for y = 1, height do
            for x = 1, width do
                local neighbors = 0
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if dx == 0 and dy == 0 then
                            goto continue
                        end
                        local nx, ny = x + dx, y + dy
                        if nx >= 1 and nx <= width and ny >= 1 and ny <= height and tiles[ny][nx] ~= "o" then
                            neighbors = neighbors + 1
                        end
                        ::continue::
                    end
                end
                if neighbors < 4 then
                    new_tiles[y][x] = "o"
                elseif neighbors >= 5 then
                    new_tiles[y][x] = tiles[y][x]
                end
            end
        end
        for y = 1, height do
            for x = 1, width do
                tiles[y][x] = new_tiles[y][x]
            end
        end
    end
    return tiles
end

function map.initialize_game(locations_data)
    map_data = {
        overworld = {
            tiles = {},
            visited = {},
            items = {},
            enemies = {},
            fire = { x = nil, y = nil, active = false }
        },
        underworld = {
            tiles = {},
            visited = {},
            items = {},
            enemies = {},
            fire = { x = nil, y = nil, active = false }
        }
    }
    
    player = {
        x = math.floor(config.map.width / 2),
        y = math.floor(config.map.height / 2),
        world = "overworld",
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
        inventory = { ["Short Sword"] = 1, ["Leather Armor"] = 1 },
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
    
    local function initialize_world(world, is_underworld)
        for y = 1, config.map.height do
            world.tiles[y] = {}
            world.visited[y] = {}
            world.items[y] = {}
            world.enemies[y] = {}
            for x = 1, config.map.width do
                local symbol
                if is_underworld then
                    local noise_value = map.noise(x, y, 0.1)
                    if noise_value < 0.3 then
                        symbol = "u"
                    elseif noise_value < 0.5 then
                        symbol = "l"
                    elseif noise_value < 0.7 then
                        symbol = "k"
                    elseif noise_value < 0.95 then
                        symbol = "o"
                    else
                        symbol = "#"
                    end
                else
                    local river_location = nil
                    for _, loc in ipairs(locations_data.locations) do
                        if loc.symbol == "r" then
                            river_location = loc
                            break
                        end
                    end
                    local river_value = map.river_noise(x, y, river_location.river_noise_scale or 0.05)
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
                end
                world.tiles[y][x] = symbol
                world.visited[y][x] = false
                world.items[y][x] = {}
                world.enemies[y][x] = {}
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
                            world.items[y][x][item.name] = quantity
                        end
                    end
                end
                if location_data and location_data.enemies then
                    for _, enemy in ipairs(location_data.enemies) do
                        if math.random() < enemy.chance then
                            local quantity = math.random(enemy.quantity[1], enemy.quantity[2])
                            world.enemies[y][x][enemy.name] = quantity
                        end
                    end
                end
            end
        end
        if is_underworld then
            world.tiles = map.cellular_automaton(world.tiles, config.map.width, config.map.height, 3)
        end
    end
    
    initialize_world(map_data.overworld, false)
    initialize_world(map_data.underworld, true)
    
    local center_x, center_y = math.floor(config.map.width / 2), math.floor(config.map.height / 2)
    local portals = {}
    for i = 1, 3 do
        local x, y
        repeat
            x = center_x + math.random(-15, 15)
            y = center_y + math.random(-10, 10)
        until x >= 1 and x <= config.map.width and y >= 1 and y <= config.map.height and not map_data.overworld.tiles[y][x]:match("[><]")
        map_data.overworld.tiles[y][x] = ">"
        map_data.underworld.tiles[y][x] = "<"
        portals[i] = { x = x, y = y }
    end
    
    local troll_x, troll_y
    repeat
        troll_x = center_x + math.random(-20, 20)
        troll_y = center_y + math.random(-20, 20)
        local distance = math.sqrt((troll_x - center_x)^2 + (troll_y - center_y)^2)
    until distance >= 15 and distance <= 20 and troll_x >= 1 and troll_x <= config.map.width and troll_y >= 1 and troll_y <= config.map.height and not map_data.underworld.tiles[troll_y][troll_x]:match("[><]")
    map_data.underworld.tiles[troll_y][troll_x] = "t"
    map_data.underworld.enemies[troll_y][troll_x]["Troll King"] = 1
    
    for y = utils.clamp(player.y - player.radius, 1, config.map.height), utils.clamp(player.y + player.radius, 1, config.map.height) do
        for x = utils.clamp(player.x - player.radius, 1, config.map.width), utils.clamp(player.x + player.radius, 1, config.map.width) do
            if math.sqrt((x - player.x)^2 + (y - player.y)^2) <= player.radius then
                map_data[player.world].visited[y][x] = true
            end
        end
    end
end

function map.move_up(player, map_data)
    if config.debug or map_data[player.world].tiles[player.y][player.x] == "<" then
        player.world = "overworld"
        map.update_visibility(player, map_data)
        return true
    end
    return false
end

function map.move_down(player, map_data)
    if config.debug or map_data[player.world].tiles[player.y][player.x] == ">" then
        player.world = "underworld"
        map.update_visibility(player, map_data)
        return true
    end
    return false
end

function map.update_visibility(player, map_data)
    for y = utils.clamp(player.y - player.radius, 1, config.map.height), utils.clamp(player.y + player.radius, 1, config.map.height) do
        for x = utils.clamp(player.x - player.radius, 1, config.map.width), utils.clamp(player.x + player.radius, 1, config.map.width) do
            if math.sqrt((x - player.x)^2 + (y - player.y)^2) <= player.radius then
                map_data[player.world].visited[y][x] = true
            end
        end
    end
end

function map.display_location(player, map_data)
    local location = map.get_location_description(map_data[player.world].tiles[player.y][player.x])
    output.add("You are in " .. location.name .. ". " .. location.description .. "\n")
    
    local directions = {
        north = {x = player.x, y = player.y - 1, name = "North"},
        south = {x = player.x, y = player.y + 1, name = "South"},
        east = {x = player.x + 1, y = player.y, name = "East"},
        west = {x = player.x - 1, y = player.y, name = "West"}
    }
    
    local visible_directions = {}
    for dir, data in pairs(directions) do
        if data.x >= 1 and data.x <= config.map.width and data.y >= 1 and data.y <= config.map.height then
            local tile_symbol = map_data[player.world].tiles[data.y][data.x]
            local tile_data = map.get_location_description(tile_symbol)
            visible_directions[dir] = tile_data.name
        end
    end
    
    local direction_groups = {}
    for dir, name in pairs(visible_directions) do
        direction_groups[name] = direction_groups[name] or {}
        table.insert(direction_groups[name], directions[dir].name)
    end
    
    local direction_strings = {}
    for biome, dirs in pairs(direction_groups) do
        local dir_names = table.concat(dirs, ", ")
        table.insert(direction_strings, "To " .. dir_names .. " you see " .. biome .. ".")
    end
    
    if #direction_strings > 0 then
        output.add(table.concat(direction_strings, "\n") .. "\n")
    end
    
    local items_string = items.get_tile_items_string(map_data[player.world], player.x, player.y)
    output.add(items_string)
    local enemies_string = enemies.get_tile_enemies_string(map_data[player.world], player.x, player.y)
    output.add(enemies_string)
    if map_data[player.world].fire.active and map_data[player.world].fire.x == player.x and map_data[player.world].fire.y == player.y then
        output.add("A fire is burning here.\n")
    end
end

return map