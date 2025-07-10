local command_cast = {}

function command_cast.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, player_module, magic)
	if not player_module.check_player_alive("cast spell", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify spell to cast (e.g., 'cast Fireball Goblin' or 'cast Heal').\n")
		return player
	end
	local spell_name = command_parts[2]
	local enemy_name = #command_parts > 2 and table.concat(command_parts, " ", 3) or nil

	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell '" .. spell_name .. "'.\n")
		return player
	end
	if spell_data.type == "damage" or spell_data.type == "confuse" then
		if player.equipment then
			for _, item in pairs(player.equipment) do
				if item and item.broken then
					output.add("You cannot cast '" .. spell_name .. "' because you have broken equipment.\n")
					return player
				end
			end
		end
	end

	player = magic.cast_spell(player, map_data, items_data, enemies_data, skills_data, time, map, spell_name, enemy_name, player_module)
	return player
end

return command_cast