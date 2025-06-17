local commands = {}

commands.awaiting_confirmation = false
commands.confirmation_type = nil

local command_map = {
	game = {"help", "intro", "new", "load", "save", "about", "quit"},
	info = {"status", "skills", "time", "items", "map"},
	item = {"eat", "drink", "pick", "drop", "equip", "unequip"},
	action = {"rest", "examine", "look", "kill", "light", "volume", "recipes", "cook", "fish", "trollcave"},
	movement = {"north", "south", "east", "west", "n", "s", "e", "w", "up", "down", "u", "d"}
}

local movement_map = {north = "north", south = "south",	east = "east", west = "west", up = "up", down = "down",
						n = "north", s = "south", e = "east", w = "west", u = "up",	d = "down"
}

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

function commands.is_valid_command(cmd)
	for _, category in pairs(command_map) do
		if commands.table_contains(category, cmd) then
			return true
		end
	end
	return false
end

function commands.look()
	if not player_module.check_player_alive("look around", player) then
		return
	end
	map.display_location(player, map_data)
end

function commands.get_item_name_from_parts(command_parts, start_index)
	return table.concat(command_parts, " ", start_index)
end

function commands.validate_parameter(param, param_type, output)
	if #param < 3 then
		output.add("Parameter '" .. param .. "' must be at least 3 characters long.\n")
		return false
	end
	return true
end

function commands.parse_item_command(command_parts, start_index)
	local quantity = 1
	local item_name
	if tonumber(command_parts[start_index]) then
		quantity = math.floor(tonumber(command_parts[start_index]))
		if #command_parts >= start_index + 1 then
			item_name = commands.get_item_name_from_parts(command_parts, start_index + 1)
		else
			output.add("Please specify an item name after the quantity (e.g., 'pick 3 Healing Potion').\n")
			return nil, nil
		end
	else
		item_name = commands.get_item_name_from_parts(command_parts, start_index)
	end
	if item_name and not commands.validate_parameter(item_name, "item", output) then
		return nil, nil
	end
	return quantity, item_name
end

function commands.handle_confirmation(command_parts, output)
	local cmd = command_parts[1]
	if cmd == "y" or cmd == "yes" then
		if commands.confirmation_type == "new" then
			game.new_game()
		elseif commands.confirmation_type == "load" then
			game.load_game()
			output.add(const.TYPE_HELP_MSG)
		end
		commands.awaiting_confirmation = false
		commands.confirmation_type = nil
	elseif cmd == "n" or cmd == "no" then
		commands.awaiting_confirmation = false
		commands.confirmation_type = nil
		commands.look()
	else
		output.add("Please enter ('yes' or 'no').\n")
	end
end

function commands.handle_item_commands(cmd, command_parts, player, map_data, items_data, items, player_module)
	if cmd == "eat" then
		if #command_parts < 2 then
			output.add("Please specify an item to eat (e.g., 'eat Apple').\n")
		else
			local item_name = commands.get_item_name_from_parts(command_parts, 2)
			if commands.validate_parameter(item_name, "item", output) then
				player = items.eat_item(player, items_data, item_name) or player
			end
		end
	elseif cmd == "drink" then
		if #command_parts < 2 then
			output.add("Please specify an item to drink (e.g., 'drink Healing Potion').\n")
		else
			local item_name = commands.get_item_name_from_parts(command_parts, 2)
			if commands.validate_parameter(item_name, "item", output) then
				player = items.drink_item(player, items_data, item_name) or player
			end
		end
	elseif cmd == "pick" then
		if #command_parts < 2 then
			output.add("Please specify a quantity and item to pick up (e.g., 'pick 2 Healing Potion').\n")
		else
			local quantity, item_name = commands.parse_item_command(command_parts, 2)
			if quantity and item_name then
				items.pick_item(player, map_data[player.world], item_name, quantity)
			end
		end
	elseif cmd == "drop" then
		if #command_parts < 2 then
			output.add("Please specify a quantity and item to drop (e.g., 'drop 2 Healing Potion').\n")
		else
			local quantity, item_name = commands.parse_item_command(command_parts, 2)
			if quantity and item_name then
				items.drop_item(player, map_data[player.world], item_name, quantity)
			end
		end
	elseif cmd == "equip" then
		if #command_parts < 2 then
			output.add("Please specify an item to equip (e.g., 'equip Sword').\n")
		else
			local item_name = commands.get_item_name_from_parts(command_parts, 2)
			if commands.validate_parameter(item_name, "item", output) then
				player = player_module.equip_item(player, items_data, item_name)
			end
		end
	elseif cmd == "unequip" then
		if #command_parts < 2 then
			output.add("Please specify an item or slot to unequip (e.g., 'unequip Sword' or 'unequip weapon').\n")
		else
			local identifier = commands.get_item_name_from_parts(command_parts, 2)
			if commands.validate_parameter(identifier, "item", output) then
				player = player_module.unequip_item(player, items_data, identifier)
			end
		end
	end
	return player
end

function commands.handle_game_commands(cmd, command_parts, player, output)
	if cmd == "help" then
		game.help()
	elseif cmd == "intro" then
		game.intro()
		output.add("\n")
		output.add(const.TYPE_HELP_MSG)
	elseif cmd == "new" then
		if game.initialized and player.alive then
			commands.awaiting_confirmation = true
			commands.confirmation_type = "new"
			output.add("This will end the current game. Are you sure you want to start a new game? (yes/no)\n")
		else
			game.new_game()
		end
	elseif cmd == "load" then
		if game.initialized and player.alive then
			commands.awaiting_confirmation = true
			commands.confirmation_type = "load"
			output.add("This will end the current game. Are you sure you want to load a saved game? (yes/no)\n")
		else
			game.load_game()
			output.add(const.TYPE_HELP_MSG)
		end
	elseif cmd == "save" then
		if not player_module.check_player_alive("save the game", player) then
			return
		end
		game.save_game()
	elseif cmd == "about" then
		game.about()
	elseif cmd == "quit" then
		if game.initialized then
			game.save_game()
		end
		love.event.quit()
	end
end

function commands.handle_info_commands(cmd, command_parts, player, map_data, config, game_time, skills, output, player_module)
	if cmd == "status" then
		player_module.draw_status(player)
	elseif cmd == "skills" then
		command_skills.exec(skills, output)
	elseif cmd == "time" then
		output.add("Time: " .. game_time.year .. "/" .. game_time.month .. "/" .. game_time.day .. " " .. string.format("%02d:%02d", game_time.hour, game_time.minute) .. " (" .. (game_time.hour >= 6 and game_time.hour < 18 and "Day" or "Night") .. ")\n")
		output.add("Played: " .. time.format_playtime(game_time.playtime or 0) .. "\n")
	elseif cmd == "items" then
		command_items.exec(player, player_module, items)
	elseif cmd == "map" then
		map.draw()
	end
end

function commands.handle_action_commands(cmd, command_parts, player, map_data, items_data, enemies_data, skills_data, game_time, time, output, player_module, items, enemies, map, music, config)
	if cmd == "rest" then
		if not player_module.check_player_alive("rest", player) then
			return player
		end
		return player_module.rest(player, map_data, game_time, time)
	elseif cmd == "examine" then
		return command_examine.exec(command_parts, player, map_data, items_data, enemies_data, output, items, enemies, player_module)
	elseif cmd == "look" then
		commands.look()
	elseif cmd == "kill" then
		return command_kill.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, output, player_module)
	elseif cmd == "light" then
		return command_light.exec(player, player_module, map_data)
	elseif cmd == "volume" then
		command_volume.exec(command_parts)
	elseif cmd == "recipes" then
		command_recipes.exec(player)
	elseif cmd == "cook" then
		return command_cook.exec(command_parts, player, map_data, items_data, output, items, time)
	elseif cmd == "fish" then
		return command_fishing.exec(player, map_data, items_data, skills_data, time, output)
	elseif cmd == "trollcave" then
		return command_trollcave.exec(player, map_data, config, output, map)
	end
	return player
end

function commands.handle_command(command_parts, player, map_data, items_data, enemies_data, skills_data, config, game_time, input, output, time, player_module, items, enemies, map, skills, json)
	if commands.awaiting_confirmation then
		commands.handle_confirmation(command_parts, output)
		return
	end

	if not game.initialized and not commands.table_contains({"help", "quit", "new", "about", "load"}, command_parts[1]) then
		output.add("No game loaded or saved game version is incompatible. " .. const.START_NEW_GAME_MSG)
		return
	end

	local cmd = command_parts[1]

	commands.handle_game_commands(cmd, command_parts, player, output)
	commands.handle_info_commands(cmd, command_parts, player, map_data, config, game_time, skills, output, player_module)
	player = commands.handle_item_commands(cmd, command_parts, player, map_data, items_data, items, player_module)
	player = commands.handle_action_commands(cmd, command_parts, player, map_data, items_data, enemies_data, skills_data, game_time, time, output, player_module, items, enemies, map, music, config)

	local direction = movement_map[cmd]
	if direction then
		player = command_move.exec(direction, player, map_data, config, time, output, player_module, map, music)
	elseif not commands.is_valid_command(cmd) then
		output.add("Unknown command: '" .. cmd .. "'.\n")
		output.add(const.TYPE_HELP_MSG)
	end
end

return commands