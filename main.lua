function love.load()
    -- Ініціалізація терміналу
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
        -- Використання моноширинного шрифту для коректного відображення мапи
        font = love.graphics.newFont("assets\fonts\UbuntuMono-R.ttf", 20)
    }
    
    -- Якщо файл courier.ttf не знайдено, використати стандартний шрифт
    if output.font == nil then
        output.font = love.graphics.newFont(16)
    end
    
    -- Ініціалізація мапи та героя
    map = {
        width = 127,
        height = 37,
        tiles = {},
        visited = {} -- Таблиця для відстеження відвіданих тайлів
    }
    
    player = {
        x = math.floor(map.width / 2),
        y = math.floor(map.height / 2), 
        symbol = "@"
    }
    
    -- Заповнення мапи піском та ініціалізація відвіданих тайлів
    for y = 1, map.height do
        map.tiles[y] = {}
        map.visited[y] = {}
        for x = 1, map.width do
            map.tiles[y][x] = "s"  -- s - пісок
            map.visited[y][x] = false -- Спочатку всі тайли не відвідані
        end
    end
    
    -- Позначити початкову позицію гравця як відвідану
    map.visited[player.y][player.x] = true
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
            output.text = ""  -- Clear the output window
            output.text = output.text .. "Available commands:\n\n"
            output.text = output.text .. "help - Show this help message\n"
            output.text = output.text .. "new - Starts a new game\n"
            output.text = output.text .. "save - Saves a game\n"
            output.text = output.text .. "load - Loads a saved game\n"
            output.text = output.text .. "map - Display the game map\n"
            output.text = output.text .. "north (or n) - Move player north\n"
            output.text = output.text .. "south (or s) - Move player south\n"
            output.text = output.text .. "east (or e) - Move player east\n"
            output.text = output.text .. "west (or w) - Move player west\n"
            output.text = output.text .. "quit - Exit the game\n"
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "save" then
            local content = table.concat(input.history, "\n")
            love.filesystem.write("commands.txt", content)
            output.text = output.text .. "Commands saved to commands.txt\n"
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "load" then
            if love.filesystem.getInfo("commands.txt") then
                local content = love.filesystem.read("commands.txt")
                if content then
                    local loaded_commands = {}
                    for line in content:gmatch("[^\r\n]+") do
                        table.insert(loaded_commands, line)
                    end
                    -- Add loaded commands to history in reverse order
                    for i = #loaded_commands, 1, -1 do
                        table.insert(input.history, 1, loaded_commands[i])
                    end
                    output.text = output.text .. "Commands loaded from commands.txt\n"
                else
                    output.text = output.text .. "Failed to read commands.txt\n"
                end
            else
                output.text = output.text .. "No saved commands file found\n"
            end
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "map" then
            output.text = ""  -- Clear the output window
            
            -- Відображення мапи без заголовка, лише сама мапа
            for y = 1, map.height do
                local line = ""
                for x = 1, map.width do
                    -- Якщо це координати героя, показуємо героя замість тайла
                    if x == player.x and y == player.y then
                        line = line .. player.symbol
                    -- Показуємо тайл лише якщо він відвіданий
                    elseif map.visited[y][x] then
                        line = line .. map.tiles[y][x]
                    else
                        line = line .. " " -- Непідосвідчені тайли показуємо як пробіли
                    end
                end
                output.text = output.text .. line .. "\n"
            end
            
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "north" or command == "n" then
            output.text = ""  -- Clear the output window before showing movement result
            if player.y > 1 then
                player.y = player.y - 1
                map.visited[player.y][player.x] = true -- Позначити нову позицію як відвідану
                output.text = output.text .. "You moved north.\n"
            else
                output.text = output.text .. "You can't move further north.\n"
            end
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "south" or command == "s" then
            output.text = ""  -- Clear the output window before showing movement result
            if player.y < map.height then
                player.y = player.y + 1
                map.visited[player.y][player.x] = true -- Позначити нову позицію як відвідану
                output.text = output.text .. "You moved south.\n"
            else
                output.text = output.text .. "You can't move further south.\n"
            end
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "east" or command == "e" then
            output.text = ""  -- Clear the output window before showing movement result
            if player.x < map.width then
                player.x = player.x + 1
                map.visited[player.y][player.x] = true -- Позначити нову позицію як відвідану
                output.text = output.text .. "You moved east.\n"
            else
                output.text = output.text .. "You can't move further east.\n"
            end
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "west" or command == "w" then
            output.text = ""  -- Clear the output window before showing movement result
            if player.x > 1 then
                player.x = player.x - 1
                map.visited[player.y][player.x] = true -- Позначити нову позицію як відвідану
                output.text = output.text .. "You moved west.\n"
            else
                output.text = output.text .. "You can't move further west.\n"
            end
            -- Add valid command to history
            table.insert(input.history, 1, command)
        elseif command == "quit" then
            love.event.quit()
            -- Add valid command to history (though it won't be saved as we're quitting)
            table.insert(input.history, 1, command)
        else
            -- Do NOT add invalid commands to history
            -- Clear output and show error message for unknown command
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