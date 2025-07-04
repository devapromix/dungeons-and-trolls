local enemies = {}

function enemies.load_enemies()
	return utils.load_json_file("assets/data/enemies.json", "Enemies file")
end

function enemies.get_tile_enemies_string(map_data, x, y)
	local enemy_list = map_data.enemies[y][x]
	if not enemy_list or next(enemy_list) == nil then
		return ""
	end
	local enemies_string = "\nYou see enemies: "
	local enemies = {}
	for name, quantity in pairs(enemy_list) do
		if quantity > 1 then
			table.insert(enemies, name .. " (" .. quantity .. ")")
		else
			table.insert(enemies, name)
		end
	end
	enemies_string = enemies_string .. table.concat(enemies, ", ") .. ".\n"
	return enemies_string
end

function enemies.get_enemy_data(enemies_data, enemy_name)
	if not enemies_data or not enemies_data.enemies or not enemy_name then return nil end
	for _, enemy in ipairs(enemies_data.enemies) do
		if utils.equals(enemy.name, enemy_name) then
			return enemy
		end
	end
	return nil
end

function enemies.get_enemy_at_position(enemies_data, map_data, x, y, enemy_name)
	if not map_data or not map_data.enemies or not map_data.enemies[y] or not map_data.enemies[y][x] then
		return nil
	end
	local enemy_list = map_data.enemies[y][x]
	for enemy, count in pairs(enemy_list) do
		if count > 0 and enemy:lower():find(enemy_name:lower(), 1, true) then
			local enemy_data = enemies.get_enemy_data(enemies_data, enemy)
			if enemy_data then
				local combat_enemy_data = {}
				for k, v in pairs(enemy_data) do
					combat_enemy_data[k] = v
				end
				combat_enemy_data.status = { confused = 0 }
				return combat_enemy_data
			end
		end
	end
	return nil
end

function enemies.apply_damage(enemy, damage)
	enemy.health = math.max(enemy.health - damage, 0)
end

function enemies.remove_enemy(map_data, x, y, enemy_name)
	if map_data and map_data.enemies and map_data.enemies[y] and map_data.enemies[y][x] then
		local enemy_list = map_data.enemies[y][x]
		if enemy_list[enemy_name] then
			enemy_list[enemy_name] = enemy_list[enemy_name] - 1
			if enemy_list[enemy_name] <= 0 then
				enemy_list[enemy_name] = nil
			end
		end
	end
end

return enemies