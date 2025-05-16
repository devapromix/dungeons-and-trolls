json = require("libraries.json")
output = require("output")

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
    
    initialize_game()
    
    if love.filesystem.getInfo("game.json") then
        load_game_from_json()
        output.add("Loaded saved game.\n")
    else
        output.add("Created new game.\n")
    end
end

function initialize_game()
    map = {
        tiles = {},
        visited = {}
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
        alive = true
    }
    
    time = {
        year = 1280,
        month = 4,
        day = 1,
        hour = 9,
        minute = 0
    }
    
    for y = 1, config.map.height do
        map.tiles[y] = {}
        map.visited[y] = {}
        for x = 1, config.map.width do
            map.tiles[y][x] = "s"
            map.visited[y][x] = false
        end
    end
    
    map.visited[player.y][player.x] = true
    input.history = {}
    input.history_index = 0
    output.clear()
end

function tick_time(minutes)
    time.minute = time.minute + minutes
    while time.minute >= 60 do
        time.minute = time.minute - 60
        time.hour = time.hour + 1
    end
    while time.hour >= 24 do
        time.hour = time.hour - 24
        time.day = time.day + 1
    end
    while time.day > 30 do
        time.day = time.day - 30
        time.month = time.month + 1
    end
    while time.month > 12 do
        time.month = time.month - 12
        time.year = time.year + 1
    end
end

function save_game_to_json()
    local save_data = {
        map = map,
        player = player,
        history = input.history,
        time = time
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
            time = save_data.time or { year = 1280, month = 4, day = 1, hour = 9, minute = 0 }
            input.history = save_data.history or {}
            
            player.health = math.min(100, math.max(0, player.health))
            player.mana = math.min(100, math.max(0, player.mana))
            player.hunger = math.min(100, math.max(0, player.hunger or 0))
            player.fatigue = math.min(100, math.max(0, player.fatigue or 0))
            player.thirst = math.min(100, math.max(0, player.thirst or 0))
            
            if player.alive == nil then
                player.alive = (player.hunger < 100 and player.fatigue < 100 and player.health > 0 and player.thirst < 100)
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
        
        tick_time(120)
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
        if command == "help" then
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
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "new" then
            output.clear()
            output.add("Starting a new game...\n")
            initialize_game()
            output.add("New game initialized.\nType 'map' to see the map.\n")
        elseif command == "save" then
            save_game_to_json()
            output.clear()
            output.add("Game saved.\n")
        elseif command == "load" then
            output.clear()
            if love.filesystem.getInfo("game.json") then
                load_game_from_json()
                output.add("Game loaded.\n")
            else
                output.add("No saved game found.\n")
            end
        elseif command == "status" then
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
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "time" then
            output.clear()
            output.add("Time: " .. time.year .. "/" .. time.month .. "/" .. time.day .. " " .. string.format("%02d:%02d", time.hour, time.minute) .. " (" .. (time.hour >= 6 and time.hour < 18 and "Day" or "Night") .. ")\n")
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "rest" then
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
                if time.hour >= 18 then
                    hours_to_morning = (24 - time.hour) + 6
                elseif time.hour < 6 then
                    hours_to_morning = 6 - time.hour
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
                tick_time(rest_hours * 60)
                
                output.add("Your health, mana, and fatigue have been restored.\n")
                if rest_hours > 0 then
                    output.add("You feel hungrier and thirstier.\n")
                end
                
                local status_message = check_player_status()
                if status_message ~= "" then
                    output.add(status_message)
                end
            end
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "eat" then
            output.clear()
            if not player.alive then
                output.add("You are dead and cannot eat.\nStart a new game with the 'new' command.\n")
            elseif player.hunger <= 0 then
                output.add("You don't need to eat.\n")
            else
                output.add("You eat some food...\n")
                player.hunger = math.min(100, math.max(0, player.hunger - 30))
                player.thirst = math.min(100, math.max(0, player.thirst + 1))
                tick_time(15)
                output.add("You feel less hungry but slightly thirstier.\n")
            end
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "drink" then
            output.clear()
            if not player.alive then
                output.add("You are dead and cannot drink.\nStart a new game with the 'new' command.\n")
            elseif player.thirst <= 0 then
                output.add("You don't need to drink.\n")
            else
                output.add("You drink some water...\n")
                player.thirst = math.min(100, math.max(0, player.thirst - 10))
                tick_time(15)
                output.add("You feel less thirsty.\n")
            end
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "map" then
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
            
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "north" or command == "n" then
            move_player("north")
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "south" or command == "s" then
            move_player("south")
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "east" or command == "e" then
            move_player("east")
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "west" or command == "w" then
            move_player("west")
            if not table.contains(input.history, command) then
                table.insert(input.history, 1, command)
            end
        elseif command == "quit" then
            save_game_to_json()
            love.event.quit()
        else
            output.clear()
            output.add("Unknown command: '" .. command .. "'.\n")
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

function table.contains(table, element)
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