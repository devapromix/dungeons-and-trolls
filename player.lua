local player = {}

function player.starter_kit(player_data)
	player_data.inventory = player_data.inventory or {}
	player_data.strength = 10
	player_data.dexterity = 10
	player_data.willpower = 10
	player_data.intelligence = 10
	player_data.perception = 10
	player_data.levelpoints = 0
	
	local starter_items = {}    

	local function add_rand_item(item_name)
		starter_items[item_name] = math.random(1, 3)
	end

	add_rand_item("Firewood")
	add_rand_item("Bread")
	add_rand_item("Water Bottle")
	if config.debug then
		add_rand_item("Raw Meat")
		add_rand_item("Apple")
		add_rand_item("Mushroom")
		add_rand_item("Sacred Armor")
		add_rand_item("Sword of Dawn")
	end
	
	for item, quantity in pairs(starter_items) do
		player_data.inventory[item] = (player_data.inventory[item] or 0) + quantity
	end
	
	return player_data
end

function player.draw_status(player_data)
	output.add("Player:\n")
	output.add("Level: " .. player_data.level .. "\n")
	output.add("Experience: " .. player_data.experience .. "/" .. player.experience_to_next_level(player_data.level) .. "\n")
	output.add("Level Points: " .. player_data.levelpoints .. "\n\n")
	output.add("Strength: " .. player_data.strength .. "\n")
	output.add("Dexterity: " .. player_data.dexterity .. "\n")
	output.add("Willpower: " .. player_data.willpower .. "\n")
	output.add("Intelligence: " .. player_data.intelligence .. "\n")
	output.add("Perception: " .. player_data.perception .. "\n\n")
	output.add("Health: " .. player_data.health .. "\n")
	output.add("Mana: " .. player_data.mana .. "\n")
	output.add("Hunger: " .. player_data.hunger .. "\n")
	output.add("Thirst: " .. player_data.thirst .. "\n")
	output.add("Fatigue: " .. player_data.fatigue .. "\n")
	output.add("Attack: " .. player_data.attack .. "\n")
	output.add("Defense: " .. player_data.defense .. "\n\n")
	output.add("Gold: " .. player_data.gold .. "\n")
	output.add("Position: " .. player_data.x .. ", " .. player_data.y .. " (" .. player_data.world .. ")\n\n")
	output.add("Equipment:\n")
	output.add("Weapon: " .. (player_data.equipment and player_data.equipment.weapon or "None") .. "\n")
	output.add("Armor: " .. (player_data.equipment and player_data.equipment.armor or "None") .. "\n\n")
	if not player_data.alive then
		output.add("\nYou are DEAD.\n\n")
		output.add(const.START_NEW_GAME_MSG)
	end
end

function player.clamp_player_stats(player_data)
	player_data.health = utils.clamp(player_data.health, 0, 100)
	player_data.mana = utils.clamp(player_data.mana, 0, 100)
	player_data.hunger = utils.clamp(player_data.hunger, 0, 100)
	player_data.fatigue = utils.clamp(player_data.fatigue, 0, 100)
	player_data.thirst = utils.clamp(player_data.thirst, 0, 100)
	player_data.attack = utils.clamp(player_data.attack, 0, math.huge)
	player_data.defense = utils.clamp(player_data.defense, 0, math.huge)
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

function player.rest(player_data, map_data, game_time, time)
	if player_data.health >= 100 and player_data.mana >= 100 and player_data.fatigue <= 0 then
		output.add("You don't need to rest.\n")
		return player_data
	end
	local hours_to_full = math.max(
		math.ceil((100 - player_data.health) / 10),
		math.ceil((100 - player_data.mana) / 10),
		math.ceil(player_data.fatigue / 10)
	)
	local hours_to_morning = 0
	if game_time.hour >= 18 then
		hours_to_morning = (24 - game_time.hour) + 6
	elseif game_time.hour < 6 then
		hours_to_morning = 6 - game_time.hour
	end
	local rest_hours = hours_to_full
	if hours_to_morning > 0 then
		rest_hours = utils.clamp(hours_to_full, 0, hours_to_morning)
	end
	local rest_multiplier = map_data[player_data.world].fire.active and map_data[player_data.world].fire.x == player_data.x and map_data[player_data.world].fire.y == player_data.y and 2 or 1
	output.add("You rest for " .. rest_hours .. " hour(s)...\n")
	player_data.health = player_data.health + rest_hours * 10 * rest_multiplier
	player_data.mana = player_data.mana + rest_hours * 10 * rest_multiplier
	player_data.fatigue = player_data.fatigue - rest_hours * 10 * rest_multiplier
	player_data.hunger = player_data.hunger + rest_hours * 0.5
	player_data.thirst = player_data.thirst + rest_hours * 2.5
	player_data = player.clamp_player_stats(player_data)
	time.tick_time(rest_hours * 60)
	output.add("Your health, mana, and fatigue have been restored.\n")
	if rest_multiplier > 1 then
		output.add("Resting by the fire makes you recover twice as fast!\n")
	end
	if rest_hours > 0 then
		output.add("You feel hungrier and thirstier.\n")
	end
	local status_message = player.check_player_status(player_data)
	if status_message ~= "" then
		output.add(status_message)
	end
	return player_data
end

function player.equip_item(player_data, items_data, item_name)
	if not player.check_player_alive("equip items", player_data) then
		return player_data
	end
	
	local item_key = items.find_item_key(player_data.inventory, item_name)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return player_data
	end
	
	local item_data = items.get_item_data(items_data, item_key)
	if not item_data then
		output.add("No data found for " .. item_key .. ".\n")
		return player_data
	end
	
	local item_level = nil
	for _, tag in ipairs(item_data.tags) do
		if tag:match("^level=") then
			item_level = tonumber(tag:match("^level=(%S+)"))
			break
		end
	end
	
	if item_level and item_level > player_data.level then
		output.add("You need to be level " .. item_level .. " to equip " .. item_key .. ".\n")
		return player_data
	end
	
	local is_weapon = false
	local is_armor = false
	local weapon_value = nil
	local armor_value = nil
	
	for _, tag in ipairs(item_data.tags) do
		if tag:match("^weapon=") then
			is_weapon = true
			weapon_value = tonumber(tag:match("^weapon=(%S+)"))
		elseif tag:match("^armor=") then
			is_armor = true
			armor_value = tonumber(tag:match("^armor=(%S+)"))
		end
	end
	
	if not is_weapon and not is_armor then
		output.add(item_key .. " cannot be equipped.\n")
		return player_data
	end
	
	if is_weapon then
		if player_data.equipment and player_data.equipment.weapon then
			local current_weapon_data = items.get_item_data(items_data, player_data.equipment.weapon)
			if current_weapon_data then
				for _, tag in ipairs(current_weapon_data.tags) do
					if tag:match("^weapon=") then
						player_data.attack = player_data.attack - tonumber(tag:match("^weapon=(%S+)"))
						break
					end
				end
			end
		end
		player_data.equipment = player_data.equipment or {}
		player_data.equipment.weapon = item_key
		player_data.attack = player_data.attack + weapon_value
		output.add("You equipped " .. item_key .. ".\n")
	elseif is_armor then
		if player_data.equipment and player_data.equipment.armor then
			local current_armor_data = items.get_item_data(items_data, player_data.equipment.armor)
			if current_armor_data then
				for _, tag in ipairs(current_armor_data.tags) do
					if tag:match("^armor=") then
						player_data.defense = player_data.defense - tonumber(tag:match("^armor=(%S+)"))
						break
					end
				end
			end
		end
		player_data.equipment = player_data.equipment or {}
		player_data.equipment.armor = item_key
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
		slot = items.is_item_equipped(player_data, identifier) and (player_data.equipment and player_data.equipment.weapon == identifier and "weapon" or "armor") or nil
	end
	
	if not slot then
		output.add(identifier .. " is not equipped or invalid slot specified.\n")
		return player_data
	end
	
	if not player_data.equipment then
		output.add("No equipment is currently equipped.\n")
		return player_data
	end
	
	local equipped_item = player_data.equipment[slot]
	if not equipped_item then
		output.add("No " .. slot .. " is currently equipped.\n")
		return player_data
	end
	
	local item_data = items.get_item_data(items_data, equipped_item)
	if not item_data then
		output.add("No data found for " .. equipped_item .. ".\n")
		return player_data
	end
	
	if slot == "weapon" then
		for _, tag in ipairs(item_data.tags) do
			if tag:match("^weapon=") then
				player_data.attack = player_data.attack - tonumber(tag:match("^weapon=(%S+)"))
				break
			end
		end
		player_data.equipment.weapon = nil
		output.add("You unequipped " .. equipped_item .. ".\n")
	elseif slot == "armor" then
		for _, tag in ipairs(item_data.tags) do
			if tag:match("^armor=") then
				player_data.defense = player_data.defense - tonumber(tag:match("^armor=(%S+)"))
				break
			end
		end
		player_data.equipment.armor = nil
		output.add("You unequipped " .. equipped_item .. ".\n")
	end
	
	return player_data
end

function player.move_player(direction, player_data, map_data, config, time, output)
	if not player.check_player_alive("move", player_data) then
		return false
	end
	local moves = {
		north = {y = -1, x_min = 1, x_max = config.map.width, y_min = 2, y_max = config.map.height, dir = "north"},
		south = {y = 1, x_min = 1, x_max = config.map.width, y_min = 1, y_max = config.map.height - 1, dir = "south"},
		east = {x = 1, x_min = 1, x_max = config.map.width - 1, y_min = 1, y_max = config.map.height, dir = "east"},
		west = {x = -1, x_min = 2, x_max = config.map.width, y_min = 1, y_max = config.map.height, dir = "west"}
	}
	local move = moves[direction]
	if not move then return false end
	local new_x = player_data.x + (move.x or 0)
	local new_y = player_data.y + (move.y or 0)
	if new_x >= move.x_min and new_x <= move.x_max and new_y >= move.y_min and new_y <= move.y_max then
		local target_symbol = map_data[player_data.world].tiles[new_y][new_x]
		local location_data = map.get_location_description(target_symbol)
		if not location_data.passable then
			output.add("You cannot pass through the wall.\n")
			return false
		end
		if map_data[player_data.world].fire.active and (map_data[player_data.world].fire.x ~= new_x or map_data[player_data.world].fire.y ~= new_y) then
			map_data[player_data.world].fire.active = false
			map_data[player_data.world].fire.x = nil
			map_data[player_data.world].fire.y = nil
			output.add("The fire goes out as you leave the location.\n")
		end
		player_data.x = new_x
		player_data.y = new_y
		for y = utils.clamp(player_data.y - player_data.radius, 1, config.map.height), utils.clamp(player_data.y + player_data.radius, 1, config.map.height) do
			for x = utils.clamp(player_data.x - player_data.radius, 1, config.map.width), utils.clamp(player_data.x + player_data.radius, 1, config.map.width) do
				if math.sqrt((x - player_data.x)^2 + (y - player_data.y)^2) <= player_data.radius then
					map_data[player_data.world].visited[y][x] = true
				end
			end
		end
		output.add("You moved " .. move.dir .. ".\n")
		map.display_location(player_data, map_data)
		local current_biome = map_data[player_data.world].tiles[player_data.y][player_data.x]
		local effects = map.get_biome_effects(current_biome)
		time.tick_time(120)
		player_data.fatigue = utils.clamp(player_data.fatigue + (player_data.mana <= 0 and effects.fatigue * 2 or effects.fatigue), 0, 100)
		player_data.hunger = utils.clamp(player_data.hunger + effects.hunger, 0, 100)
		player_data.thirst = utils.clamp(player_data.thirst + effects.thirst, 0, 100)
		return true
	else
		output.add("You can't move further " .. move.dir .. ".\n")
		return false
	end
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
		player_data.health = utils.clamp(player_data.health, 0, 100)
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
		return 150
	end
	return (value * 150) + ((value - 1) * 150)
end

function player.add_experience(player_data, experience, output)
	player_data.experience = player_data.experience + experience
	output.add("Gained " .. experience .. " experience.\n")
	while player_data.experience >= player.experience_to_next_level(player_data.level) do
		player_data.experience = player_data.experience - player.experience_to_next_level(player_data.level)
		player_data.level = player_data.level + 1
		player_data.levelpoints = player_data.levelpoints + 3
		player_data.health = 100
		player_data.mana = 100
		player_data.fatigue = 0
		output.add("Congratulations! You reached level " .. player_data.level .. "! Gained 3 level points.\n")
	end
	return player_data
end

return player