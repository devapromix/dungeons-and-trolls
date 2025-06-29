local command_spells = {}

function command_spells.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("view spells", player) then
		return player
	end
	local lines = {}
	if next(player.spellbook) then
		table.insert(lines, "Spellbook:\n")
		for spell_name, level in pairs(player.spellbook) do
			table.insert(lines, spell_name .. ": Level " .. level .. "\n")
		end
	else
		table.insert(lines, "You have not learned any spells yet.\n")
	end
	output.add(table.concat(lines))
	return player
end

return command_spells