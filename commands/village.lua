local village = {}

function village.exec(player, map_data, map)
	if not player_module.check_player_alive("teleport", player) then
		return player
	end
	if config.debug then
		player.world = "overworld"
		player.x = map_data.overworld.village.x
		player.y = map_data.overworld.village.y
		output.add("Teleported to village Dork!\n")
		map.update_visibility(player, map_data)
		map.display_location(player, map_data)
		return player
	else
		output.add("Command only available in debug mode.\n")
		return player
	end
end

return village