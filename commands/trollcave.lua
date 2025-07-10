local trollcave = {}

function trollcave.exec(player, map_data, map)
	if not player_module.check_player_alive("teleport", player) then
		return player
	end
	if config.debug then
		player.world = "underworld"
		player.x = map_data.underworld.troll_cave.x
		player.y = map_data.underworld.troll_cave.y
		output.add("\nTeleported to Troll Cave!\n")
		map.update_visibility(player, map_data)
		map.display_location(player, map_data)
		return player
	else
		output.add("Command only available in debug mode.\n")
		return player
	end
end

return trollcave