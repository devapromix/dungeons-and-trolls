json = require("libraries.json")
output = require("output")
time = require("time")
items = require("items")

function love.load()
    input = {
        text = ">",
        x = 5,
        y = love.graphics.getHeight() - 40,
        width = love.graphics.getWidth() - 10,
        height = 30,
        font = love.graphics.newFont(16),
        cursor_visible = true,
        cursor_timer = 0,
        cursor_blink_speed = 0.5,
        history = {},
        history_index = 0
    }
    
    items_data = items.load_items()
    locations_data = load_locations()
    initialize_game()
    
    if love.filesystem.getInfo("game.json") then
        load_game_from_json()
        output.add("Loaded saved game.\n")
        local location_desc = get_location_description(map.tiles[player.y][player.x])
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player.x, player.y)
        output.add(items_string)
    else
        output.add("Created new game.\n")
        local location_desc = get_location_description(map.tiles[player.y][player.x])
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player.x, player.y)
        output.add(items_string)
    end
end

function load_locations()
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

function get_location_description(symbol)
    for _, location in ipairs(locations_data.locations or {}) do
        if location.symbol == symbol then
            return location.description
        end
    end
    return "An unknown location."
end

function initialize_game()
    map = {
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
        inventory = {
            ["Apple"] = 5,
            ["Sword"] = 1,
            ["Potion"] = 3,
            ["Rope"] = 2,
            ["Shield"] = 1
        }
    }
    
    game_time = {
        year = 1280,
        month = 4,
        day = 1,
        hour = 6,
        minute = 0
    }
    
    for y = 1, config.map.height do
        map.tiles[y] = {}
        map.visited[y] = {}
        map.items[y] = {}
        for x = 1, config.map.width do
            map.tiles[y][x] = math.random() < 0.7 and "s" or "f"
            map.visited[y][x] = false
            map.items[y][x] = {}
        end
    end
    
    map.visited[player.y][player.x] = true
    input.history = {}
    input.history_index = 0
    output.clear()
end

function save_game_to_json()
    local save_data = {
        map = map,
        player = player,
        history = input.history,
        time = game_time
    }
    
    local save_string = json.encode(save_data)
    love.filesystem.write("game.json", save_string)
end

function load_game_from_json()
    local save_string = love.filesystem.read("game.json")
    if save_string then
        local save_data = json.decode(save_string)
        if save_data then
            map = save_data.map
            player = save_data.player
            game_time = save_data.time or { year = 1280, month = 4, day = 1, hour = 6, minute = 0 }
            input.history = save_data.history or {}
            
            player.health = math.min(100, math.max(0, player.health))
            player.mana = math.min(100, math.max(0, player.mana))
            player.hunger = math.min(100, math.max(0, player.hunger or 0))
            player.fatigue = math.min(100, math.max(0, player.fatigue or 0))
            player.thirst = math.min(100, math.max(0, player.thirst or 0))
            player.gold = math.max(0, player.gold or 0)
            player.inventory = player.inventory or {}
            
            if player.alive == nil then
                player.alive = (player.hunger < 100 and player.fatigue < 100 and player.health > 0 and player.thirst < 100)
            end
            for y = 1, config.map.height do
                map.items[y] = map.items[y] or {}
                for x = 1, config.map.width do
                    map.items[y][x] = map.items[y][x] or {}
                end
            end
        end
    end
end

function check_player_status()
    player.hunger = math.min(100, math.max(0, player.hunger))
    player.fatigue = math.min(100, math.max(0, player.fatigue))
    player.health = math.min(100, math.max(0, player.health))
    player.thirst = math.min(100, math.max(0, player.thirst))
    
    if player.hunger >= 100 then
        player.hunger = 100
        player.alive = false
        return "You died from starvation.\n"
    elseif player.fatigue >= 100 then
        player.fatigue = 100
        player.alive = false
        return "You died from exhaustion.\n"
    elseif player.health <= 0 then
        player.health = 0
        player.alive = false
        return "You died from your injuries.\n"
    elseif player.thirst >= 100 then
        player.thirst = 100
        player.alive = false
        return "You died from thirst.\n"
    end
    return ""
end

function move_player(direction)
    if not player.alive then
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
    
    local new_x = player.x + (move.x or 0)
    local new_y = player.y + (move.y or 0)
    
    if new_x >= move.x_min and new_x <= move.x_max and new_y >= move.y_min and new_y <= move.y_max then
        player.x = new_x
        player.y = new_y
        map.visited[player.y][player.x] = true
        output.clear()
        output.add("You moved " .. move.dir .. ".\n")
        local location_desc = get_location_description(map.tiles[player.y][player.x])
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player.x, player.y)
        output.add(items_string)
        
        time.tick_time(120)
        player.fatigue = math.min(100, math.max(0, player.fatigue + (player.mana <= 0 and 2 or 1)))
        player.hunger = math.min(100, math.max(0, player.hunger + 0.5))
        player.thirst = math.min(100, math.max(0, player.thirst + 2))
        
        local status_message = check_player_status()
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

function love.update(dt)
    input.cursor_timer = input.cursor_timer + dt
    if input.cursor_timer >= input.cursor_blink_speed then
        input.cursor_visible = not input.cursor_visible
        input.cursor_timer = 0
    end
end

function love.textinput(t)
    input.text = input.text .. t
    input.history_index = 0
end

function love.keypressed(key)
    if key == "backspace" and #input.text > 1 then
        input.text = input.text:sub(1, -2)
        input.history_index = 0
    end
    if key == "return" and #input.text > 1 then
        local command = input.text:sub(2)
        local command_parts = {}
        for part in command:gmatch("%S+") do
            table.insert(command_parts, part)
        end
        
        if command_parts[1] == "help" then
            output.clear()
            
            if love.filesystem.getInfo("assets/data/help.txt") then
                local content = love.filesystem.read("assets/data/help.txt")
                if content then
                    output.add(content)
                else
                    output.add("Failed to read help file.\n")
                end
            else
                output.add("Help file not found.\n")
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "new" then
            output.clear()
            output.add("Starting a new game...\n")
            initialize_game()
            output.add("New game initialized.\n")
            local location_desc = get_location_description(map.tiles[player.y][player.x])
            output.add(location_desc .. "\n")
            local items_string = items.get_tile_items_string(map, player.x, player.y)
            output.add(items_string)
            output.add("Type 'map' to see the map.\n")
        elseif command_parts[1] == "save" then
            save_game_to_json()
            output.clear()
            output.add("Game saved.\n")
        elseif command_parts[1] == "load" then
            output.clear()
            if love.filesystem.getInfo("game.json") then
                load_game_from_json()
                output.add("Game loaded.\n")
                local location_desc = get_location_description(map.tiles[player.y][player.x])
                output.add(location_desc .. "\n")
                local items_string = items.get_tile_items_string(map, player.x, player.y)
                output.add(items_string)
            else
                output.add("No saved game found.\n")
            end
        elseif command_parts[1] == "status" then
            output.clear()
            output.add("Health: " .. player.health .. "\n")
            output.add("Mana: " .. player.mana .. "\n")
            output.add("Hunger: " .. player.hunger .. "\n")
            output.add("Fatigue: " .. player.fatigue .. "\n")
            output.add("Thirst: " .. player.thirst .. "\n")
            output.add("Position: " .. player.x .. ", " .. player.y .. "\n")
            
            if not player.alive then
                output.add("\nYou are DEAD.\nUse 'new' command to start a new game.\n")
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "time" then
            output.clear()
            output.add("Time: " .. game_time.year .. "/" .. game_time.month .. "/" .. game_time.day .. " " .. string.format("%02d:%02d", game_time.hour, game_time.minute) .. " (" .. (game_time.hour >= 6 and game_time.hour < 18 and "Day" or "Night") .. ")\n")
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "rest" then
            output.clear()
            if not player.alive then
                output.add("You are DEAD and cannot rest.\nStart a new game with the 'new' command.\n")
            elseif player.health >= 100 and player.mana >= 100 and player.fatigue <= 0 then
                output.add("You don't need to rest.\n")
            else
                local hours_to_full = math.max(
                    math.ceil((100 - player.health) / 10),
                    math.ceil((100 - player.mana) / 10),
                    math.ceil(player.fatigue / 10)
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
                player.health = math.min(100, math.max(0, player.health + rest_hours * 10))
                player.mana = math.min(100, math.max(0, player.mana + rest_hours * 10))
                player.fatigue = math.min(100, math.max(0, player.fatigue - rest_hours * 10))
                player.hunger = math.min(100, math.max(0, player.hunger + rest_hours * 0.5))
                player.thirst = math.min(100, math.max(0, player.thirst + rest_hours * 5))
                time.tick_time(rest_hours * 60)
                
                output.add("Your health, mana, and fatigue have been restored.\n")
                if rest_hours > 0 then
                    output.add("You feel hungrier and thirstier.\n")
                end
                
                local status_message = check_player_status()
                if status_message ~= "" then
                    output.add(status_message)
                end
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "eat" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify an item to eat.\n")
            else
                local item_name = table.concat(command_parts, " ", 2)
                player = items.eat_item(player, items_data, item_name) or player
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "drink" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify an item to drink.\n")
            else
                local item_name = table.concat(command_parts, " ", 2)
                player = items.drink_item(player, items_data, item_name) or player
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "items" then
            output.clear()
            if not player.alive then
                output.add("You are dead and cannot check your inventory.\nStart a new game with the 'new' command.\n")
            else
                output.add("Inventory (" .. table_count(player.inventory) .. "/" .. config.inventory.max_slots .. "):\n")
                if next(player.inventory) == nil then
                    output.add("(empty)\n")
                else
                    for item, quantity in pairs(player.inventory) do
                        if quantity > 1 then
                            output.add("  " .. item .. " (" .. quantity .. ")\n")
                        else
                            output.add("  " .. item .. "\n")
                        end
                    end
                end
                output.add("Gold: " .. player.gold .. "\n")
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "pick" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify an item to pick up.\n")
            else
                local quantity = 1
                local last_part = command_parts[#command_parts]
                if tonumber(last_part) and #command_parts > 2 then
                    quantity = math.max(1, math.floor(tonumber(last_part)))
                    table.remove(command_parts, #command_parts)
                end
                local item_name = table.concat(command_parts, " ", 2)
                items.pick_item(player, map, item_name, quantity)
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "drop" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify an item to drop.\n")
            else
                local quantity = 1
                local last_part = command_parts[#command_parts]
                if tonumber(last_part) and #command_parts > 2 then
                    quantity = math.max(1, math.floor(tonumber(last_part)))
                    table.remove(command_parts, #command_parts)
                end
                local item_name = table.concat(command_parts, " ", 2)
                items.drop_item(player, map, item_name, quantity)
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "look" then
            output.clear()
            if not player.alive then
                output.add("You are dead and cannot look around.\nStart a new game with the 'new' command.\n")
            else
                local location_desc = get_location_description(map.tiles[player.y][player.x])
                output.add(location_desc .. "\n")
                local items_string = items.get_tile_items_string(map, player.x, player.y)
                output.add(items_string)
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "map" then
            output.clear()
            
            for y = 1, config.map.height do
                local line = ""
                for x = 1, config.map.width do
                    if x == player.x and y == player.y then
                        if player.alive then
                            line = line .. player.symbol
                        else
                            line = line .. "X"
                        end
                    elseif map.visited[y][x] then
                        line = line .. map.tiles[y][x]
                    else
                        line = line .. " "
                    end
                end
                output.add(line .. "\n")
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "north" or command_parts[1] == "n" then
            move_player("north")
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "south" or command_parts[1] == "s" then
            move_player("south")
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "east" or command_parts[1] == "e" then
            move_player("east")
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "west" or command_parts[1] == "w" then
            move_player("west")
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "quit" then
            save_game_to_json()
            love.event.quit()
        else
            output.clear()
            output.add("Unknown command: '" .. command_parts[1] .. "'.\n")
            output.add("Type 'help' for a list of available commands.\n")
        end
        input.text = ">"
        input.history_index = 0
    end
    if key == "up" and input.history_index < #input.history then
        input.history_index = input.history_index + 1
        input.text = ">" .. input.history[input.history_index]
    end
    if key == "down" then
        if input.history_index > 1 then
            input.history_index = input.history_index - 1
            input.text = ">" .. input.history[input.history_index]
        elseif input.history_index == 1 then
            input.history_index = 0
            input.text = ">"
        end
    end
end

function table_contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function table_count(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function love.draw()
    love.graphics.setFont(output.font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(output.text, output.x, output.y, output.width, "left")
    
    love.graphics.setFont(input.font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(input.text, input.x, input.y)
    
    if input.cursor_visible then
        local text_width = input.font:getWidth(input.text)
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(
            input.x + text_width,
            input.y,
            input.x + text_width,
            input.y + input.font:getHeight()
        )
    end
end

function love.resize(w, h)
    input.y = h - 40
    input.width = w - 10
    output.width = w - 10
    output.height = h - 50
end

function love.quit()
    save_game_to_json()
end