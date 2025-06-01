json = require("libraries.json")
output = require("output")
time = require("time")
const = require("const")
items = require("items")
enemies = require("enemies")
map = require("map")
game = require("game")
player_module = require("player")
skills = require("skills")
commands = require("commands")

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
    locations_data = map.load_locations()
    enemies_data = enemies.load_enemies()
    skills_data = skills.load_skills()
    
    output.add("Welcome to " .. config.game.name .. " v." .. config.game.version .. "\n")
    if love.filesystem.getInfo("game.json") then
        load_game_from_json()
        output.add("Type 'help' to see a list of available commands.\n")
    else
        game.new_game()
    end
end

function save_game_to_json()
    local save_data = {
        map = map_data,
        player = player,
        history = input.history,
        time = game_time,
        version = config.game.version,
        fire = map_data.fire
    }
    
    local save_string = json.encode(save_data)
    love.filesystem.write("game.json", save_string)
end

function load_game_from_json()
    local save_string = love.filesystem.read("game.json")
    if save_string then
        local save_data = json.decode(save_string)
        if save_data then
            if save_data.version ~= config.game.version then
                output.add("Saved game version (" .. (save_data.version or "unknown") .. ") is incompatible with current game version (" .. config.game.version .. ").\n")
                output.add("Please start a new game with the 'new' command.\n")
                return
            end
            map_data = save_data.map
            player = save_data.player
            game_time = save_data.time or { year = 1280, month = 4, day = 1, hour = 6, minute = 0 }
            input.history = save_data.history or {}
            map_data.fire = save_data.fire or { x = nil, y = nil, active = false }
            
            player = player_module.clamp_player_stats(player)
            player = player_module.clamp_player_skills(player, skills_data)
            player.inventory = player.inventory or {}
            player.equipment = player.equipment or { weapon = nil, armor = nil }
            player.skills = player.skills or {}
            for _, skill in ipairs(skills_data.skills) do
                player.skills[skill.name] = player.skills[skill.name] or skill.initial_level
            end
            player.level = player.level or 1
            player.experience = player.experience or 0
            
            if player.alive == nil then
                player.alive = (player.hunger < 100 and player.fatigue < 100 and player.health > 0 and player.thirst < 100)
            end
            for y = 1, config.map.height do
                map_data.items[y] = map_data.items[y] or {}
                map_data.enemies[y] = map_data.enemies[y] or {}
                for x = 1, config.map.width do
                    map_data.items[y][x] = map_data.items[y][x] or {}
                    map_data.enemies[y][x] = map_data.enemies[y][x] or {}
                end
            end
            output.add("Loaded saved game.\n")
            map.display_location_and_items(player, map_data)
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
        output.clear()
        local command = input.text:sub(2)
        local command_parts = {}
        for part in command:gmatch("%S+") do
            table.insert(command_parts, part)
        end
        commands.handle_command(command_parts, player, map_data, items_data, enemies_data, skills_data, config, game_time, input, output, time, player_module, items, enemies, map, skills, json)
        if not commands.table_contains(input.history, command) then
            table.insert(input.history, 1, command)
        end
        input.text = ">"
        input.history_index = 0
    end
    if key == "up" and input.history_index < #input.history then
        input.history_index = input.history_index + 1
        input.text = ">" .. input.history[input.history_index]
    elseif key == "down" then
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
    save_game_to_json()
end