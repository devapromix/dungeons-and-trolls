local command_read = {}

function command_read.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, player_module, magic)
	if not player_module.check_player_alive("read", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a book or scroll to read (e.g., 'read Book of Fireball' or 'read Scroll of Heal' or 'read Scroll of Fireball Goblin').\n")
		return player
	end

	local item_parts = {}
	for i = 2, #command_parts do
		table.insert(item_parts, command_parts[i])
	end

	local item_name, enemy_name
	for i = #item_parts, 1, -1 do
		local potential_item = table.concat(item_parts, " ", 1, i)
		if items.get_item_data(items_data, potential_item) then
			item_name = potential_item
			if i < #item_parts then
				enemy_name = table.concat(item_parts, " ", i + 1)
			end
			break
		end
	end

	if not item_name then
		output.add("No item found matching '" .. table.concat(item_parts, " ") .. "' in items data.\n")
		return player
	end

	local item_data = items.get_item_data(items_data, item_name)
	if not item_data then
		output.add("No item found matching '" .. item_name .. "' in items data.\n")
		return player
	end
	local spell_name = utils.get_item_tag_value(item_data, "spell")
	if not spell_name then
		output.add("'" .. item_name .. "' is not a book or scroll.\n")
		return player
	end

	if items.has_tag(items_data, item_name, "scroll") then
		local spell_data = magic.get_spell_data(spell_name)
		if not spell_data then
			output.add("No data found for spell '" .. spell_name .. "'.\n")
			return player
		end
		if spell_data.type == "damage" or spell_data.type == "confuse" then
			if player.equipment then
				for _, item in pairs(player.equipment) do
					if item and item.broken then
						output.add("You cannot use '" .. item_name .. "' because you have broken equipment.\n")
						return player
					end
				end
			end
		end
		return magic.use_scroll(player, map_data, items_data, enemies_data, skills_data, time, map, item_name, spell_name, player_module, enemy_name)
	end
	return magic.learn_spell(player, items_data, item_name, player_module, enemy_name)
end

return command_read