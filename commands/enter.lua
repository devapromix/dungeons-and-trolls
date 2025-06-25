local enter = {}

function enter.exec(command_parts, player, map_data)
	if not player_module.check_player_alive("enter a building", player) then
		return player
	end
	if player.state ~= "overworld" then
		output.add("You are already inside a building.\n")
		return player
	end
	if map_data[player.world].tiles[player.y][player.x] ~= "v" then
		output.add("You must be in a village to enter a shop or tavern.\n")
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a building to enter:\n")
		output.add("- enter weapon shop\n")
		output.add("- enter armor shop\n")
		output.add("- enter magic shop\n")
		output.add("- enter tavern\n")
		return player
	end
	
	local building_parts = {}
	for i = 2, #command_parts do
		table.insert(building_parts, command_parts[i]:lower())
	end
	local building = table.concat(building_parts, " ")
	
	local aliases = {
		["shop"] = "weapon shop",
		["weapon"] = "weapon shop",
		["armor"] = "armor shop",
		["magic"] = "magic shop",
		["tavern"] = "tavern"
	}
	
	if aliases[building] then
		building = aliases[building]
	end
	
	local interiors_data = map.load_interiors()
	for _, interior in ipairs(interiors_data.interiors or {}) do
		if interior.id == building then
			player.state = building
			output.add(interior.name .. "\n")
			if interior.description and interior.description ~= "" then
				output.add(interior.description .. "\n")
			end
			if building == "tavern" then
				local items_data = items.load_items()
				output.add(items.get_tavern_items_string(items_data))
			end
			output.add("\n")
			return player
		end
	end
	
	output.add("Unknown building: " .. building .. "\n")
	output.add("Available buildings:\n")
	output.add("- weapon shop\n")
	output.add("- armor shop\n")
	output.add("- magic shop\n")
	output.add("- tavern\n")
	return player
end

return enter