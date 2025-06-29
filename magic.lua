local magic = {}

function magic.load_spells_data()
	local spells_string = love.filesystem.read("assets/data/spells.json")
	if not spells_string then
		output.add("Error: Could not read spells.json. Check if file exists in assets/data/.\n")
		return { spells = {} }
	end
	local spells_data = json.decode(spells_string)
	if not spells_data or not spells_data.spells then
		output.add("Error: Invalid spells.json format. Expected { spells = { ... } }.\n")
		return { spells = {} }
	end
	if #spells_data.spells == 0 then
		output.add("Warning: spells.json contains no spells.\n")
	end
	return spells_data
end

function magic.get_spell_data(spell_name)
	local spells_data = magic.load_spells_data()
	for _, spell in ipairs(spells_data.spells) do
		if spell.name:lower() == spell_name:lower() then
			return spell
		end
	end
	output.add("Debug: No spell found matching '" .. spell_name .. "' in spells.json.\n")
	return nil
end

function magic.learn_spell(player_data, items_data, item_name, player_module)
	if not player_module.check_player_alive("learn spell", player_data) then
		return player_data
	end
	local item_data = items.get_item_data(items_data, item_name)
	if not item_data then
		output.add("No item found matching '" .. item_name .. "' in items data.\n")
		if items_data.items then
			local item_names = {}
			for _, item in ipairs(items_data.items) do
				table.insert(item_names, item.name)
			end
		end
		return player_data
	end
	local inventory_key
	for key, _ in pairs(player_data.inventory) do
		if key:lower() == item_name:lower() then
			inventory_key = key
			break
		end
	end
	if not inventory_key or player_data.inventory[inventory_key] <= 0 then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return player_data
	end
	local spell_name = utils.get_item_tag_value(item_data, "spell")
	if not spell_name then
		output.add(item_name .. " is not a spellbook.\n")
		return player_data
	end
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell " .. spell_name .. " in spells.json.\n")
		return player_data
	end
	if player_data.spellbook[spell_name] then
		output.add("You already know the spell " .. spell_name .. ".\n")
		return player_data
	end
	if player_data.mana < spell_data.mana_cost then
		output.add("You need at least " .. spell_data.mana_cost .. " mana to learn " .. spell_name .. ".\n")
		return player_data
	end
	player_data.mana = player_data.mana - spell_data.mana_cost
	player_data.spellbook[spell_name] = 1
	player_data.inventory[inventory_key] = player_data.inventory[inventory_key] - 1
	if player_data.inventory[inventory_key] <= 0 then
		player_data.inventory[inventory_key] = nil
	end
	output.add("You learned the spell " .. spell_name .. "!\n")
	return player_data
end

return magic