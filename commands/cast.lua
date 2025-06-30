local command_cast = {}

function command_cast.exec(command_parts, player, map_data, enemies_data, player_module, magic, enemies)
	if not player_module.check_player_alive("cast spell", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Usage: cast <spell_name> (e.g., 'cast Fireball')\n")
		return player
	end
	local spell_name = table.concat(command_parts, " ", 2)
	return magic.cast_spell(player, map_data, enemies_data, spell_name, player_module, enemies)
end

return command_cast