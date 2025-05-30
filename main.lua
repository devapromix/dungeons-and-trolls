json = require("libraries.json")
output = require("output")
time = require("time")
items = require("items")
enemies = require("enemies")
map = require("map")
player_module = require("player")
skills = require("skills")

function display_location_and_items()
    local location = map.get_location_description(map_data.tiles[player.y][player.x])
    output.add("You are in " .. location.name .. ". " .. location.description .. "\n")
    local items_string = items.get_tile_items_string(map_data, player.x, player.y)
    output.add(items_string)
    local enemies_string = enemies.get_tile_enemies_string(map_data, player.x, player.y)
    output.add(enemies_string)
    if map_data.fire.active and map_data.fire.x == player.x and map_data.fire.y == player.y then
        output.add("A fire is burning here.\n")
    end
end

function initialize_new_game()
    map.initialize_game(locations_data)
    output.add("Created new game.\n")
    display_location_and_items()
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
            display_location_and_items()
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

function parse_item_command(command_parts, start_index)
    local quantity = 1
    local item_name
    if tonumber(command_parts[start_index]) then
        quantity = math.floor(tonumber(command_parts[start_index]))
        if #command_parts >= start_index + 1 then
            item_name = table.concat(command_parts, " ", start_index + 1)
        else
            output.add("Please specify an item name after the quantity.\n")
            return nil, nil
        end
    else
        item_name = table.concat(command_parts, " ", start_index)
    end
    return quantity, item_name
end

function combat_round(enemy_name, enemy_data)
    local enemy_health = enemy_data.health
    while player.health > 0 and enemy_health > 0 do
        local player_damage = math.max(0, player.attack - enemy_data.defense)
        player_damage = skills.apply_skill_effects(player, skills_data, player_damage)
        if player_damage > 0 then
            enemy_health = enemy_health - player_damage
            output.add("You hit " .. enemy_name .. " for " .. player_damage .. " damage.\n")
        else
            output.add("Your attack is blocked by " .. enemy_name .. ".\n")
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
            display_location_and_items()
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
        if command_parts[1] == "help" then
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
        elseif command_parts[1] == "new" then
            initialize_new_game()
        elseif command_parts[1] == "save" then
            save_game_to_json()
            output.add("Game saved.\n")
        elseif command_parts[1] == "load" then
            if love.filesystem.getInfo("game.json") then
                load_game_from_json()
                output.add("Type 'help' to see a list of available commands.\n")
            else
                output.add("No saved game found.\n")
            end
        elseif command_parts[1] == "status" then
            output.add("Health: " .. player.health .. "\n")
            output.add("Mana: " .. player.mana .. "\n")
            output.add("Hunger: " .. player.hunger .. "\n")
            output.add("Fatigue: " .. player.fatigue .. "\n")
            output.add("Thirst: " .. player.thirst .. "\n")
            output.add("Attack: " .. player.attack .. "\n")
            output.add("Defense: " .. player.defense .. "\n")
            output.add("Level: " .. player.level .. "\n")
            output.add("Experience: " .. player.experience .. "\n")
            output.add("Gold: " .. player.gold .. "\n")
            output.add("Position: " .. player.x .. ", " .. player.y .. "\n")
            output.add("\nEquipment:\n")
            output.add("Weapon: " .. (player.equipment and player.equipment.weapon or "None") .. "\n")
            output.add("Armor: " .. (player.equipment and player.equipment.armor or "None") .. "\n")
            output.add("\nSkills:\n")
            skills.draw()
            if not player.alive then
                output.add("\nYou are DEAD.\nUse 'new' command to start a new game.\n")
            end
        elseif command_parts[1] == "skills" then
            if not check_player_alive("check skills") then
                return
            end
            output.add("Skills:\n")
            skills.draw()
        elseif command_parts[1] == "time" then
            output.add("Time: " .. game_time.year .. "/" .. game_time.month .. "/" .. game_time.day .. " " .. string.format("%02d:%02d", game_time.hour, game_time.minute) .. " (" .. (game_time.hour >= 6 and game_time.hour < 18 and "Day" or "Night") .. ")\n")
        elseif command_parts[1] == "rest" then
            if not check_player_alive("rest") then
                return
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
                local rest_multiplier = map_data.fire.active and map_data.fire.x == player.x and map_data.fire.y == player.y and 2 or 1
                output.add("You rest for " .. rest_hours .. " hour(s)...\n")
                player.health = math.min(100, math.max(0, player.health + rest_hours * 10 * rest_multiplier))
                player.mana = math.min(100, math.max(0, player.mana + rest_hours * 10 * rest_multiplier))
                player.fatigue = math.min(100, math.max(0, player.fatigue - rest_hours * 10 * rest_multiplier))
                player.hunger = math.min(100, math.max(0, player.hunger + rest_hours * 0.5))
                player.thirst = math.min(100, math.max(0, player.thirst + rest_hours * 5))
                time.tick_time(rest_hours * 60)
                output.add("Your health, mana, and fatigue have been restored.\n")
                if rest_multiplier > 1 then
                    output.add("Resting by the fire makes you recover twice as fast!\n")
                end
                if rest_hours > 0 then
                    output.add("You feel hungrier and thirstier.\n")
                end
                local status_message = check_player_status()
                if status_message ~= "" then
                    output.add(status_message)
                end
            end
        elseif command_parts[1] == "eat" then
            if #command_parts < 2 then
                output.add("Please specify an item to eat.\n")
            else
                local item_name = table.concat(command_parts, " ", 2)
                player = items.eat_item(player, items_data, item_name) or player
            end
        elseif command_parts[1] == "drink" then
            if #command_parts < 2 then
                output.add("Please specify an item to drink.\n")
            else
                local item_name = table.concat(command_parts, " ", 2)
                player = items.drink_item(player, items_data, item_name) or player
            end
        elseif command_parts[1] == "items" then
            if not check_player_alive("check your inventory") then
                return
            end
            output.add("Inventory (" .. table_count(player.inventory) .. "/" .. config.inventory.max_slots .. "):\n")
            if next(player.inventory) == nil then
                output.add("(empty)\n")
            else
                for item, quantity in pairs(player.inventory) do
                    local equipped = items.is_item_equipped(player, item) and " (equipped)" or ""
                    if quantity > 1 then
                        output.add(item .. " (" .. quantity .. ")" .. equipped .. "\n")
                    else
                        output.add(item .. equipped .. "\n")
                    end
                end
            end
            output.add("Gold: " .. player.gold .. "\n")
        elseif command_parts[1] == "pick" then
            if #command_parts < 2 then
                output.add("Please specify a quantity and item to pick up (e.g., 'pick 2 Healing Potion').\n")
            else
                local quantity, item_name = parse_item_command(command_parts, 2)
                if quantity and item_name then
                    items.pick_item(player, map_data, item_name, quantity)
                end
            end
        elseif command_parts[1] == "drop" then
            if #command_parts < 2 then
                output.add("Please specify a quantity and item to drop (e.g., 'drop 2 Healing Potion').\n")
            else
                local quantity, item_name = parse_item_command(command_parts, 2)
                if quantity and item_name then
                    items.drop_item(player, map_data, item_name, quantity)
                end
            end
        elseif command_parts[1] == "equip" then
            if #command_parts < 2 then
                output.add("Please specify an item to equip (e.g., 'equip Sword').\n")
            else
                local item_name = table.concat(command_parts, " ", 2)
                player = player_module.equip_item(player, items_data, item_name)
            end
        elseif command_parts[1] == "unequip" then
            if #command_parts < 2 then
                output.add("Please specify an item or slot to unequip (e.g., 'unequip Sword' or 'unequip weapon').\n")
            else
                local identifier = table.concat(command_parts, " ", 2)
                player = player_module.unequip_item(player, items_data, identifier)
            end
        elseif command_parts[1] == "look" then
            if not check_player_alive("look around") then
                return
            end
            display_location_and_items()
        elseif command_parts[1] == "map" then
            for y = 1, config.map.height do
                local line = ""
                for x = 1, config.map.width do
                    if x == player.x and y == player.y then
                        if player.alive then
                            line = line .. player.symbol
                        else
                            line = line .. "X"
                        end
                    elseif map_data.visited[y][x] then
                        line = line .. map_data.tiles[y][x]
                    else
                        line = line .. " "
                    end
                end
                output.add(line .. "\n")
            end
        elseif command_parts[1] == "attack" then
            if #command_parts < 2 then
                output.add("Please specify an enemy to attack (e.g., 'attack Goblin').\n")
            else
                local enemy_name = table.concat(command_parts, " ", 2)
                attack_enemy(enemy_name)
            end
        elseif command_parts[1] == "north" or command_parts[1] == "n" then
            player_module.move_player("north", player, map_data, config, time, output)
        elseif command_parts[1] == "south" or command_parts[1] == "s" then
            player_module.move_player("south", player, map_data, config, time, output)
        elseif command_parts[1] == "east" or command_parts[1] == "e" then
            player_module.move_player("east", player, map_data, config, time, output)
        elseif command_parts[1] == "west" or command_parts[1] == "w" then
            player_module.move_player("west", player, map_data, config, time, output)
        elseif command_parts[1] == "light" then
            if not check_player_alive("light a fire") then
                return
            end
            items.make_fire_item(player, map_data)
        elseif command_parts[1] == "quit" then
            save_game_to_json()
            love.event.quit()
        else
            output.add("Unknown command: '" .. command_parts[1] .. "'.\n")
            output.add("Type 'help' for a list of available commands.\n")
        end
        if not table_contains(input.history, command) then
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