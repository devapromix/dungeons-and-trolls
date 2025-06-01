json = require("libraries.json")
output = require("output")
time = require("time")
items = require("items")
enemies = require("enemies")
map = require("map")
player_module = require("player")
skills = require("skills")
commands = require("commands")

function initialize_new_game()
    map.initialize_game(locations_data)
    output.add("Created new game.\n")
    map.display_location_and_items(player, map_data, output)
    output.add("Type 'help' to see a list of available commands.\n")
end

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
        initialize_new_game()
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
            map.display_location_and_items(player, map_data, output)
        end
    end
end

function check_player_status()
    player = player_module.clamp_player_stats(player)
    
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
        return "You died from injuries.\n"
    elseif player.thirst >= 100 then
        player.thirst = 100
        player.alive = false
        return "You died from thirst.\n"
    end
    return ""
end

function check_player_alive(action)
    if not player.alive then
        output.add("You are dead and cannot " .. action .. ".\nStart a new game with the 'new' command.\n")
        return false
    end
    return true
end

function attack_enemy(enemy_name)
    if not check_player_alive("attack") then
        return
    end
    if not enemy_name or enemy_name == "" then
        output.add("Please specify an enemy to attack.\n")
        return
    end
    local enemy_list = map_data.enemies[player.y][player.x]
    local enemy_key = items.find_item_key(enemy_list, enemy_name)
    if not enemy_key then
        output.add("No " .. enemy_name .. " found here.\n")
        return
    end
    local enemy_data = enemies.get_enemy_data(enemies_data, enemy_key)
    if not enemy_data then
        output.add("No data found for " .. enemy_key .. ".\n")
        return
    end
    output.add("You engage " .. enemy_key .. " in combat!\n")
    combat_round(enemy_key, enemy_data)
end

function combat_round(enemy_name, enemy_data)
    local enemy_health = enemy_data.health
    while player.health > 0 and enemy_health > 0 do
        local miss_chance = player.fatigue > 70 and ((player.fatigue - 70) / 30) * 0.5 or 0
        if math.random() >= miss_chance then
            local player_damage = math.max(0, player.attack - enemy_data.defense)
            player_damage = skills.apply_skill_effects(player, skills_data, player_damage)
            if player_damage > 0 then
                enemy_health = enemy_health - player_damage
                output.add("You hit " .. enemy_name .. " for " .. player_damage .. " damage.\n")
            else
                output.add("Your attack is blocked by " .. enemy_name .. ".\n")
            end
        else
            output.add("You missed your attack due to fatigue!\n")
        end
        
        if enemy_health <= 0 then
            output.add("You defeated " .. enemy_name .. "!\n")
            player.experience = player.experience + enemy_data.experience
            output.add("Gained " .. enemy_data.experience .. " experience.\n")
            
            if player.equipment and player.equipment.weapon then
                local item_data = items.get_item_data(items_data, player.equipment.weapon)
                if item_data then
                    skills.upgrade_skill(player, skills_data, item_data)
                end
            end
            if enemy_data.drops then
                for _, drop in ipairs(enemy_data.drops) do
                    if math.random() < drop.chance then
                        local quantity = drop.quantity and math.random(drop.quantity[1], drop.quantity[2]) or 1
                        if drop.type == "gold" then
                            player.gold = player.gold + quantity
                            output.add("Gained " .. quantity .. " gold.\n")
                        elseif drop.type == "item" then
                            map_data.items[player.y][player.x][drop.name] = (map_data.items[player.y][player.x][drop.name] or 0) + quantity
                            output.add(drop.name .. " (" .. quantity .. ") dropped on the ground.\n")
                        end
                    end
                end
            end
            map_data.enemies[player.y][player.x][enemy_name] = map_data.enemies[player.y][player.x][enemy_name] - 1
            if map_data.enemies[player.y][player.x][enemy_name] <= 0 then
                map_data.enemies[player.y][player.x][enemy_name] = nil
            end
            map.display_location_and_items(player, map_data, output)
            return true
        end
        local enemy_damage = math.max(0, enemy_data.attack - player.defense)
        if enemy_damage > 0 then
            player.health = player.health - enemy_damage
            output.add(enemy_name .. " hits you for " .. enemy_damage .. " damage.\n")
        else
            output.add(enemy_name .. "'s attack is blocked.\n")
        end
        if player.health <= 0 then
            player.alive = false
            output.add("You were defeated by " .. enemy_name .. ".\n")
            output.add("Game over. Start a new game with the 'new' command.\n")
            save_game_to_json()
            return false
        end
        time.tick_time(10)
    end
    return false
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