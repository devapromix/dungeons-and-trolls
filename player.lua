local json = require("libraries.json")
local output = require("output")
local time = require("time")
local items = require("items")

local player = {}

-- Initialize a new player
function player.initialize()
    return {
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
end

-- Check player's vital stats and return status message
function player.check_status(player_data)
    player_data.hunger = math.min(100, math.max(0, player_data.hunger))
    player_data.fatigue = math.min(100, math.max(0, player_data.fatigue))
    player_data.health = math.min(100, math.max(0, player_data.health))
    player_data.thirst = math.min(100, math.max(0, player_data.thirst))
    
    if player_data.hunger >= 100 then
        player_data.hunger = 100
        player_data.alive = false
        return "You died from starvation.\n"
    elseif player_data.fatigue >= 100 then
        player_data.fatigue = 100
        player_data.alive = false
        return "You died from exhaustion.\n"
    elseif player_data.health <= 0 then
        player_data.health = 0
        player_data.alive = false
        return "You died from your injuries.\n"
    elseif player_data.thirst >= 100 then
        player_data.thirst = 100
        player_data.alive = false
        return "You died from thirst.\n"
    end
    return ""
end

-- Move player in the given direction
function player.move(player_data, map, direction, locations_data)
    if not player_data.alive then
        output.clear()
        output.add("You are DEAD and cannot move.\n\nStart a new game with the 'new' command.\n")
        return false
    end
    
    local moves = {
        north = {y = -1, x_min = 1, x_max = config.map.width, y_min = 2, y_max = config.map.height, dir = "north"},
        south = {y = 1, x_min = 1, x_max = config.map.width, y_min = 1, y_max = config.map.height - 1, dir = "south"},
        east = {x = 1, x_min = 1, x_max = config.map.width - 1, y_min = 1, y_max = config.map.height, dir = "east"},
        west = {x = -1, x_min = 2, x_max = config.map.width, y_min = 1, y_max = config.map.height, dir = "west"}
    }
    
    local move = moves[direction]
    if not move then return false end
    
    local new_x = player_data.x + (move.x or 0)
    local new_y = player_data.y + (move.y or 0)
    
    if new_x >= move.x_min and new_x <= move.x_max and new_y >= move.y_min and new_y <= move.y_max then
        player_data.x = new_x
        player_data.y = new_y
        map.visited[player_data.y][player_data.x] = true
        output.clear()
        output.add("You moved " .. move.dir .. ".\n")
        
        -- Get the location description
        local location_desc = player.get_location_description(map.tiles[player_data.y][player_data.x], locations_data)
        output.add(location_desc .. "\n")
        
        local items_string = items.get_tile_items_string(map, player_data.x, player_data.y)
        output.add(items_string)
        
        time.tick_time(120)
        player_data.fatigue = math.min(100, math.max(0, player_data.fatigue + (player_data.mana <= 0 and 2 or 1)))
        player_data.hunger = math.min(100, math.max(0, player_data.hunger + 0.5))
        player_data.thirst = math.min(100, math.max(0, player_data.thirst + 2))
        
        local status_message = player.check_status(player_data)
        if status_message ~= "" then
            output.add(status_message)
        end
        return true
    else
        output.clear()
        output.add("You can't move further " .. move.dir .. ".\n")
        return false
    end
end

-- Get the description of a location based on its symbol
function player.get_location_description(symbol, locations_data)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return location.description
        end
    end
    return "An unknown location."
end

-- Rest to restore player stats
function player.rest(player_data, game_time)
    output.clear()
    if not player_data.alive then
        output.add("You are DEAD and cannot rest.\nStart a new game with the 'new' command.\n")
    elseif player_data.health >= 100 and player_data.mana >= 100 and player_data.fatigue <= 0 then
        output.add("You don't need to rest.\n")
    else
        local hours_to_full = math.max(
            math.ceil((100 - player_data.health) / 10),
            math.ceil((100 - player_data.mana) / 10),
            math.ceil(player_data.fatigue / 10)
        )
        local hours_to_morning = 0
        if game_time.hour >= 18 then
            hours_to_morning = (24 - game_time.hour) + 6
        elseif game_time.hour < 6 then
            hours_to_morning = 6 - game_time.hour
        end
        local rest_hours = hours_to_full
        if hours_to_morning > 0 then
            rest_hours = math.min(hours_to_full, hours_to_morning)
        end
        
        output.add("You rest for " .. rest_hours .. " hour(s)...\n")
        player_data.health = math.min(100, math.max(0, player_data.health + rest_hours * 10))
        player_data.mana = math.min(100, math.max(0, player_data.mana + rest_hours * 10))
        player_data.fatigue = math.min(100, math.max(0, player_data.fatigue - rest_hours * 10))
        player_data.hunger = math.min(100, math.max(0, player_data.hunger + rest_hours * 0.5))
        player_data.thirst = math.min(100, math.max(0, player_data.thirst + rest_hours * 5))
        time.tick_time(rest_hours * 60)
        
        output.add("Your health, mana, and fatigue have been restored.\n")
        if rest_hours > 0 then
            output.add("You feel hungrier and thirstier.\n")
        end
        
        local status_message = player.check_status(player_data)
        if status_message ~= "" then
            output.add(status_message)
        end
    end
end

-- Display player status
function player.show_status(player_data)
    output.clear()
    output.add("Health: " .. player_data.health .. "\n")
    output.add("Mana: " .. player_data.mana .. "\n")
    output.add("Hunger: " .. player_data.hunger .. "\n")
    output.add("Fatigue: " .. player_data.fatigue .. "\n")
    output.add("Thirst: " .. player_data.thirst .. "\n")
    output.add("Position: " .. player_data.x .. ", " .. player_data.y .. "\n")
    
    if not player_data.alive then
        output.add("\nYou are DEAD.\nUse 'new' command to start a new game.\n")
    end
end

-- Show player inventory
function player.show_inventory(player_data)
    output.clear()
    if not player_data.alive then
        output.add("You are dead and cannot check your inventory.\nStart a new game with the 'new' command.\n")
    else
        output.add("Inventory (" .. player.count_inventory_items(player_data.inventory) .. "/" .. config.inventory.max_slots .. "):\n")
        if next(player_data.inventory) == nil then
            output.add("(empty)\n")
        else
            for item, quantity in pairs(player_data.inventory) do
                if quantity > 1 then
                    output.add(item .. " (" .. quantity .. ")\n")
                else
                    output.add(item .. "\n")
                end
            end
        end
        output.add("Gold: " .. player_data.gold .. "\n")
    end
end

-- Helper function to count inventory items
function player.count_inventory_items(inventory)
    local count = 0
    for _ in pairs(inventory) do
        count = count + 1
    end
    return count
end

-- Look at current location
function player.look(player_data, map, locations_data)
    output.clear()
    if not player_data.alive then
        output.add("You are dead and cannot look around.\nStart a new game with the 'new' command.\n")
    else
        local location_desc = player.get_location_description(map.tiles[player_data.y][player_data.x], locations_data)
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player_data.x, player_data.y)
        output.add(items_string)
    end
end

return player