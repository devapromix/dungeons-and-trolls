local commands = {}

function commands.table_contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function commands.table_count(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function commands.parse_item_command(command_parts, start_index)
    local quantity = 1
    local item_name
    if tonumber(command_parts[start_index]) then
        quantity = math.floor(tonumber(command_parts[start_index]))
        if #command_parts >= start_index + 1 then
            item_name = table.concat(command_parts, " ", start_index + 1)
        else
            output.add("Please specify an item name after the quantity  (e.g., 'pick 3 Healing Potion').\n")
            return nil, nil
        end
    else
        item_name = table.concat(command_parts, " ", start_index)
    end
    return quantity, item_name
end

function commands.handle_command(command_parts, player, map_data, items_data, enemies_data, skills_data, config, game_time, input, output, time, player_module, items, enemies, map, skills, json)
    if not game.initialized and not (command_parts[1] == "help" or command_parts[1] == "quit" or command_parts[1] == "new" or command_parts[1] == "about") then
        output.add("No game loaded or saved game version is incompatible. Please start a new game with the 'new' command.\n")
        return
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
        game.new_game()
    elseif command_parts[1] == "save" then
        game.save_game()
    elseif command_parts[1] == "load" then
        game.load_game()
        output.add("Type 'help' to see a list of available commands.\n")
    elseif command_parts[1] == "status" then
        player_module.draw_status(player)
    elseif command_parts[1] == "skills" then
        output.add("Skills:\n")
        skills.draw()
    elseif command_parts[1] == "time" then
        output.add("Time: " .. game_time.year .. "/" .. game_time.month .. "/" .. game_time.day .. " " .. string.format("%02d:%02d", game_time.hour, game_time.minute) .. " (" .. (game_time.hour >= 6 and game_time.hour < 18 and "Day" or "Night") .. ")\n")
    elseif command_parts[1] == "rest" then
    if not player_module.check_player_alive("rest", player) then
        return
    end
    player = player_module.rest(player, map_data, game_time, time, output)
    elseif command_parts[1] == "eat" then
        if #command_parts < 2 then
            output.add("Please specify an item to eat (e.g., 'eat Apple').\n")
        else
            local item_name = table.concat(command_parts, " ", 2)
            player = items.eat_item(player, items_data, item_name) or player
        end
    elseif command_parts[1] == "drink" then
        if #command_parts < 2 then
            output.add("Please specify an item to drink (e.g., 'drink Healing Potion').\n")
        else
            local item_name = table.concat(command_parts, " ", 2)
            player = items.drink_item(player, items_data, item_name) or player
        end
    elseif command_parts[1] == "items" then
        if not player_module.check_player_alive("check your inventory", player) then
            return
        end
        output.add("Inventory (" .. commands.table_count(player.inventory) .. "/" .. config.inventory.max_slots .. "):\n")
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
            local quantity, item_name = commands.parse_item_command(command_parts, 2)
            if quantity and item_name then
                items.pick_item(player, map_data, item_name, quantity)
            end
        end
    elseif command_parts[1] == "drop" then
        if #command_parts < 2 then
            output.add("Please specify a quantity and item to drop (e.g., 'drop 2 Healing Potion').\n")
        else
            local quantity, item_name = commands.parse_item_command(command_parts, 2)
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
        if not player_module.check_player_alive("look around", player) then
            return
        end
        map.display_location_and_items(player, map_data)
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
            player_module.attack_enemy(enemy_name, map_data, player, enemies_data, items_data, skills_data, time, map, output)
        end
    elseif command_parts[1] == "north" or command_parts[1] == "n" then
        if player_module.move_player("north", player, map_data, config, time, output) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    elseif command_parts[1] == "south" or command_parts[1] == "s" then
        if player_module.move_player("south", player, map_data, config, time, output) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    elseif command_parts[1] == "east" or command_parts[1] == "e" then
        if player_module.move_player("east", player, map_data, config, time, output) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    elseif command_parts[1] == "west" or command_parts[1] == "w" then
        if player_module.move_player("west", player, map_data, config, time, output) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    elseif command_parts[1] == "light" then
        if not player_module.check_player_alive("light a fire", player) then
            return
        end
        items.make_fire_item(player, map_data)
    elseif command_parts[1] == "about" then
        game.about()
    elseif command_parts[1] == "quit" then
        if game.initialized then
            game.save_game()
        end
        love.event.quit()
    else
        output.add("Unknown command: '" .. command_parts[1] .. "'.\n")
        output.add("Type 'help' for a list of available commands.\n")
    end
end

return commands