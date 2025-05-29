local json = require("libraries.json")
local output = require("output")
local items = require("items")

local map = {}

local biomes = {
    { symbol = "f", threshold = 0.15, item_chance = 0.25, enemy_chance = 0.2, effects = { thirst = 2, hunger = 0.5, fatigue = 1 } },
    { symbol = "g", threshold = 0.30, item_chance = 0.20, enemy_chance = 0.2, effects = { thirst = 1.5, hunger = 0.4, fatigue = 0.8 } },
    { symbol = "p", threshold = 0.45, item_chance = 0.15, enemy_chance = 0.2, effects = { thirst = 2.5, hunger = 0.5, fatigue = 1 } },
    { symbol = "s", threshold = 0.60, item_chance = 0.10, enemy_chance = 0.2, effects = { thirst = 3, hunger = 0.5, fatigue = 1 } },
    { symbol = "v", threshold = 0.75, item_chance = 0.08, enemy_chance = 0.2, effects = { thirst = 4, hunger = 0.6, fatigue = 1.2 } },
    { symbol = "d", threshold = 0.85, item_chance = 0.05, enemy_chance = 0.2, effects = { thirst = 5, hunger = 0.8, fatigue = 1.5 } },
    { symbol = "m", threshold = 1.0, item_chance = 0.08, enemy_chance = 0.2, effects = { thirst = 2.5, hunger = 0.6, fatigue = 2 } },
    { symbol = "r", item_chance = 0.3, enemy_chance = 0, effects = { thirst = -3, hunger = 0.5, fatigue = 1.2 } }
}

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
    for _, biome in ipairs(biomes) do
        if biome.symbol == symbol then
            return biome.effects
        end
    end
    return { thirst = 2, hunger = 0.5, fatigue = 1 }
end

function map.initialize_game()
    map_data = {
        tiles = {},
        visited = {},
        items = {},
        enemies = {}
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
        attack = 0,
        defense = 0,
        alive = true,
        gold = 0,
        inventory = {},
        equipment = { weapon = nil, armor = nil },
        radius = 3
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
    
    for y = 1, config.map.height do
        map_data.tiles[y] = {}
        map_data.visited[y] = {}
        map_data.items[y] = {}
        map_data.enemies[y] = {}
        for x = 1, config.map.width do
            local river_value = map.river_noise(x, y, river_scale)
            local symbol
            if river_value < 0.1 then
                symbol = "r"
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
            map_data.enemies[y][x] = {}
            local item_chance = symbol == "r" and 0.3 or (biomes[symbol] and biomes[symbol].item_chance or 0.1)
            if items_data.items and #items_data.items > 0 and math.random() < item_chance then
                local item = items_data.items[math.random(1, #items_data.items)]
                local quantity = math.random(1, 3)
                map_data.items[y][x][item.name] = quantity
            end
            local enemy_chance = symbol == "r" and 0 or (biomes[symbol] and biomes[symbol].enemy_chance or 0.2)
            if enemies_data.enemies and #enemies_data.enemies > 0 and math.random() < enemy_chance then
                local enemy = enemies_data.enemies[math.random(1, #enemies_data.enemies)]
                local quantity = math.random(1, 3)
                map_data.enemies[y][x][enemy.name] = quantity
            end
        end
    end
    
    for y = math.max(1, player.y - player.radius), math.min(config.map.height, player.y + player.radius) do
        for x = math.max(1, player.x - player.radius), math.min(config.map.width, player.x + player.radius) do
            if math.sqrt((x - player.x)^2 + (y - player.y)^2) <= player.radius then
                map_data.visited[y][x] = true
            end
        end
    end
    
    output.clear()
    output.add("Welcome to " .. config.game.name .. " v." .. config.game.version .. "\n")
end

return map