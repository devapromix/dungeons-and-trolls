local json = require("libraries.json")
local output = require("output")
local items = require("items")

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
    
    local scale = 0.08
    local river_scale = 0.05
    local biomes = {
        { symbol = "f", threshold = 0.15, item_chance = 0.25, effects = { thirst = 2, hunger = 0.5, fatigue = 1 } }, -- forest
        { symbol = "g", threshold = 0.30, item_chance = 0.20, effects = { thirst = 1.5, hunger = 0.4, fatigue = 0.8 } }, -- grassland
        { symbol = "p", threshold = 0.45, item_chance = 0.15, effects = { thirst = 2.5, hunger = 0.5, fatigue = 1 } }, -- plain
        { symbol = "s", threshold = 0.60, item_chance = 0.10, effects = { thirst = 3, hunger = 0.5, fatigue = 1 } }, -- steppe
        { symbol = "v", threshold = 0.75, item_chance = 0.08, effects = { thirst = 4, hunger = 0.6, fatigue = 1.2 } }, -- savanna
        { symbol = "d", threshold = 0.85, item_chance = 0.05, effects = { thirst = 5, hunger = 0.8, fatigue = 1.5 } }, -- desert
        { symbol = "m", threshold = 1.0, item_chance = 0.08, effects = { thirst = 2.5, hunger = 0.6, fatigue = 2 } } -- mountain
    }
    
    for y = 1, config.map.height do
        map_data.tiles[y] = {}
        map_data.visited[y] = {}
        map_data.items[y] = {}
        for x = 1, config.map.width do
            local river_value = map.river_noise(x, y, river_scale)
            local symbol
            if river_value < 0.1 then
                symbol = "r" -- river
            else
                local noise_value = map.noise(x, y, scale)
                local biome = biomes[#biomes]
                for _, b in ipairs(biomes) do
                    if noise_value <= b.threshold then
                        biome = b
                        break
                    end
                end
                symbol = biome.symbol
            end
            map_data.tiles[y][x] = symbol
            map_data.visited[y][x] = false
            map_data.items[y][x] = {}
            local item_chance = symbol == "r" and 0.3 or (biomes[symbol] and biomes[symbol].item_chance or 0.1)
            if items_data.items and #items_data.items > 0 and math.random() < item_chance then
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