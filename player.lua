local player = {}

function player.starter_kit(player_data)
	player_data.inventory = player_data.inventory or {}
	local starter_items = {}
	local function add_rand_items(item_name)
		starter_items[item_name] = math.random(2, 5)
	end
	local function add_rand_item(item_name)
		starter_items[item_name] = 1
	end
	add_rand_items("Firewood")
	add_rand_items("Apple")
	add_rand_items("Bread")
	add_rand_items("Water Bottle")
	if config.debug then
		add_rand_items("Hand Axe")
		add_rand_items("Raw Meat")
		add_rand_items("Mushroom")
		add_rand_item("Sacred Armor")
	end
	for item, quantity in pairs(starter_items) do
		player_data.inventory[item] = (player_data.inventory[item] or 0) + quantity
	end
	return player_data
end

function player.draw_status(player_data)
	local lines = {
		"Player:\n",
		"Level: " .. player_data.level .. "\n",
		"Experience: " .. player_data.experience .. "/" .. player.experience_to_next_level(player_data.level) .. "\n",
		"Level points: " .. player_data.levelpoints .. "\n\n",
		"Strength: " .. player_data.strength .. "\n",
		"Dexterity: " .. player_data.dexterity .. "\n",
		"Vitality: " .. player_data.vitality .. "\n",
		"Intelligence: " .. player_data.intelligence .. "\n\n",
		"Health: " .. player_data.health .. "/" .. player_data.max_health .. "\n",
		"Mana: " .. player_data.mana .. "/" .. player_data.max_mana .. "\n",
		"Hunger: " .. player_data.hunger .. "\n",
		"Thirst: " .. player_data.thirst .. "\n",
		"Fatigue: " .. player_data.fatigue .. "\n",
		"Attack: " .. player_data.attack .. "\n",
		"Defense: " .. player_data.defense .. "\n\n",
		"Position: " .. player_data.x .. ", " .. player_data.y .. " (" .. player_data.world .. ")\n\n",
	}
	if not player_data.alive then
		table.insert(lines, "\nYou are DEAD.\n\n")
		table.insert(lines, const.aliveSTART_NEW)
	end
	output.add(table.concat(lines))
	return player_data
end

function player.clamp_player_stats(player_data)
	player_data.health = utils.clamp(player_data.health, 0, player_data.max_health)
	player_data.mana = utils.clamp(player_data.mana, 0, player_data.max_mana)
	player_data.hunger = utils.clamp(player_data.hunger, 0, 100)
	player_data.fatigue = utils.clamp(player_data.fatigue, 0, 100)
	player_data.thirst = utils.clamp(player_data.thirst, 0, 100)
	player_data.attack = utils.clamp(player_data.attack, 0, math.huge)
	player_data.defense = utils.clamp(player_data.defense, 0, math.huge)
	player_data.strength = utils.clamp(player_data.strength, 0, 100)
	player_data.dexterity = utils.clamp(player_data.dexterity, 0, 100)
	player_data.vitality = utils.clamp(player_data.vitality, 0, 100)
	player_data.intelligence = utils.clamp(player_data.intelligence, 0, 100)
	return player_data
end

function player.clamp_player_skills(player_data, skills_data)
	if not player_data.skills then
		player_data.skills = {}
	end
	if not skills_data or not skills_data.skills then
		output.add("Error: No valid skills data provided.\n")
		return player_data
	end
	for _, skill in ipairs(skills_data.skills) do
		if skill and skill.name and skill.max_level then
			local initial_level = skill.initial_level or 0
			player_data.skills[skill.name] = utils.clamp(player_data.skills[skill.name] or initial_level, 0, skill.max_level)
		else
			output.add("Warning: Invalid skill entry in skills data.\n")
		end
	end
	return player_data
end

function player.get_skill_data(skills_data, skill_name)
	if not skills_data or not skills_data.skills or not skill_name then return nil end
	for _, skill in ipairs(skills_data.skills) do
		if skill.name == skill_name then
			return skill
		end
	end
	return nil
end

function player.update_max_health(player_data)
	player_data.max_health = player_data.vitality * 10
	player_data.health = utils.clamp(player_data.health, 0, player_data.max_health)
	return player_data
end

function player.update_max_mana(player_data)
	player_data.max_mana = player_data.intelligence * 10
	player_data.mana = utils.clamp(player_data.mana, 0, player_data.max_mana)
	return player_data
end

function player.equip_item(player_data, items_data, item_name)
	if not player.check_player_alive("equip items", player_data) then
		return player_data
	end
	local matches = {}
	for item, _ in pairs(player_data.inventory) do
		if item:lower():find(item_name:lower(), 1, true) then
			table.insert(matches, item)
		end
	end
	if #matches == 0 then
		output.add("You don't have any item matching '" .. item_name .. "' in your inventory.\n")
		return player_data
	elseif #matches > 1 then
		output.add("Multiple items match '" .. item_name .. "'. Please specify: " .. table.concat(matches, ", ") .. ".\n")
	end
	local item_key = utils.find_item_key(player_data.inventory, item_name)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return player_data
	end
	local item_key = matches[1]
	local item_data = items.get_item_data(items_data, item_key)
	if not item_data then
		output.add("No data found for " .. item_key .. ".\n")
		return player_data
	end
	local item_level = utils.get_item_tag_value(item_data, "level")
	if item_level and item_level > player_data.level then
		output.add("You need to be level " .. item_level .. " to equip " .. item_key .. ".\n")
		return player_data
	end
	local weapon_value = utils.get_item_tag_value(item_data, "weapon")
	local armor_value = utils.get_item_tag_value(item_data, "armor")
	if not weapon_value and not armor_value then
		output.add(item_key .. " cannot be equipped.\n")
		return player_data
	end
	player_data.equipment = player_data.equipment or {}
	player_data.equipment_status = player_data.equipment_status or { weapon = "", armor = "" }
	if weapon_value then
		if player_data.equipment.weapon then
			local current_weapon_data = items.get_item_data(items_data, player_data.equipment.weapon)
			if current_weapon_data then
				local current_weapon_value = utils.get_item_tag_value(current_weapon_data, "weapon")
				if current_weapon_value then
					player_data.attack = player_data.attack - current_weapon_value
				end
			end
		end
		player_data.equipment.weapon = item_key
		player_data.equipment_status.weapon = ""
		player_data.attack = player_data.attack + weapon_value
		output.add("You equipped " .. item_key .. ".\n")
	elseif armor_value then
		if player_data.equipment.armor then
			local current_armor_data = items.get_item_data(items_data, player_data.equipment.armor)
			if current_armor_data then
				local current_armor_value = utils.get_item_tag_value(current_armor_data, "armor")
				if current_armor_value then
					player_data.defense = player_data.defense - current_armor_value
				end
			end
		end
		player_data.equipment.armor = item_key
		player_data.equipment_status.armor = ""
		player_data.defense = player_data.defense + armor_value
		output.add("You equipped " .. item_key .. ".\n")
	end
	return player_data
end

function player.unequip_item(player_data, items_data, identifier)
	if not player.check_player_alive("unequip items", player_data) then
		return player_data
	end
	local slot
	if identifier:lower() == "weapon" then
		slot = "weapon"
	elseif identifier:lower() == "armor" then
		slot = "armor"
	else
		local matches = {}
		for item, _ in pairs(player_data.inventory) do
			if item:lower():find(identifier:lower(), 1, true) then
				table.insert(matches, item)
			end
		end
		if #matches == 0 then
			output.add("No item matching '" .. identifier .. "' is equipped.\n")
			return player_data
		elseif #matches > 1 then
			output.add("Multiple items match '" .. identifier .. "'. Please specify: " .. table.concat(matches, ", ") .. ".\n")
			return player_data
		end
		local item_key = matches[1]
		slot = player_data.equipment and (player_data.equipment.weapon == item_key and "weapon" or player_data.equipment.armor == item_key and "armor")
	end
	if not slot then
		output.add(identifier .. " is not equipped or invalid slot specified.\n")
		return player_data
	end
	if not player_data.equipment or not player_data.equipment[slot] then
		output.add("No " .. slot .. " is currently equipped.\n")
		return player_data
	end
	if player_data.equipment_status and player_data.equipment_status[slot] ~= "" then
		output.add("You cannot unequip " .. player_data.equipment[slot] .. " because it has a '" .. player_data.equipment_status[slot] .. "'.\n")
		return player_data
	end
	local equipped_item = player_data.equipment[slot]
	local item_data = items.get_item_data(items_data, equipped_item)
	if not item_data then
		output.add("No data found for " .. equipped_item .. ".\n")
		return player_data
	end
	local tag_value = utils.get_item_tag_value(item_data, slot)
	if tag_value then
		if slot == "weapon" then
			player_data.attack = player_data.attack - tag_value
		else
			player_data.defense = player_data.defense - tag_value
		end
		player_data.equipment[slot] = nil
		player_data.equipment_status[slot] = ""
		output.add("You unequipped " .. equipped_item .. ".\n")
	end
	return player_data
end

function player.check_player_status(player_data)
	player_data = player.clamp_player_stats(player_data)
	if player_data.hunger >= 100 then
		player_data.hunger = utils.clamp(player_data.hunger, 0, 100)
		player_data.alive = false
		return "You died from starvation.\n"
	elseif player_data.fatigue >= 100 then
		player_data.fatigue = utils.clamp(player_data.fatigue, 0, 100)
		player_data.alive = false
		return "You died from exhaustion.\n"
	elseif player_data.health <= 0 then
		player_data.health = utils.clamp(player_data.health, 0, player_data.max_health)
		player_data.alive = false
		return "You died from injuries.\n"
	elseif player_data.thirst >= 100 then
		player_data.thirst = utils.clamp(player_data.thirst, 0, 100)
		player_data.alive = false
		return "You died from thirst.\n"
	end
	return ""
end

function player.check_player_alive(action, player_data)
	if not player_data.alive then
		output.add("You are DEAD and cannot " .. action .. ".\n\n")
		output.add(const.START_NEW_GAME_MSG)
		return false
	end
	return true
end

function player.experience_to_next_level(value)
	if value <= 1 then
		return 120
	end
	return (value * 120) + ((value - 1) * 120)
end

function player.add_experience(player_data, experience, output)
	player_data.experience = player_data.experience + experience
	output.add("Gained " .. experience .. " experience.\n")
	while player_data.experience >= player.experience_to_next_level(player_data.level) do
		player_data.experience = player_data.experience - player.experience_to_next_level(player_data.level)
		player_data.level = player_data.level + 1
		player_data.levelpoints = player_data.levelpoints + 3
		player_data.health = player_data.max_health
		player_data.mana = player_data.max_mana
		player_data.fatigue = 0
		output.add("Congratulations! You reached level " .. player_data.level .. "! Gained 3 level points.\n")
	end
	return player_data
end

function player.initialize_player(config)
	local player_data = {
		x = math.floor(config.map.width / 2),
		y = math.floor(config.map.height / 2),
		world = "overworld",
		state = "overworld",
		symbol = "@",
		health = 0,
		max_health = 0,
		mana = 0,
		max_mana = 0,
		hunger = 0,
		fatigue = 0,
		thirst = 0,
		attack = 5,
		defense = 3,
		alive = true,
		gold = 0,
		inventory = { ["Short Sword"] = 1, ["Leather Armor"] = 1 },
		equipment = { weapon = "Short Sword", armor = "Leather Armor" },
		equipment_status = { weapon = "", armor = "" },
		skills = {},
		spellbook = {},
		radius = 3,
	 Kyrie = "@",
		level = 1,
		experience = 0,
		levelpoints = 0,
		strength = 10,
		dexterity = 10,
		vitality = 10,
		intelligence = 10
	}
	player_data = player.update_max_health(player_data)
	player_data = player.update_max_mana(player_data)
	player_data.health = player_data.max_health
	player_data.mana = player_data.max_mana
	player_data = player.starter_kit(player_data)
	player_data = player.clamp_player_stats(player_data)
	return player_data
end

function player.has_chop_item(player, items_data)
	if not player.equipment or not player.equipment.weapon then
		return false
	end
	return items.has_tag(items_data, player.equipment.weapon, "chop")
end

function player.add_hunger(player_data, value)
	player_data.hunger = utils.clamp(player_data.hunger + value, 0, 100)
	if player_data.hunger >= 100 then
		player_data.alive = false
		output.add("You are DEAD!.\n\n")
		output.add(const.START_NEW_GAME_MSG)
	end
end

function player.add_thirst(player_data, value)
	player_data.thirst = utils.clamp(player_data.thirst + value, 0, 100)
	if player_data.thirst >= 100 then
		player_data.alive = false
		output.add("You are DEAD!.\n\n")
		output.add(const.START_NEW_GAME_MSG)
	end
end

function player.add_fatigue(player_data, value)
	player_data.fatigue = utils.clamp(player_data.fatigue + value, 0, 100)
	if player_data.fatigue >= 100 then
		player_data.alive = false
		output.add("You are DEAD!.\n\n")
		output.add(const.START_NEW_GAME_MSG)
	end
end

return player