local light = {}

function light.exec(player, player_module, map_data)
	if not player_module.check_player_alive("light a fire", player) then
		return player
	end
	if map_data[player.world].tiles[player.y][player.x] == "v" then
		output.add("You cannot light a fire in the village.\n")
		return player
	end
	if player.state ~= "overworld" then
		output.add("You cannot light a fire inside a building.\n")
		return player
	end
	fire.make_fire(player, player.world)
	return player
end

return light