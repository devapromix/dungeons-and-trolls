local village = {}

function village.exec(player, map_data, map)
	if not player_module.check_player_alive("teleport", player) then
		return player
	end
	if config.debug then
		player = map.teleport_to_village(player, map_data)
		output.add("Teleported to village Dork!\n")
		return player
	else
		output.add("Command only available in debug mode.\n")
		return player
	end
end

return village