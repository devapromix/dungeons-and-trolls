local look = {}

function look.exec(player, map_data)
	if not player_module.check_player_alive("look around", player) then
		return player
	end
	map.display_location(player, map_data)
	return player
end

return look