local magic = {}

local spells_cache = nil

function magic.load_spells()
	if spells_cache then
		return spells_cache
	end
	
	local spells_string = love.filesystem.read("assets/data/spells.json")
	if not spells_string then
		output.add("Error: Could not read spells.json. Check if file exists in assets/data/.\n")
		spells_cache = { spells = {} }
		return spells_cache
	end
	
	local spells_data = json.decode(spells_string)
	if not spells_data or not spells_data.spells then
		output.add("Error: Invalid spells.json format. Expected { spells = { ... } }.\n")
		spells_cache = { spells = {} }
		return spells_cache
	end
	
	if #spells_data.spells == 0 then
		output.add("Warning: spells.json contains no spells.\n")
	end
	
	spells_cache = spells_data
	return spells_cache
end

function magic.clear_cache()
	spells_cache = nil
end

function magic.get_spell_data(spell_name)
	local spells_data = magic.load_spells()
	for _, spell in ipairs(spells_data.spells) do
		if utils.equals(spell.name, spell_name) then
			return spell
		end
	end
	return nil
end

local function find_inventory_item(inventory, item_name)
	for key, quantity in pairs(inventory) do
		if utils.equals(key, item_name) and quantity > 0 then
			return key
		end
	end
	return nil
end

local function consume_mana(player_data, mana_cost, spell_name, item_name)
	if player_data.mana < mana_cost then
		local item_or_spell = item_name or spell_name
		output.add("You need " .. mana_cost .. " mana to use '" .. item_or_spell .. "'. You have " .. player_data.mana .. ".\n")
		return false
	end
	player_data.mana = player_data.mana - mana_cost
	return true
end

local function refund_mana(player_data, mana_cost)
	player_data.mana = player_data.mana + mana_cost
end

local function consume_inventory_item(player_data, inventory_key)
	player_data.inventory[inventory_key] = player_data.inventory[inventory_key] - 1
	if player_data.inventory[inventory_key] <= 0 then
		player_data.inventory[inventory_key] = nil
	end
end

local function handle_heal_spell(player_data, spell_data, spell_name, item_name)
	player_data.health = utils.clamp(player_data.health + spell_data.value, 0, player_data.max_health)
	local source = item_name or spell_name
	output.add("You " .. (item_name and "used" or "cast") .. " '" .. source .. "' and restored " .. spell_data.value .. " health.\n")
end

local function handle_teleport_spell(player_data, map_data, spell_name, item_name)
	player_data = map.teleport_to_village(player_data, map_data)
	local source = item_name or spell_name
	output.add("You " .. (item_name and "used" or "cast") .. " '" .. source .. "' and teleported to the village.\n")
	return player_data
end

local function handle_confuse_spell(player_data, map_data, enemies_data, spell_data, spell_name, enemy_name, item_name, mana_cost, spellbook_key)
	if not enemy_name then
		local source = item_name or spell_name
		local action = item_name and "read" or "cast"
		output.add("Please specify an enemy to target with '" .. source .. "' (e.g., '" .. action .. " " .. source .. " Goblin').\n")
		refund_mana(player_data, mana_cost)
		if spellbook_key then
			player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] + 1
		end
		return player_data, false
	end
	
	local enemy = enemies.get_enemy_at_position(enemies_data, map_data[player_data.world], player_data.x, player_data.y, enemy_name)
	if not enemy then
		output.add("No " .. enemy_name .. " found at this location.\n")
		refund_mana(player_data, mana_cost)
		if spellbook_key then
			player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] + 1
		end
		return player_data, false
	end
	
	enemy.status.confused = spell_data.value
	local source = item_name or spell_name
	output.add("You " .. (item_name and "used" or "cast") .. " '" .. source .. "' and confused " .. enemy.name .. " for " .. spell_data.value .. " turns.\n")
	
	combat.attack_enemy(enemy.name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output, player_module, enemy)
	
	return player_data, true
end

local function handle_damage_spell(player_data, map_data, items_data, enemies_data, skills_data, time, map, player_module, spell_data, spell_name, enemy_name, item_name, mana_cost, spellbook_key)
	if not enemy_name then
		local source = item_name or spell_name
		local action = item_name and "read" or "cast"
		output.add("Please specify an enemy to target with '" .. source .. "' (e.g., '" .. action .. " " .. source .. " Goblin').\n")
		refund_mana(player_data, mana_cost)
		if spellbook_key then
			player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] + 1
		end
		return player_data, false
	end
	
	local enemy = enemies.get_enemy_at_position(enemies_data, map_data[player_data.world], player_data.x, player_data.y, enemy_name)
	if not enemy then
		output.add("No " .. enemy_name .. " found at this location.\n")
		refund_mana(player_data, mana_cost)
		if spellbook_key then
			player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] + 1
		end
		return player_data, false
	end
	
	enemies.apply_damage(enemy, spell_data.value)
	local source = item_name or spell_name
	output.add("You " .. (item_name and "used" or "cast") .. " '" .. source .. "' and dealt " .. spell_data.value .. " damage to " .. enemy.name .. ".\n")
	
	if enemy.health <= 0 then
		output.add(enemy.name .. " has been defeated!\n")
		enemies.remove_enemy(map_data[player_data.world], player_data.x, player_data.y, enemy.name)
		player_data = player_module.add_experience(player_data, enemy.experience, output)
	else
		combat.attack_enemy(enemy.name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output, player_module, enemy)
	end
	
	return player_data, true
end

function magic.use_scroll(player_data, map_data, items_data, enemies_data, skills_data, time, map, item_name, spell_name, player_module, enemy_name)
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
	if not consume_mana(player_data, mana_cost, nil, item_name) then
		return player_data
	end
	
	local inventory_key = find_inventory_item(player_data.inventory, item_name)
	if not inventory_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		refund_mana(player_data, mana_cost)
		return player_data
	end
	
	local success = true
	
	if spell_data.type == "heal" then
		handle_heal_spell(player_data, spell_data, spell_name, item_name)
	elseif spell_data.type == "damage" then
		player_data, success = handle_damage_spell(player_data, map_data, items_data, enemies_data, skills_data, time, map, player_module, spell_data, spell_name, enemy_name, item_name, mana_cost)
	elseif spell_data.type == "teleport" then
		player_data = handle_teleport_spell(player_data, map_data, spell_name, item_name)
	elseif spell_data.type == "confuse" then
		player_data, success = handle_confuse_spell(player_data, map_data, enemies_data, spell_data, spell_name, enemy_name, item_name, mana_cost)
	else
		output.add("Spell '" .. spell_name .. "' has an unknown type.\n")
		refund_mana(player_data, mana_cost)
		return player_data
	end
	
	if success then
		consume_inventory_item(player_data, inventory_key)
	end
	
	return player_data
end

function magic.learn_spell(player_data, items_data, item_name, player_module, enemy_name)
	if not player_module.check_player_alive("learn spell", player_data) then
		return player_data
	end
	
	local item_data = items.get_item_data(items_data, item_name)
	if not item_data then
		output.add("No item found matching '" .. item_name .. "' in items data.\n")
		return player_data
	end
	
	local inventory_key = find_inventory_item(player_data.inventory, item_name)
	if not inventory_key then
		output.add("You don't have '" .. item_name .. "' in your inventory.\n")
		return player_data
	end
	
	local spell_name = utils.get_item_tag_value(item_data, "spell")
	if not spell_name then
		output.add("'" .. item_name .. "' is not a book or scroll.\n")
		return player_data
	end
	
	if items.has_tag(items_data, item_name, "scroll") then
		return magic.use_scroll(player_data, map_data, items_data, enemies_data, skills_data, time, map, item_name, spell_name, player_module, enemy_name)
	end
	
	local spell_data = magic.get_spell_data(spell_name)
	if not spell_data then
		output.add("No data found for spell " .. spell_name .. " in spells.json.\n")
		return player_data
	end
	
	local existing_spell_key = nil
	for known_spell, _ in pairs(player_data.spellbook) do
		if utils.equals(known_spell, spell_name) then
			existing_spell_key = known_spell
			break
		end
	end
	
	if existing_spell_key then
		player_data.spellbook[existing_spell_key] = player_data.spellbook[existing_spell_key] + spell_data.amount
		output.add("You reinforced the spell '" .. existing_spell_key .. "'. Uses remaining: " .. player_data.spellbook[existing_spell_key] .. ".\n")
	else
		local learning_cost = spell_data.mana_cost * 2
		if not consume_mana(player_data, learning_cost, spell_name) then
			return player_data
		end
		player_data.spellbook[spell_name] = spell_data.amount
		output.add("You learned the spell '" .. spell_name .. "' with " .. spell_data.amount .. " uses!\n")
	end
	
	consume_inventory_item(player_data, inventory_key)
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
	
	local spellbook_key = nil
	for known_spell, uses in pairs(player_data.spellbook) do
		if utils.equals(known_spell, spell_name) and uses > 0 then
			spellbook_key = known_spell
			break
		end
	end
	
	if not spellbook_key then
		output.add("You don't know the spell '" .. spell_name .. "'.\n")
		return player_data
	end
	
	local spell_data = magic.get_spell_data(spellbook_key)
	if not spell_data then
		output.add("No data found for spell '" .. spellbook_key .. "'.\n")
		return player_data
	end
	
	if not consume_mana(player_data, spell_data.mana_cost, spellbook_key) then
		return player_data
	end
	
	player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] - 1
	local success = true
	
	if spell_data.type == "heal" then
		handle_heal_spell(player_data, spell_data, spellbook_key)
	elseif spell_data.type == "damage" then
		player_data, success = handle_damage_spell(player_data, map_data, items_data, enemies_data, skills_data, time, map, player_module, spell_data, spellbook_key, enemy_name, nil, spell_data.mana_cost, spellbook_key)
	elseif spell_data.type == "teleport" then
		player_data = handle_teleport_spell(player_data, map_data, spellbook_key)
	elseif spell_data.type == "confuse" then
		player_data, success = handle_confuse_spell(player_data, map_data, enemies_data, spell_data, spellbook_key, enemy_name, nil, spell_data.mana_cost, spellbook_key)
	else
		output.add("Spell '" .. spellbook_key .. "' has an unknown type.\n")
		refund_mana(player_data, spell_data.mana_cost)
		player_data.spellbook[spellbook_key] = player_data.spellbook[spellbook_key] + 1
		return player_data
	end
	
	if not success then
		return player_data
	end
	
	if player_data.spellbook[spellbook_key] <= 0 then
		output.add("You have forgotten the spell '" .. spellbook_key .. "'.\n")
		player_data.spellbook[spellbook_key] = nil
	end
	
	return player_data
end

return magic