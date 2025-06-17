local combat = {}

function combat.attack_enemy(enemy_name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output, player_module)
	if not player_module.check_player_alive("attack", player_data) then
		return
	end
	
	if not enemy_name or enemy_name == "" then
		output.add("Please specify an enemy to attack (e.g., 'attack Goblin').\n")
		return
	end
	
	local enemy_list = map_data[player_data.world].enemies[player_data.y][player_data.x]
	local enemy_key = items.find_item_key(enemy_list, enemy_name)
	
	if not enemy_key then
		output.add("No " .. enemy_name .. " found here.\n")
		return
	end
	
	local enemy_data = enemies.get_enemy_data(enemies_data, enemy_key)
	if not enemy_data then
		output.add("No data found for " .. enemy_key .. ".\n")
		return
	end
	
	output.add("You engage " .. enemy_key .. " in combat!\n")
	return combat.combat_round(enemy_key, enemy_data, map_data, player_data, items_data, skills_data, time, map, output, player_module)
end

function combat.combat_round(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, time, map, output, player_module)
	local enemy_health = enemy_data.health
	local round_count = 0
	
	while player_data.health > 0 and enemy_health > 0 and round_count < 10 do
		round_count = round_count + 1
		
		player_data.fatigue = player_data.fatigue + 1
		player_data = player_module.clamp_player_stats(player_data)
		local status_message = player_module.check_player_status(player_data)
		if status_message ~= "" then
			output.add(status_message)
			return combat.handle_defeat(enemy_name, map_data, player_data, time, output)
		end
		
		local player_hit = combat.player_attack(player_data, enemy_data, skills_data, output, enemy_name)
		if player_hit.hit then
			enemy_health = enemy_health - player_hit.damage
			if enemy_health <= 0 then
				return combat.handle_victory(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, map, output, player_module)
			end
		end
		
		local enemy_hit = combat.enemy_attack(enemy_data, player_data, output, enemy_name)
		if enemy_hit.hit then
			player_data.health = player_data.health - enemy_hit.damage
			if player_data.health <= 0 then
				return combat.handle_defeat(enemy_name, map_data, player_data, time, output)
			end
		end
		
		time.tick_time(10)
	end
	
	if round_count >= 10 and player_data.health > 0 and enemy_health > 0 then
		output.add("You failed to defeat " .. enemy_name .. " and retreated.\n")
		map.display_location(player_data, map_data)
		return false
	end
	
	return false
end

function combat.player_attack(player_data, enemy_data, skills_data, output, enemy_name)
	local result = { hit = false, damage = 0 }
	
	local miss_chance = combat.calculate_miss_chance(player_data.fatigue)
	
	if math.random() >= miss_chance then
		local base_damage = math.max(player_data.attack - enemy_data.defense, 0)
		local final_damage = skills.apply_skill_effects(player_data, skills_data, base_damage)
		
		if final_damage > 0 then
			result.hit = true
			result.damage = final_damage
			output.add("You hit " .. enemy_name .. " for " .. final_damage .. " damage.\n")
		else
			output.add("Your attack is blocked by " .. enemy_name .. ".\n")
		end
	else
		output.add("You missed your attack due to fatigue!\n")
	end
	
	return result
end

function combat.enemy_attack(enemy_data, player_data, output, enemy_name)
	local result = { hit = false, damage = 0 }
	local damage = math.max(enemy_data.attack - player_data.defense, 0)
	
	if damage > 0 then
		result.hit = true
		result.damage = damage
		output.add(enemy_name .. " hits you for " .. damage .. " damage.\n")
	else
		output.add(enemy_name .. "'s attack is blocked.\n")
	end
	
	return result
end

function combat.calculate_miss_chance(fatigue)
	if fatigue > 70 then
		return ((fatigue - 70) / 30) * 0.5
	end
	return 0
end

function combat.handle_victory(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, map, output, player_module)
	output.add("You defeated " .. enemy_name .. "!\n")
	
	player_data = player_module.add_experience(player_data, enemy_data.experience, output)
	
	combat.upgrade_weapon_skill(player_data, items_data, skills_data)
	combat.handle_enemy_drops(enemy_data, map_data, player_data, output)
	combat.remove_enemy_from_map(enemy_name, map_data, player_data)
	
	if enemy_name == "Troll King" then
		game.victory()
	end
	
	map.display_location(player_data, map_data)
	
	return true
end

function combat.upgrade_weapon_skill(player_data, items_data, skills_data)
	if player_data.equipment and player_data.equipment.weapon then
		local item_data = items.get_item_data(items_data, player_data.equipment.weapon)
		if item_data then
			skills.upgrade_skill(player_data, skills_data, item_data)
		end
	end
end

function combat.handle_enemy_drops(enemy_data, map_data, player_data, output)
	if not enemy_data.drops then
		return
	end
	
	for _, drop in ipairs(enemy_data.drops) do
		if math.random() < drop.chance then
			local quantity = drop.quantity and math.random(drop.quantity[1], drop.quantity[2]) or 1
			
			if drop.type == "gold" then
				player_data.gold = player_data.gold + quantity
				output.add("Gained " .. quantity .. " gold.\n")
			elseif drop.type == "item" then
				local current_items = map_data[player_data.world].items[player_data.y][player_data.x]
				current_items[drop.name] = (current_items[drop.name] or 0) + quantity
				output.add(drop.name .. " (" .. quantity .. ") dropped on the ground.\n")
			end
		end
	end
end

function combat.remove_enemy_from_map(enemy_name, map_data, player_data)
	local enemy_location = map_data[player_data.world].enemies[player_data.y][player_data.x]
	enemy_location[enemy_name] = enemy_location[enemy_name] - 1
	
	if enemy_location[enemy_name] <= 0 then
		enemy_location[enemy_name] = nil
	end
end

function combat.handle_defeat(enemy_name, map_data, player_data, time, output)
	player_data.alive = false
	output.add("You were defeated by " .. enemy_name .. ".\n")
	if enemy_name == "Troll King" then
		game.defeat()
	end

	output.add("Game over!\n\n")
	output.add(const.START_NEW_GAME_MSG)
	
	combat.save_game_on_death(map_data, player_data, time)
	
	return false
end

function combat.save_game_on_death(map_data, player_data, time)
	local save_data = {
		map = map_data,
		player = player_data,
		history = input.history,
		time = game_time,
		version = config.game.version,
		fire = map_data[player_data.world].fire
	}
	local save_string = json.encode(save_data)
	love.filesystem.write("game.json", save_string)
end

return combat