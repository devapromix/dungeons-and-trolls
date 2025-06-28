local command_read = {}

function command_read.exec(command_parts, player, items_data, player_module, spells)
	if not player_module.check_player_alive("read", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a spellbook to read (e.g., 'read Fireball Spellbook').\n")
		return player
	end
	local _, item_name = utils.parse_item_command(command_parts, 2, output)
	if not item_name then
		return player
	end
	player = spells.learn_spell(player, items_data, item_name)
	return player
end

return command_read