local kill = {}

function kill.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, player_module)
	if player.state ~= "overworld" then
		output.add("You cannot fight while inside a building.\n")
		return player, false
	end
	if #command_parts < 2 then
		output.add("Please specify an enemy to kill (e.g., 'kill Goblin').\n")
		return player, false
	end
	
	local enemy_name = commands.get_item_name_from_parts(command_parts, 2)
	local updated_player, success = combat.attack_enemy(enemy_name, map_data, player, enemies_data, items_data, skills_data, time, map, output, player_module)
	return updated_player, success
end

return kill