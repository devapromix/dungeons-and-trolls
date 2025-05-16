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
    
    initializeGame()
    
    if love.filesystem.getInfo("game.json") then
        loadGameFromJson()
        output.add("Loaded saved game.\n")
    else
        output.add("Created new game.\n")
    end
end

function initializeGame()
    map = {
        tiles = {},
        visited = {}
    }
    
    player = {
        x = math.floor(config.map.width / 2),
        y = math.floor(config.map.height / 2), 
        symbol = "@",
        health = 100,
        max_health = 100,
        mana = 100,
        max_mana = 100,
        hunger = 100,
        fatigue = 100,
        alive = true
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

function saveGameToJson()
    local saveData = {
        map = map,
        player = player,
        history = input.history
    }
    
    local saveString = json.encode(saveData)
    love.filesystem.write("game.json", saveString)
end

function loadGameFromJson()
    local saveString = love.filesystem.read("game.json")
    if saveString then
        local saveData = json.decode(saveString)
        if saveData then
            map = saveData.map
            player = saveData.player
            input.history = saveData.history or {}
            
            if player.alive == nil then
                player.alive = (player.hunger > 0 and player.fatigue > 0 and player.health > 0)
            end
        end
    end
end

function checkPlayerStatus()
    if player.hunger <= 0 then
        player.hunger = 0
        player.alive = false
        return "You died from starvation.\n"
    elseif player.fatigue <= 0 then
        player.fatigue = 0
        player.alive = false
        return "You died from exhaustion.\n"
    elseif player.health <= 0 then
        player.health = 0
        player.alive = false
        return "You died from your injuries.\n"
    end
    return ""
end

function movePlayer(direction)
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
        
        player.fatigue = math.max(0, player.fatigue - (player.mana <= 0 and 2 or 1))
        player.hunger = math.max(0, player.hunger - 0.5)
        
        local statusMessage = checkPlayerStatus()
        if statusMessage ~= "" then
            output.add(statusMessage)
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
            
            table.insert(input.history, 1, command)
        elseif command == "new" then
            output.clear()
            output.add("Starting a new game...\n")
            initializeGame()
            output.add("New game initialized.\nType 'map' to see the map.\n")
            table.insert(input.history, 1, command)
        elseif command == "save" then
            saveGameToJson()
            output.clear()
            output.add("Game saved.\n")
            table.insert(input.history, 1, command)
        elseif command == "load" then
            output.clear()
            if love.filesystem.getInfo("game.json") then
                loadGameFromJson()
                output.add("Game loaded.\n")
            else
                output.add("No saved game file found.\n")
            end
            table.insert(input.history, 1, command)
        elseif command == "status" then
            output.clear()
            output.add("Health: " .. player.health .. "/" .. player.max_health .. "\n")
            output.add("Mana: " .. player.mana .. "/" .. player.max_mana .. "\n")
            output.add("Hunger: " .. player.hunger .. "/100" .. "\n")
            output.add("Fatigue: " .. player.fatigue .. "/100" .. "\n")
            output.add("Position: " .. player.x .. ", " .. player.y .. "\n")
            
            if not player.alive then
                output.add("\nYou are DEAD.\nUse 'new' command to start a new game.\n")
            end
            
            table.insert(input.history, 1, command)
        elseif command == "rest" then
            output.clear()
            if not player.alive then
                output.add("You are DEAD and cannot rest.\nStart a new game with the 'new' command.\n")
            else
                output.add("You rest for a while...\n")
                player.health = player.max_health
                player.mana = player.max_mana
                player.fatigue = math.min(100, player.fatigue + 50)
                player.hunger = math.max(0, player.hunger - 10)
                
                output.add("Your health and mana are fully restored.\n")
                output.add("Your fatigue has decreased.\n")
                output.add("You feel hungrier.\n")
                
                local statusMessage = checkPlayerStatus()
                if statusMessage ~= "" then
                    output.add(statusMessage)
                end
            end
            
            table.insert(input.history, 1, command)
        elseif command == "eat" then
            output.clear()
            if not player.alive then
                output.add("You are dead and cannot eat.\nStart a new game with the 'new' command.\n")
            else
                output.add("You eat some food...\n")
                player.hunger = math.min(100, player.hunger + 30)
                
                output.add("You feel less hungry now.\n")
            end
            
            table.insert(input.history, 1, command)
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
            
            table.insert(input.history, 1, command)
        elseif command == "north" or command == "n" then
            movePlayer("north")
            table.insert(input.history, 1, command)
        elseif command == "south" or command == "s" then
            movePlayer("south")
            table.insert(input.history, 1, command)
        elseif command == "east" or command == "e" then
            movePlayer("east")
            table.insert(input.history, 1, command)
        elseif command == "west" or command == "w" then
            movePlayer("west")
            table.insert(input.history, 1, command)
        elseif command == "quit" then
            saveGameToJson()
            love.event.quit()
            table.insert(input.history, 1, command)
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
    saveGameToJson()
end