-- MAP

local map = {}

function map.load_locations()
    local locations_file = "assets/data/locations.json"
    if love.filesystem.getInfo(locations_file) then
        local content = love.filesystem.read(locations_file)
        if content then
            return json.decode(content)
        else
            output.add("Failed to read locations file.\n")
            return { locations = {} }
        end
    else
        output.add("Locations file not found.\n")
        return { locations = {} }
    end
end

function map.get_location_description(symbol)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return location.description
        end
    end
    return "An unknown location."
end

function map.initialize_game()
    map_data = {
        tiles = {},
        visited = {},
        items = {}
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
        alive = true,
        gold = 0,
        inventory = {}
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
        for x = 1, config.map.width do
            map_data.tiles[y][x] = math.random() < 0.7 and "s" or "f"
            map_data.visited[y][x] = false
            map_data.items[y][x] = {}
            if items_data.items and #items_data.items > 0 and math.random() < 0.1 then
                local item = items_data.items[math.random(1, #items_data.items)]
                local quantity = math.random(1, 3)
                map_data.items[y][x][item.name] = quantity
            end
        end
    end
    
    map_data.visited[player.y][player.x] = true
    input.history = {}
    input.history_index = 0
    output.clear()
    output.add("Welcome to " .. config.game.name .. " v." .. config.game.version .. "\n")
end

return map