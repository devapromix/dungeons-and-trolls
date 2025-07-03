local command_add = {}

function command_add.exec(command_parts, player, items_data, enemies_data, map_data, skills_data, player_module)
	if not config.debug then
		output.add("Command only available in debug mode.\n")
		return player
	end
	if not player_module.check_player_alive("add item, enemy or skill", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a quantity and item, enemy or skill to add (e.g., 'add 2 Healing Potion', 'add 3 Goblin', 'add 5 Swords').\n")
		return player
	end
	local quantity, name = utils.parse_item_command(command_parts, 2, output)
	if not quantity or not name then
		return player
	end
	local item_data = items.get_item_data(items_data, name)
	local enemy_data = enemies.get_enemy_data(enemies_data, name)
	local skill_data = skills.get_skill_data(skills_data, name)
	if item_data then
		local item_key = item_data.name
		local add_qty = math.floor(quantity)
		player.inventory[item_key] = (player.inventory[item_key] or 0) + add_qty
		output.add("Added " .. add_qty .. " " .. item_key .. " to inventory.\n")
		if item_data.file then
			utils.output_text_file(item_data.file)
		end
		if items.is_artifact(item_data) then
			output.add("You acquired the legendary " .. item_key .. "!\n")
		end
	elseif enemy_data then
		local enemy_key = enemy_data.name
		local add_qty = math.floor(quantity)
		map_data[player.world].enemies[player.y][player.x][enemy_key] = (map_data[player.world].enemies[player.y][player.x][enemy_key] or 0) + add_qty
		output.add("Added " .. add_qty .. " " .. enemy_key .. " to current location.\n")
	elseif skill_data then
		local skill_key = skill_data.name
		local add_qty = math.floor(quantity)
		player.skills[skill_key] = utils.clamp((player.skills[skill_key] or 0) + add_qty, 0, 40)
		output.add("Added " .. add_qty .. " to " .. skill_key .. " skill. Current level: " .. player.skills[skill_key] .. ".\n")
	else
		output.add("No item, enemy or skill found matching '" .. name .. "'.\n")
	end
	return player
end

return command_add