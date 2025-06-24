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
		output.add("Please specify a building to enter (e.g., 'enter shop' or 'enter tavern').\n")
		return player
	end
	local building = command_parts[2]:lower()
	local interiors_data = map.load_interiors()
	for _, interior in ipairs(interiors_data.interiors or {}) do
		if interior.id == building then
			player.state = building
			output.add(interior.name .. "\n")
			output.add(interior.description .. "\n\n")
			return player
		end
	end
	output.add("Unknown building: " .. building .. ". Try 'shop' or 'tavern'.\n")
	return player
end

return enter