local leave = {}

function leave.exec(command_parts, player, map_data)
	if not player_module.check_player_alive("leave a building", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You are not inside a building.\n")
		return player
	end
	if player.state == "shop" then
		player.state = "overworld"
		output.add("You leave the shop and return to the village.\n\n")
		map.display_location(player, map_data)
	elseif player.state == "tavern" then
		player.state = "overworld"
		output.add("You leave the tavern and return to the village.\n\n")
		map.display_location(player, map_data)
	end
	return player
end

return leave