local fishing = {}

function get_fish_types(items_data)
	local	fish_types = {}
	for _, item in ipairs(items_data.items) do
		if commands.table_contains(item.tags, "fish") then
			table.insert(fish_types, item.name)
		end
	end
	return	fish_types
end

function fishing.exec(player, map_data, items_data, skills_data, time, output)
	if not player_module.check_player_alive("fish", player) then
		return player
	end
	local current_symbol = map_data[player.world].tiles[player.y][player.x]
	local location_data = map.get_location_description(current_symbol)
	if location_data.name ~= "River" and location_data.name ~= "Lake" then
		output.add("You can only fish in a river or lake.\n")
		return player
	end
	if not player.equipment or not player.equipment.weapon then
		output.add("You need to equip a Fishing Rod or Spear to fish.\n")
		return player
	end
	local item_data = items.get_item_data(items_data, player.equipment.weapon)
	if not item_data or (not commands.table_contains(item_data.tags, "fishing_rod") and player.equipment.weapon ~= "Spear") then
		output.add("You need to equip a Fishing Rod or Spear to fish.\n")
		return player
	end
	local success_chance = 0.15
	if commands.table_contains(item_data.tags, "fishing_rod") then
		local fishing_skill = player.skills and player.skills.Fishing or 0
		success_chance = 0.25 + (fishing_skill / 100)
	end
	if math.random() < success_chance then
		local fish_types = get_fish_types(items_data)
		if #fish_types == 0 then
			output.add("No fish available to catch.\n")
			return player
		end
		local caught_fish = fish_types[math.random(1, #fish_types)]
		player.inventory[caught_fish] = (player.inventory[caught_fish] or 0) + 1
		output.add("You caught a " .. caught_fish .. "!\n")
		if commands.table_contains(item_data.tags, "fishing_rod") and math.random() < 0.1 then
			skills.upgrade_skill(player, skills_data, {skill = "Fishing"})
		end
	else
		output.add("You failed to catch anything.\n")
	end
	time.tick_time(math.random(10, 20))
	return player
end

return fishing