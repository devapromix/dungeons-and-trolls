local fishing = {}

function fishing.exec(player, map_data, items_data, skills_data, time, output)
	if not player_module.check_player_alive("fish", player) then
		return player
	end
	local current_symbol = map_data[player.world].tiles[player.y][player.x]
	local location_data = map.get_location_description(current_symbol)
	if location_data.name ~= "River" then
		output.add("You can only fish in a river.\n")
		return player
	end
	if not player.equipment or not player.equipment.weapon then
		output.add("You need to equip a Fishing Rod to fish.\n")
		return player
	end
	local item_data = items.get_item_data(items_data, player.equipment.weapon)
	if not item_data or not commands.table_contains(item_data.tags, "fishing_rod") then
		output.add("You need to equip a Fishing Rod to fish.\n")
		return player
	end
	local fishing_skill = player.skills and player.skills.Fishing or 0
	local success_chance = 0.25 + (fishing_skill / 100)
	if math.random() < success_chance then
		local fish_types = {"Silver Pike", "Roach", "Zander"}
		local caught_fish = fish_types[math.random(1, #fish_types)]
		player.inventory[caught_fish] = (player.inventory[caught_fish] or 0) + 1
		output.add("You caught a " .. caught_fish .. "!\n")
		if math.random() < 0.1 then
			skills.upgrade_skill(player, skills_data, {skill = "Fishing"})
		end
	else
		output.add("You failed to catch anything.\n")
	end
	time.tick_time(math.random(10, 20))
	return player
end

return fishing