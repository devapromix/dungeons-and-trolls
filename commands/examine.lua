local examine = {}

function examine.display_item_info(item_key, item_data, status)
	output.add(item_key .. ":\n\n")
	output.add(item_data.description .. "\n\n")
	
	local attributes = {}
	local locations = {}
	for _, tag in ipairs(item_data.tags) do
		local key, value = tag:match("(%w+)=(%d+)")
		if key and value then
			local capitalized_key = key:sub(1, 1):upper() .. key:sub(2)
			table.insert(attributes, capitalized_key .. ": " .. value)
		else
			if tag ~= "artifact" then
				table.insert(locations, tag)
			end
		end
	end
	
	if item_data.skill then
		table.insert(attributes, "Skill: " .. item_data.skill)
	end
	
	if status and status ~= "" then
		table.insert(attributes, "Status: " .. status:sub(1, 1):upper() .. status:sub(2))
	end
	
	if #attributes > 0 then
		for _, attr in ipairs(attributes) do
			output.add(attr .. "\n")
		end
	end
	
	if #locations > 0 then
		output.add("Available at: " .. table.concat(locations, ", ") .. "\n")
	end
	
	if items.is_artifact(item_data) then
		output.add("Type: Artifact\n")
	end
end

function examine.exec(command_parts, player, map_data, items_data, enemies_data, items, enemies, player_module)
	if not player_module.check_player_alive("examine", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify an item or enemy to examine (e.g., 'examine Goblin').\n")
		return player
	end
	local name = commands.get_item_name_from_parts(command_parts, 2)
	if #name < 3 then
		output.add("Name '" .. name .. "' must be at least 3 characters long.\n")
		return player
	end
	local enemies_at_location = map_data[player.world].enemies[player.y][player.x]
	for enemy_name, _ in pairs(enemies_at_location) do
		if utils.equals(enemy_name, name) then
			local enemy_data = enemies.get_enemy_data(enemies_data, enemy_name)
			if enemy_data then
				output.add(enemy_data.name .. ":\n\n")
				output.add(enemy_data.description .. "\n\n")
				output.add("Health: " .. enemy_data.health .. "\nAttack: " .. enemy_data.attack .. "\nDefense: " .. enemy_data.defense .. "\nExperience: " .. enemy_data.experience .. "\n")
				return player
			end
		end
	end
	
	if name:lower() == "weapon" or name:lower() == "armor" then
		local slot = name:lower()
		if player.equipment and player.equipment[slot] then
			local item_key = player.equipment[slot]
			local item_data = items.get_item_data(items_data, item_key)
			local status = player.equipment_status and player.equipment_status[slot] or nil
			examine.display_item_info(item_key, item_data, status)
			return player
		else
			output.add("No item equipped in " .. slot .. " slot.\n")
			return player
		end
	end

	local item_key = utils.find_item_key(player.inventory, name, false)
	if item_key then
		local item_data = items.get_item_data(items_data, item_key)
		local status = nil
		if player.equipment and player.equipment_status then
			if item_key == player.equipment.weapon then
				status = player.equipment_status.weapon
			elseif item_key == player.equipment.armor then
				status = player.equipment_status.armor
			end
		end
		examine.display_item_info(item_key, item_data, status)
		return player
	end
	item_key = utils.find_item_key(map_data[player.world].items[player.y][player.x], name, false)
	if item_key then
		local item_data = items.get_item_data(items_data, item_key)
		examine.display_item_info(item_key, item_data)
		return player
	end
	output.add("No item or enemy named " .. name .. " found.\n")
	return player
end

return examine