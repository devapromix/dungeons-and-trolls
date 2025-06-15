local examine = {}

function examine.display_item_info(item_key, item_data, output)
	output.add(item_key .. ":\n\n")
	output.add(item_data.description .. "\n\n")
	for _, tag in ipairs(item_data.tags) do
		local key, value = tag:match("(%w+)=(%d+)")
		if key and value then
			local capitalized_key = key:sub(1, 1):upper() .. key:sub(2)
			output.add(capitalized_key .. ": " .. value .. "\n")
		end
	end
end

function examine.exec(command_parts, player, map_data, items_data, enemies_data, output, items, enemies, player_module)
	if not player_module.check_player_alive("examine", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify an item or enemy to examine (e.g., 'examine Goblin').\n")
		return player
	end
	local name = commands.get_item_name_from_parts(command_parts, 2)
	if not commands.validate_parameter(name, "name", output) then
		return player
	end
	local enemies_at_location = map_data[player.world].enemies[player.y][player.x]
	for enemy_name, _ in pairs(enemies_at_location) do
		if enemy_name:lower() == name:lower() then
			local enemy_data = enemies.get_enemy_data(enemies_data, enemy_name)
			if enemy_data then
				output.add(enemy_data.name .. ":\n\n")
				output.add(enemy_data.description .. "\n\n")
				output.add("Health: " .. enemy_data.health .. "\nAttack: " .. enemy_data.attack .. "\nDefense: " .. enemy_data.defense .. "\nExperience: " .. enemy_data.experience .. "\n")
				return player
			end
		end
	end
	local item_key = items.find_item_key(player.inventory, name, false)
	if item_key then
		local item_data = items.get_item_data(items_data, item_key)
		examine.display_item_info(item_key, item_data, output)
		return player
	end
	item_key = items.find_item_key(map_data[player.world].items[player.y][player.x], name, false)
	if item_key then
		local item_data = items.get_item_data(items_data, item_key)
		examine.display_item_info(item_key, item_data, output)
		return player
	end
	output.add("No item or enemy named " .. name .. " found.\n")
	return player
end

return examine