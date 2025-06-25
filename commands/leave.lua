local leave = {}

function leave.exec(player, map_data)
	if not player_module.check_player_alive("leave a building", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You are not inside a building.\n")
		return player
	end

	player.state = "overworld"
	map.display_location(player, map_data)
	
	return player
end

return leave