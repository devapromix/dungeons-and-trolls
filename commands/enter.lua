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
	if building == "shop" then
		player.state = "shop"
		output.add("You enter the shop. The shelves are filled with various goods for sale.\n")
	elseif building == "tavern" then
		player.state = "tavern"
		output.add("You enter the tavern. The warm glow of the hearth and the chatter of patrons welcome you.\n")
	else
		output.add("Unknown building: " .. building .. ". Try 'shop' or 'tavern'.\n")
		return player
	end
	return player
end

return enter