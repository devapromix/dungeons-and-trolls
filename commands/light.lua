local light = {}

function light.exec(player, player_module, map_data)
	if not player_module.check_player_alive("light a fire", player) then
		return player
	end
	items.make_fire_item(player, map_data, player.world)
	return player
end

return light