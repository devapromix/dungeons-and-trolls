local combat = {}

function combat.format_combat_message(attacker, target, action, damage)
	if action == "hit" then
		return attacker .. " hit " .. target .. " for " .. damage .. " damage.\n"
	elseif action == "block" then
		return attacker .. "'s attack is blocked by " .. target .. ".\n"
	elseif action == "miss" then
		return attacker .. " missed their attack on " .. target .. "!\n"
	elseif action == "dodge" then
		return target .. " dodged " .. attacker .. "'s attack!\n"
	end
	return ""
end

function combat.attack_enemy(enemy_name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output, player_module)
	if not player_module.check_player_alive("attack", player_data) then
		return false
	end
	
	if player_data.equipment_status then
		if player_data.equipment_status.weapon == "broken" then
			output.add("You cannot fight because your weapon is broken.\n")
			return false
		end
		if player_data.equipment_status.armor == "broken" then
			output.add("You cannot fight because your armor is broken.\n")
			return false
		end
	end
	
	if not enemy_name or enemy_name == "" then
		output.add("Please specify an enemy to attack (e.g., 'attack Goblin').\n")
		return false
	end
	
	if not map_data[player_data.world] or 
	   not map_data[player_data.world].enemies or
	   not map_data[player_data.world].enemies[player_data.y] or
	   not map_data[player_data.world].enemies[player_data.y][player_data.x] then
		output.add("No enemies found at this location.\n")
		return false
	end
	
	local enemy_list = map_data[player_data.world].enemies[player_data.y][player_data.x]
	
	if not enemy_list or next(enemy_list) == nil then
		output.add("No enemies found here.\n")
		return false
	end
	
	local enemy_key = nil
	for enemy, count in pairs(enemy_list) do
		if count > 0 and string.lower(enemy):find(string.lower(enemy_name), 1, true) then
			enemy_key = enemy
			break
		end
	end
	
	if not enemy_key then
		output.add("No " .. enemy_name .. " found here.\n")
		return false
	end
	
	local enemy_data = enemies.get_enemy_data(enemies_data, enemy_key)
	if not enemy_data then
		output.add("Enemy data not found for " .. enemy_key .. ".\n")
		return false
	end
	
	local combat_enemy_data = {}
	for k, v in pairs(enemy_data) do
		combat_enemy_data[k] = v
	end
	
	output.add("You engage " .. enemy_key .. " in combat!\n")
	return combat.combat_round(enemy_key, combat_enemy_data, map_data, player_data, items_data, skills_data, time, map, output, player_module)
end

function combat.combat_round(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, time, map, output, player_module)
	local round_count = 0
	local max_rounds = 10
	
	if not enemy_data or not enemy_data.health or enemy_data.health <= 0 then
		output.add("Enemy data is invalid or enemy is already dead.\n")
		return false
	end
	
	if not player_data or not player_data.health or player_data.health <= 0 then
		output.add("Player data is invalid or player is already dead.\n")
		return false
	end
	
	while player_data.health > 0 and enemy_data.health > 0 and round_count < max_rounds do
		round_count = round_count + 1
		
		player_data.fatigue = math.min((player_data.fatigue or 0) + 1, 100)
		player_data = player_module.clamp_player_stats(player_data)
		
		local status_message = player_module.check_player_status(player_data)
		if status_message and status_message ~= "" then
			output.add(status_message)
			return combat.handle_defeat(enemy_name, map_data, player_data, time, output)
		end
		
		local player_hit = combat.player_attack(player_data, enemy_data, skills_data, output, enemy_name)
		if player_hit and player_hit.hit and player_hit.damage > 0 then
			enemy_data.health = enemy_data.health - player_hit.damage
			if enemy_data.health <= 0 then
				return combat.handle_victory(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, map, output, player_module)
			end
		end
		
		if enemy_data.health > 0 then
			local enemy_hit = combat.enemy_attack(enemy_data, player_data, output, enemy_name)
			if enemy_hit and enemy_hit.hit and enemy_hit.damage > 0 then
				player_data.health = player_data.health - enemy_hit.damage
				if player_data.health <= 0 then
					return combat.handle_defeat(enemy_name, map_data, player_data, time, output)
				end
			end
		end
		
		if time and time.tick_time then
			time.tick_time(10)
		end
	end
	
	if round_count >= max_rounds then
		output.add("The battle goes on too long. You retreat to avoid exhaustion.\n")
	end
	
	if map and map.display_location then
		map.display_location(player_data, map_data)
	end
	
	return false
end

function combat.calculate_damage(attacker_stat, defender_stat)
	local damage = (attacker_stat or 0) - (defender_stat or 0)
	return math.max(damage, 0)
end

function combat.player_attack(player_data, enemy_data, skills_data, output, enemy_name)
	local result = { hit = false, damage = 0 }
	
	local fatigue = player_data.fatigue or 0
	local dexterity = player_data.dexterity or 1
	local strength = player_data.strength or 0
	local attack = player_data.attack or 1
	local enemy_defense = enemy_data.defense or 0
	
	local miss_chance = combat.calculate_miss_chance(fatigue, dexterity)
	
	if math.random() >= miss_chance then
		local base_damage = combat.calculate_damage(attack, enemy_defense)
		local final_damage = base_damage
		
		if skills and skills.apply_skill_effects then
			final_damage = skills.apply_skill_effects(player_data, skills_data, base_damage)
		end
		
		if final_damage > 0 then
			result.hit = true
			local crit_chance = math.min(math.floor(dexterity / 10) * 0.05, 0.5)
			if math.random() < crit_chance then
				final_damage = final_damage + strength
				output.add("Critical hit!\n")
			end
			result.damage = final_damage
			output.add(combat.format_combat_message("You", enemy_name, "hit", final_damage))
		else
			output.add(combat.format_combat_message("You", enemy_name, "block"))
		end
	else
		output.add(combat.format_combat_message("You", enemy_name, "miss"))
	end
	
	return result
end

function combat.enemy_attack(enemy_data, player_data, output, enemy_name)
	local result = { hit = false, damage = 0 }
	
	local player_dexterity = player_data.dexterity or 1
	local enemy_attack = enemy_data.attack or 1
	local player_defense = player_data.defense or 0
	
	local dodge_chance = math.min(math.floor(player_dexterity / 10) * 0.05, 0.5)
	
	if math.random() >= dodge_chance then
		local damage = combat.calculate_damage(enemy_attack, player_defense)
		if damage > 0 then
			result.hit = true
			result.damage = damage
			output.add(combat.format_combat_message(enemy_name, "you", "hit", damage))
		else
			output.add(combat.format_combat_message(enemy_name, "you", "block"))
		end
	else
		output.add(combat.format_combat_message(enemy_name, "you", "dodge"))
	end
	
	return result
end

function combat.calculate_miss_chance(fatigue, dexterity)
	local base_miss_chance = 0
	if fatigue > 70 then
		base_miss_chance = ((fatigue - 70) / 30) * 0.5
	end
	
	local dexterity_modifier = math.floor((dexterity or 1) / 10) * 0.05
	return math.max(base_miss_chance - dexterity_modifier, 0)
end

function combat.apply_broken_equipment_status(player_data, output)
	if math.random() < 0.1 then
		if player_data.equipment and player_data.equipment_status then
			local slots = {}
			if player_data.equipment.weapon then
				table.insert(slots, "weapon")
			end
			if player_data.equipment.armor then
				table.insert(slots, "armor")
			end
			if #slots > 0 then
				local slot = slots[math.random(1, #slots)]
				player_data.equipment_status[slot] = "broken"
				output.add("Your " .. slot .. " (" .. player_data.equipment[slot] .. ") is broken!\n")
			end
		end
	end
end

function combat.handle_victory(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, map, output, player_module)
	output.add("You defeated " .. enemy_name .. "!\n")
	
	if player_module and player_module.add_experience then
		player_data = player_module.add_experience(player_data, enemy_data.experience or 0, output)
	end
	
	combat.upgrade_weapon_skill(player_data, items_data, skills_data)
	
	combat.handle_enemy_drops(enemy_data, map_data, player_data, output)
	
	combat.remove_enemy_from_map(enemy_name, map_data, player_data)
	
	combat.apply_broken_equipment_status(player_data, output)
	
	if enemy_name == "Troll King" and game and game.victory then
		game.victory()
	end
	
	return true
end

function combat.upgrade_weapon_skill(player_data, items_data, skills_data)
	if player_data.equipment and player_data.equipment.weapon and 
	   items and items.get_item_data and skills and skills.upgrade_skill then
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
		if math.random() < (drop.chance or 0) then
			local quantity = 1
			if drop.quantity then
				quantity = math.random(drop.quantity[1] or 1, drop.quantity[2] or 1)
			end
			
			if drop.type == "gold" then
				player_data.gold = (player_data.gold or 0) + quantity
				output.add("Gained " .. quantity .. " gold.\n")
			elseif drop.type == "item" and drop.name then
				if items and items.get_item_data and items.is_artifact then
					local item_data = items.get_item_data(items_data, drop.name)
					if item_data and items.is_artifact(item_data) and 
					   game and game.unique_items and game.unique_items[drop.name] then
						goto continue
					end
				end
				
				if map_data[player_data.world] and 
				   map_data[player_data.world].items and
				   map_data[player_data.world].items[player_data.y] and
				   map_data[player_data.world].items[player_data.y][player_data.x] then
					local current_items = map_data[player_data.world].items[player_data.y][player_data.x]
					current_items[drop.name] = (current_items[drop.name] or 0) + quantity
					output.add(drop.name .. " (" .. quantity .. ") dropped on the ground.\n")
					
					if items and items.get_item_data and items.is_artifact then
						local item_data = items.get_item_data(items_data, drop.name)
						if item_data and items.is_artifact(item_data) then
							if game and game.unique_items then
								game.unique_items[drop.name] = true
							end
							output.add("The legendary " .. drop.name .. " has appeared!\n")
						end
					end
				end
			end
			::continue::
		end
	end
end

function combat.remove_enemy_from_map(enemy_name, map_data, player_data)
	if map_data[player_data.world] and 
	   map_data[player_data.world].enemies and
	   map_data[player_data.world].enemies[player_data.y] and
	   map_data[player_data.world].enemies[player_data.y][player_data.x] then
		local enemy_location = map_data[player_data.world].enemies[player_data.y][player_data.x]
		
		if enemy_location[enemy_name] then
			enemy_location[enemy_name] = enemy_location[enemy_name] - 1
			
			if enemy_location[enemy_name] <= 0 then
				enemy_location[enemy_name] = nil
			end
		end
	end
end

function combat.handle_defeat(enemy_name, map_data, player_data, time, output)
	player_data.alive = false
	output.add("You were defeated by " .. enemy_name .. ".\n")
	
	if enemy_name == "Troll King" and game and game.defeat then
		game.defeat()
	end

	output.add("Game over!\n\n")
	
	if const and const.START_NEW_GAME_MSG then
		output.add(const.START_NEW_GAME_MSG)
	end
	
	combat.save_game_on_death(map_data, player_data, time)
	
	return false
end

function combat.save_game_on_death(map_data, player_data, time)
	if not json or not json.encode or not love or not love.filesystem then
		return
	end
	
	local save_data = {
		map = map_data,
		player = player_data,
		history = input and input.history or {},
		time = game_time or time,
		version = config and config.game and config.game.version or "1.0",
		fire = map_data[player_data.world] and map_data[player_data.world].fire or {}
	}
	
	local success, save_string = pcall(json.encode, save_data)
	if success then
		love.filesystem.write("game.json", save_string)
	end
end

return combat