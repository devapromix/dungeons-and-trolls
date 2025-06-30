local command_cast = {}

function command_cast.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, player_module, magic)
	if not player_module.check_player_alive("cast spell", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Usage: cast <spell_name> [enemy_name] (e.g., 'cast Fireball Goblin' or 'cast Heal')\n")
		return player
	end
	local spell_name = command_parts[2]
	local enemy_name = #command_parts > 2 and table.concat(command_parts, " ", 3) or nil
	return magic.cast_spell(player, map_data, items_data, enemies_data, skills_data, time, map, spell_name, enemy_name, player_module)
end

return command_cast