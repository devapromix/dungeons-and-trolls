json = require("libraries.json")
output = require("output")
time = require("time")
items = require("items")
player_module = require("player")

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
        local location_desc = player_module.get_location_description(map.tiles[player.y][player.x], locations_data)
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player.x, player.y)
        output.add(items_string)
        output.add("Type 'help' to see a list of available commands.\n")
    else
        output.add("Created new game.\n")
        local location_desc = player_module.get_location_description(map.tiles[player.y][player.x], locations_data)
        output.add(location_desc .. "\n")
        local items_string = items.get_tile_items_string(map, player.x, player.y)
        output.add(items_string)
        output.add("Type 'help' to see a list of available commands.\n")
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

function initialize_game()
    map = {
        tiles = {},
        visited = {},
        items = {}
    }
    
    player = player_module.initialize()
    
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
            -- Generate items with 10% probability
            if items_data.items and #items_data.items > 0 and math.random() < 0.1 then
                local item = items_data.items[math.random(1, #items_data.items)]
                local quantity = math.random(1, 3)
                map.items[y][x][item.name] = quantity
            end
        end
    end
    
    map.visited[player.y][player.x] = true
    input.history = {}
    input.history_index = 0
    output.clear()
	output.add("Welcome to " .. config.game.name .. " v." .. config.game.version .. "\n")
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
            local location_desc = player_module.get_location_description(map.tiles[player.y][player.x], locations_data)
            output.add(location_desc .. "\n")
            local items_string = items.get_tile_items_string(map, player.x, player.y)
            output.add(items_string)
            output.add("Type 'help' to see a list of available commands.\n")
        elseif command_parts[1] == "save" then
            save_game_to_json()
            output.clear()
            output.add("Game saved.\n")
        elseif command_parts[1] == "load" then
            output.clear()
            if love.filesystem.getInfo("game.json") then
                load_game_from_json()
                output.add("Game loaded.\n")
                local location_desc = player_module.get_location_description(map.tiles[player.y][player.x], locations_data)
                output.add(location_desc .. "\n")
                local items_string = items.get_tile_items_string(map, player.x, player.y)
                output.add(items_string)
                output.add("Type 'help' to see a list of available commands.\n")
            else
                output.add("No saved game found.\n")
            end
        elseif command_parts[1] == "status" then
            player_module.show_status(player)
            
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
            player_module.rest(player, game_time)
            
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
            player_module.show_inventory(player)
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "pick" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify a quantity and item to pick up (e.g., 'pick 2 Healing Potion').\n")
            else
                local quantity = 1
                local item_name
                if tonumber(command_parts[2]) then
                    quantity = math.floor(tonumber(command_parts[2]))
                    if #command_parts >= 3 then
                        item_name = table.concat(command_parts, " ", 3)
                    else
                        output.add("Please specify an item name after the quantity.\n")
                        if not table_contains(input.history, command) then
                            table.insert(input.history, 1, command)
                        end
                        input.text = ">"
                        input.history_index = 0
                        return
                    end
                else
                    item_name = table.concat(command_parts, " ", 2)
                end
                items.pick_item(player, map, item_name, quantity)
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "drop" then
            output.clear()
            if #command_parts < 2 then
                output.add("Please specify a quantity and item to drop (e.g., 'drop 2 Healing Potion').\n")
            else
                local quantity = 1
                local item_name
                if tonumber(command_parts[2]) then
                    quantity = math.floor(tonumber(command_parts[2]))
                    if #command_parts >= 3 then
                        item_name = table.concat(command_parts, " ", 3)
                    else
                        output.add("Please specify an item name after the quantity.\n")
                        if not table_contains(input.history, command) then
                            table.insert(input.history, 1, command)
                        end
                        input.text = ">"
                        input.history_index = 0
                        return
                    end
                else
                    item_name = table.concat(command_parts, " ", 2)
                end
                items.drop_item(player, map, item_name, quantity)
            end
            
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "look" then
            player_module.look(player, map, locations_data)
            
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
            player_module.move(player, map, "north", locations_data)
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "south" or command_parts[1] == "s" then
            player_module.move(player, map, "south", locations_data)
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "east" or command_parts[1] == "e" then
            player_module.move(player, map, "east", locations_data)
            if not table_contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command_parts[1] == "west" or command_parts[1] == "w" then
            player_module.move(player, map, "west", locations_data)
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