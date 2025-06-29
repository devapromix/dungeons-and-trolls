local magic = {}

function magic.load_spells_data()
	local spells_string = love.filesystem.read("assets/data/spells.json")
	if not spells_string then
		output.add("Error: Could not read spells.json.\n")
		return { spells = {} }
	end
	local spells_data = json.decode(spells_string)
	if not spells_data or not spells_data.spells then
		output.add("Error: Invalid spells.json format.\n")
		return { spells = {} }
	end
	return spells_data
end

function magic.get_spell_data(spell_name)
	local spells_data = magic.load_spells_data()
	for _, spell in ipairs(spells_data.spells) do
		if spell.name == spell_name then
			return spell
		end
	end
	return nil
end

function magic.learn_spell(player_data, items_data, item_name)
	if not player.check_player_alive("learn spell", player_data) then
		return player_data
	end
	local item_key = utils.find_item_key(player_data.inventory, item_name)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return player_data
	end
	local item_data = items.get_item_data(items_data, item_key)
	if not item_data or not items.has_tag(item_data, "spell") then
		output.add(item_name .. " is not a spellbook.\n")
		return player_data
	end
	local spell_name = utils.get_item_tag_value(item_data, "spell")
	if not spell_name then
		output.add("No spell associated with " .. item_name .. ".\n")
		return player_data
	end
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell " .. spell_name .. ".\n")
		return player_data
	end
	if player_data.spellbook[spell_name] then
		output.add("You already know the spell " .. spell_name .. ".\n")
		return player_data
	end
	if player_data.intelligence < spell_data.mana_cost then
		output.add("You need at least " .. spell_data.mana_cost .. " intelligence to learn " .. spell_name .. ".\n")
		return player_data
	end
	player_data.spellbook[spell_name] = 1
	player_data.inventory[item_key] = player_data.inventory[item_key] - 1
	if player_data.inventory[item_key] <= 0 then
		player_data.inventory[item_key] = nil
	end
	output.add("You learned the spell " .. spell_name .. "!\n")
	return player_data
end

return magic