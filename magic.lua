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
	return nil
end

function magic.use_scroll(player_data, map_data, items_data, enemies_data, skills_data, time, map, item_name, spell_name, player_module)
	if not player_module.check_player_alive("use scroll", player_data) then
		return player_data
	end
	if player_data.state ~= "overworld" then
		output.add("You cannot use scrolls while inside a building.\n")
		return player_data
	end
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell '" .. spell_name .. "'.\n")
		return player_data
	end
	local mana_cost = spell_data.mana_cost / 2
	if player_data.mana < mana_cost then
		output.add("You need " .. mana_cost .. " mana to use '" .. item_name .. "'. You have " .. player_data.mana .. ".\n")
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
	player_data.mana = player_data.mana - mana_cost
	if spell_data.type == "heal" then
		player_data.health = utils.clamp(player_data.health + spell_data.value, 0, player_data.max_health)
		output.add("You used '" .. item_name .. "' and restored " .. spell_data.value .. " health.\n")
	elseif spell_data.type == "damage" then
		output.add("You cannot use a damage scroll without specifying an enemy. Use 'cast " .. spell_name .. " <enemy_name>' instead.\n")
		player_data.mana = player_data.mana + mana_cost
		return player_data
	else
		output.add("Spell '" .. spell_name .. "' has an unknown type.\n")
		player_data.mana = player_data.mana + mana_cost
		return player_data
	end
	player_data.inventory[inventory_key] = player_data.inventory[inventory_key] - 1
	if player_data.inventory[inventory_key] <= 0 then
		player_data.inventory[inventory_key] = nil
	end
	return player_data
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
		output.add(item_name .. " is not a book or scroll.\n")
		return player_data
	end
	if items.has_tag(items_data, item_name, "scroll") then
		return magic.use_scroll(player_data, map_data, items_data, enemies_data, skills_data, time, map, item_name, spell_name, player_module)
	end
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell " .. spell_name .. " in spells.json.\n")
		return player_data
	end
	if player_data.spellbook[spell_name] then
		player_data.spellbook[spell_name] = player_data.spellbook[spell_name] + spell_data.amount
		output.add("You reinforced the spell '" .. spell_name .. "'. Uses remaining: " .. player_data.spellbook[spell_name] .. ".\n")
	else
		if player_data.mana < spell_data.mana_cost * 2 then
			output.add("You need at least " .. spell_data.mana_cost * 2 .. " mana to learn '" .. spell_name .. "'.\n")
			return player_data
		end
		player_data.mana = player_data.mana - spell_data.mana_cost * 2
		player_data.spellbook[spell_name] = spell_data.amount
		output.add("You learned the spell '" .. spell_name .. "' with " .. spell_data.amount .. " uses!\n")
	end
	player_data.inventory[inventory_key] = player_data.inventory[inventory_key] - 1
	if player_data.inventory[inventory_key] <= 0 then
		player_data.inventory[inventory_key] = nil
	end
	return player_data
end

function magic.cast_spell(player_data, map_data, items_data, enemies_data, skills_data, time, map, spell_name, enemy_name, player_module)
	if not player_module.check_player_alive("cast spell", player_data) then
		return player_data
	end
	if player_data.state ~= "overworld" then
		output.add("You cannot cast spells while inside a building.\n")
		return player_data
	end
	if not player_data.spellbook[spell_name] then
		local found = false
		for known_spell, _ in pairs(player_data.spellbook) do
			if known_spell:lower() == spell_name:lower() then
				spell_name = known_spell
				found = true
				break
			end
		end
		if not found then
			output.add("You don't know the spell '" .. spell_name .. "'.\n")
			return player_data
		end
	end
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell '" .. spell_name .. "'.\n")
		return player_data
	end
	if player_data.mana < spell_data.mana_cost then
		output.add("You need " .. spell_data.mana_cost .. " mana to cast '" .. spell_name .. "'. You have " .. player_data.mana .. ".\n")
		return player_data
	end
	player_data.mana = player_data.mana - spell_data.mana_cost
	player_data.spellbook[spell_name] = player_data.spellbook[spell_name] - 1
	if spell_data.type == "heal" then
		player_data.health = utils.clamp(player_data.health + spell_data.value, 0, player_data.max_health)
		output.add("You cast '" .. spell_name .. "' and restored " .. spell_data.value .. " health.\n")
	elseif spell_data.type == "damage" then
		if not enemy_name then
			output.add("Please specify an enemy to target with '" .. spell_name .. "' (e.g., 'cast " .. spell_name .. " Goblin').\n")
			player_data.mana = player_data.mana + spell_data.mana_cost
			player_data.spellbook[spell_name] = player_data.spellbook[spell_name] + 1
			return player_data
		end
		local enemy = enemies.get_enemy_at_position(enemies_data, map_data[player_data.world], player_data.x, player_data.y, enemy_name)
		if not enemy then
			output.add("No " .. enemy_name .. " found at this location.\n")
			player_data.mana = player_data.mana + spell_data.mana_cost
			player_data.spellbook[spell_name] = player_data.spellbook[spell_name] + 1
			return player_data
		end
		enemies.apply_damage(enemy, spell_data.value)
		output.add("You cast '" .. spell_name .. "' and dealt " .. spell_data.value .. " damage to " .. enemy.name .. ".\n")
		if enemy.health <= 0 then
			output.add(enemy.name .. " has been defeated!\n")
			enemies.remove_enemy(map_data[player_data.world], player_data.x, player_data.y, enemy.name)
			player_data = player_module.add_experience(player_data, enemy.experience, output)
		else
			combat.attack_enemy(enemy.name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output, player_module, enemy)
		end
	else
		output.add("Spell '" .. spell_name .. "' has an unknown type.\n")
		player_data.mana = player_data.mana + spell_data.mana_cost
		player_data.spellbook[spell_name] = player_data.spellbook[spell_name] + 1
		return player_data
	end
	if player_data.spellbook[spell_name] <= 0 then
		output.add("You have forgotten the spell '" .. spell_name .. "'.\n")
		player_data.spellbook[spell_name] = nil
	end
	return player_data
end

return magic