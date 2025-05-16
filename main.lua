function love.load()
    json = require("libraries.json")
    
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
    
    output = {
        text = "",
        x = 5,
        y = 5,
        width = love.graphics.getWidth() - 10,
        height = love.graphics.getHeight() - 50,
        font = love.graphics.newFont("assets/fonts/UbuntuMono-R.ttf", 20)
    }
    
    if output.font == nil then
        output.font = love.graphics.newFont(16)
    end
    
    initializeGame()
    
    if love.filesystem.getInfo("game.json") then
        loadGameFromJson()
    end
end

function initializeGame()
    map = {
        width = 127,
        height = 37,
        tiles = {},
        visited = {}
    }
    
    player = {
        x = math.floor(map.width / 2),
        y = math.floor(map.height / 2), 
        symbol = "@",
        health = 100,
        max_health = 100,
        mana = 100,
        max_mana = 100,
        hunger = 100,
        fatigue = 100,
        alive = true
    }
    
    for y = 1, map.height do
        map.tiles[y] = {}
        map.visited[y] = {}
        for x = 1, map.width do
            map.tiles[y][x] = "s"
            map.visited[y][x] = false
        end
    end
    
    map.visited[player.y][player.x] = true
    input.history = {}
    input.history_index = 0
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
    local moved = false
    output.text = ""
    
    if not player.alive then
        output.text = "You are dead and cannot move. Start a new game with the 'new' command.\n"
        return false
    end
    
    if direction == "north" then
        if player.y > 1 then
            player.y = player.y - 1
            map.visited[player.y][player.x] = true
            output.text = output.text .. "You moved north.\n"
            moved = true
        else
            output.text = output.text .. "You can't move further north.\n"
        end
    elseif direction == "south" then
        if player.y < map.height then
            player.y = player.y + 1
            map.visited[player.y][player.x] = true
            output.text = output.text .. "You moved south.\n"
            moved = true
        else
            output.text = output.text .. "You can't move further south.\n"
        end
    elseif direction == "east" then
        if player.x < map.width then
            player.x = player.x + 1
            map.visited[player.y][player.x] = true
            output.text = output.text .. "You moved east.\n"
            moved = true
        else
            output.text = output.text .. "You can't move further east.\n"
        end
    elseif direction == "west" then
        if player.x > 1 then
            player.x = player.x - 1
            map.visited[player.y][player.x] = true
            output.text = output.text .. "You moved west.\n"
            moved = true
        else
            output.text = output.text .. "You can't move further west.\n"
        end
    end
    
    if moved then
        local fatigue_modifier = 1
        if player.mana <= 0 then
            fatigue_modifier = 2
        end
        
        player.fatigue = math.max(0, player.fatigue - (1 * fatigue_modifier))
        player.hunger = math.max(0, player.hunger - 0.5)
        
        local statusMessage = checkPlayerStatus()
        if statusMessage ~= "" then
            output.text = output.text .. statusMessage
        end
    end
    
    return moved
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
            output.text = ""
            
            if love.filesystem.getInfo("assets/data/help.txt") then
                local content = love.filesystem.read("assets/data/help.txt")
                if content then
                    output.text = content
                else
                    output.text = "Failed to read help file.\n"
                end
            else
                output.text = "Help file not found.\n"
            end
            
            table.insert(input.history, 1, command)
        elseif command == "new" then
            output.text = "Starting a new game...\n"
            initializeGame()
            output.text = output.text .. "New game initialized. Type 'map' to see the map.\n"
            table.insert(input.history, 1, command)
        elseif command == "save" then
            saveGameToJson()
            output.text = "Game saved to game.json\n"
            table.insert(input.history, 1, command)
        elseif command == "load" then
            if love.filesystem.getInfo("game.json") then
                loadGameFromJson()
                output.text = "Game loaded from game.json\n"
            else
                output.text = "No saved game file found\n"
            end
            table.insert(input.history, 1, command)
        elseif command == "status" then
            output.text = "Player Status:\n\n"
            output.text = output.text .. "Health: " .. player.health .. "/" .. player.max_health .. " (0 = death)\n"
            output.text = output.text .. "Mana: " .. player.mana .. "/" .. player.max_mana .. " (0 = faster fatigue)\n"
            output.text = output.text .. "Hunger: " .. player.hunger .. "/100" .. " (0 = death)\n"
            output.text = output.text .. "Fatigue: " .. player.fatigue .. "/100" .. " (0 = death)\n"
            output.text = output.text .. "Position: X=" .. player.x .. ", Y=" .. player.y .. "\n"
            
            if not player.alive then
                output.text = output.text .. "\nStatus: DEAD. Use 'new' command to start a new game.\n"
            end
            
            table.insert(input.history, 1, command)
        elseif command == "rest" then
            if not player.alive then
                output.text = "You are dead and cannot rest. Start a new game with the 'new' command.\n"
            else
                output.text = "You rest for a while...\n"
                player.health = player.max_health
                player.mana = player.max_mana
                player.fatigue = math.min(100, player.fatigue + 50)
                player.hunger = math.max(0, player.hunger - 10)
                
                output.text = output.text .. "Your health and mana are fully restored.\n"
                output.text = output.text .. "Your fatigue has decreased.\n"
                output.text = output.text .. "You feel hungrier.\n"
                
                local statusMessage = checkPlayerStatus()
                if statusMessage ~= "" then
                    output.text = output.text .. statusMessage
                end
            end
            
            table.insert(input.history, 1, command)
        elseif command == "eat" then
            if not player.alive then
                output.text = "You are dead and cannot eat. Start a new game with the 'new' command.\n"
            else
                output.text = "You eat some food...\n"
                player.hunger = math.min(100, player.hunger + 30)
                
                output.text = output.text .. "You feel less hungry now.\n"
            end
            
            table.insert(input.history, 1, command)
        elseif command == "map" then
            output.text = ""
            
            for y = 1, map.height do
                local line = ""
                for x = 1, map.width do
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
                output.text = output.text .. line .. "\n"
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
            love.event.quit()
            table.insert(input.history, 1, command)
        else
            output.text = ""
            output.text = output.text .. "Unknown command: '" .. command .. "'\n"
            output.text = output.text .. "Type 'help' for a list of available commands\n"
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