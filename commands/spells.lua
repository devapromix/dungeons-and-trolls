local command_spells = {}

function command_spells.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("view spells", player) then
		return player
	end
	local lines = {}
	if next(player.spellbook) then
		table.insert(lines, "Spellbook (" .. player.mana .. "/" .. player.max_mana .. "):\n")
		for spell_name, amount in pairs(player.spellbook) do
			local spell_data = magic.get_spell_data(spell_name)
			local mana_cost = spell_data and spell_data.mana_cost or "Unknown"
			table.insert(lines, spell_name .. " (Mana: " .. mana_cost .. ", Uses: " .. amount .. ")\n")
		end
	else
		table.insert(lines, "You have not learned any spells yet.\n")
	end
	output.add(table.concat(lines))
	return player
end

return command_spells