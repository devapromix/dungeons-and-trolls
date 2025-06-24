local leave = {}

function leave.exec(player, map_data)
	if not player_module.check_player_alive("leave a building", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You are not inside a building.\n")
		return player
	end

	local buildings = {
		["weapon shop"] = "weapon shop",
		["armor shop"] = "armor shop", 
		["magic shop"] = "magic shop",
		["tavern"] = "tavern",
		["shop"] = "shop"
	}
	
	if buildings[player.state] then
		local current_location = player.state
		player.state = "overworld"
		if current_location == "tavern" then
			output.add("You leave the tavern and return to the village.\n\n")
		else
			output.add("You leave the shop and return to the village.\n\n")
		end
		map.display_location(player, map_data)
	else
		output.add("Unknown location state: " .. tostring(player.state) .. "\n")
		player.state = "overworld"
		map.display_location(player, map_data)
	end
	
	return player
end

return leave