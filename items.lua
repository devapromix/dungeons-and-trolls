local items = {}

function items.load_items()
	return utils.load_json_file("assets/data/items.json", "Items file")
end

function items.get_tile_items_string(map, x, y)
	local tile_items = map and map.items and map.items[y] and map.items[y][x] or {}
	local item_list = {}
	for item, qty in pairs(tile_items) do
		if qty == 1 then
			table.insert(item_list, item)
		else
			table.insert(item_list, item .. " (" .. qty .. ")")
		end
	end
	local str = table.concat(item_list, ", ")
	if str ~= "" then
		return "\nYou see items: " .. str .. ".\n"
	end
	return ""
end

function items.get_item_data(items_data, item_key)
	if not items_data or not items_data.items or not item_key then return nil end
	for _, item in ipairs(items_data.items) do
		if item.name == item_key then
			return item
		end
	end
	return nil
end

function items.is_item_equipped(player, item_name)
	if not player.equipment then return false end
	return (player.equipment.weapon == item_name or player.equipment.armor == item_name)
end

function items.pick_item(player, map, item_name, quantity)
	if not player_module.check_player_alive("pick up items", player) then
		return
	end
	if not map or not map.items or not map.items[player.y] or not map.items[player.y][player.x] then
		output.add("No items found here.\n")
		return
	end
	if not item_name or item_name == "" then
		output.add("Please specify a valid item name.\n")
		return
	end
	if not quantity or type(quantity) ~= "number" or quantity <= 0 then
		output.add("Invalid item quantity specified.\n")
		return
	end
	local tile_items = map.items[player.y][player.x]
	if not next(tile_items) then
		output.add("No items found here.\n")
		return
	end
	local item_key = utils.find_item_key(tile_items, item_name, true)
	if not item_key then
		output.add("No " .. item_name .. " found here.\n")
		return
	end
	local available_qty = tile_items[item_key]
	if not available_qty or type(available_qty) ~= "number" or available_qty <= 0 then
		output.add("Error: Invalid quantity for " .. item_key .. ".\n")
		return
	end
	if quantity > available_qty then
		output.add("There aren't enough " .. item_key .. " to pick up that amount.\n")
		return
	end
	if utils.table_count(player.inventory) >= config.inventory.max_slots and not player.inventory[item_key] then
		output.add("Cannot pick up " .. quantity .. " " .. item_key .. ": inventory is full (max " .. config.inventory.max_slots .. " slots).\n")
		return
	end
	local pickup_qty = math.floor(quantity)
	player.inventory[item_key] = (player.inventory[item_key] or 0) + pickup_qty
	tile_items[item_key] = tile_items[item_key] - pickup_qty
	if tile_items[item_key] <= 0 then
		tile_items[item_key] = nil
	end
	output.add("You picked up " .. pickup_qty .. " " .. item_key .. ".\n")
	local item_data = items.get_item_data(items_data, item_key)
	if item_data then
		if item_data.file then
			utils.output_text_file(item_data.file)
		end
		if items.is_artifact(item_data) then
			output.add("You acquired the legendary " .. item_key .. "!\n")
		end
	end
end

function items.drop_item(player, map, item_name, quantity)
	if not player_module.check_player_alive("drop items", player) then
		return
	end
	if not item_name or item_name == "" then
		output.add("Please specify a valid item name.\n")
		return
	end
	local item_key = utils.find_item_key(player.inventory, item_name, true)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return
	end
	if items.is_item_equipped(player, item_key) then
		output.add("You cannot drop " .. item_key .. " because it is equipped.\n")
		return
	end
	if not quantity or type(quantity) ~= "number" or quantity <= 0 then
		output.add("Invalid item quantity specified.\n")
		return
	end
	local available_qty = player.inventory[item_key]
	if quantity > available_qty then
		output.add("You don't have enough " .. item_key .. " to drop that amount.\n")
		return
	end
	if not map or not map.items or not map.items[player.y] or not map.items[player.y][player.x] then
		output.add("Error: Cannot drop items due to invalid map data.\n")
		return
	end
	map.items[player.y][player.x][item_key] = (map.items[player.y][player.x][item_key] or 0) + quantity
	player.inventory[item_key] = player.inventory[item_key] - quantity
	if player.inventory[item_key] <= 0 then
		player.inventory[item_key] = nil
	end
	output.add("You dropped " .. quantity .. " " .. item_key .. ".\n")
	output.add(items.get_tile_items_string(map, player.x, player.y))
end

function items.eat_item(player, items_data, item_name)
	if not player_module.check_player_alive("eat", player) then
		return
	end
	local item_key = utils.find_item_key(player.inventory, item_name, true)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return
	end
	if items.is_item_equipped(player, item_key) then
		output.add("You cannot eat " .. item_key .. " because it is equipped.\n")
		return
	end
	local item_data = items.get_item_data(items_data, item_key)
	if not item_data then
		output.add("No data found for " .. item_key .. ".\n")
		return
	end
	local edible_value = nil
	for _, tag in ipairs(item_data.tags) do
		if tag:match("^edible=") then
			edible_value = tonumber(tag:match("^edible=(%S+)"))
			break
		end
	end
	if not edible_value then
		output.add(item_key .. " is not edible.\n")
		return
	end
	output.add("You eat one " .. item_key .. "...\n")
	player.hunger = utils.clamp(player.hunger - edible_value, 0, 100)
	player.inventory[item_key] = player.inventory[item_key] - 1
	if player.inventory[item_key] <= 0 then
		player.inventory[item_key] = nil
	end
	time.tick_time(15)
	output.add("You feel less hungry.\n")
	return player
end

function items.drink_item(player, items_data, item_name)
	if not player_module.check_player_alive("drink", player) then
		return
	end
	local item_key = utils.find_item_key(player.inventory, item_name, true)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return
	end
	if items.is_item_equipped(player, item_key) then
		output.add("You cannot drink " .. item_key .. " because it is equipped.\n")
		return
	end
	local item_data = items.get_item_data(items_data, item_key)
	if not item_data then
		output.add("No data found for " .. item_key .. ".\n")
		return
	end
	local drinkable_value = nil
	local healing_value = nil
	local mana_restore_value = nil
	for _, tag in ipairs(item_data.tags) do
		if tag:match("^drinkable=") then
			drinkable_value = tonumber(tag:match("^drinkable=(%S+)"))
		elseif tag:match("^healing=") then
			healing_value = tonumber(tag:match("^healing=(%S+)"))
		elseif tag:match("^MANA_RESTORE=") then
			mana_restore_value = tonumber(tag:match("^MANA_RESTORE=(%S+)"))
		end
	end
	if not drinkable_value then
		output.add(item_key .. " is not drinkable.\n")
		return
	end
	output.add("You drink one " .. item_key .. ".\n")
	player.thirst = utils.clamp(player.thirst - drinkable_value, 0, 100)
	if healing_value then
		player.health = utils.clamp(player.health + healing_value, 0, player.max_health)
		output.add("Your health is restored.\n")
	end
	if mana_restore_value then
		player.mana = utils.clamp(player.mana + mana_restore_value, 0, player.max_mana)
		output.add("Your mana is restored.\n")
	end
	player.inventory[item_key] = player.inventory[item_key] - 1
	if player.inventory[item_key] <= 0 then
		player.inventory[item_key] = nil
	end
	time.tick_time(15)
	output.add("You feel less thirsty.\n")
	return player
end

function items.is_artifact(item_data)
	for _, tag in ipairs(item_data.tags) do
		if tag == "artifact" then
			return true
		end
	end
	return false
end

function items.has_tag(items_data, item_name, tag)
	local item_data = items.get_item_data(items_data, item_name)
	if not item_data then
		return false
	end
	for _, item_tag in ipairs(item_data.tags) do
		if item_tag == tag then
			return true
		end
	end
	return false
end

return items