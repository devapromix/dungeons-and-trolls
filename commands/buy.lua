local buy = {}

function buy.find_shop_item(shop_items, item_name)
	if not shop_items or not item_name or item_name == "" then return nil, nil end
	local lower_name = string.lower(item_name)
	for _, item in ipairs(shop_items) do
		if string.lower(item.name) == lower_name then
			return item.name, item.price
		end
	end
	return nil, nil
end

function buy.exec(command_parts, player, game_time, time, player_module)
	if not player_module.check_player_alive("buy", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You can only buy items or a room in a shop or tavern.\n")
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify what to buy (e.g., 'buy room' or 'buy 5 Healing Potion').\n")
		return player
	end
	local shop_type = player.state
	if command_parts[2]:lower() == "room" then
		if shop_type ~= "tavern" then
			output.add("You can only buy a room in the tavern.\n")
			return player
		end
		if game_time.hour < 18 then
			output.add("Rooms are only available for purchase after 6 PM.\n")
			return player
		end
		if game_time.hour >= 24 then
			output.add("Rooms are not available for purchase after midnight.\n")
			return player
		end
		if player.gold < 10 then
			output.add("You need 10 gold to buy a room for the night.\n")
			return player
		end
		player.gold = player.gold - 10
		player = buy.rest_in_tavern(player, game_time, time)
		output.add("You paid 10 gold and rested in the tavern until morning.\n")
	else
		if not game.shop_items_cache[shop_type] then
			output.add("No items available for purchase in this shop.\n")
			return player
		end
		local quantity = 1
		local item_name_start_index = 2
		if tonumber(command_parts[2]) then
			quantity = math.floor(tonumber(command_parts[2]))
			item_name_start_index = 3
			if #command_parts < 3 then
				output.add("Please specify an item name after the quantity (e.g., 'buy 5 Healing Potion').\n")
				return player
			end
		end
		if quantity <= 0 then
			output.add("Invalid item quantity specified.\n")
			return player
		end
		local item_name = table.concat(command_parts, " ", item_name_start_index)
		local item_key, price = buy.find_shop_item(game.shop_items_cache[shop_type], item_name)
		if not item_key then
			output.add("Item '" .. item_name .. "' is not available in this shop.\n")
			return player
		end
		local total_cost = price * quantity
		if player.gold < total_cost then
			output.add("You need " .. total_cost .. " gold to buy " .. quantity .. " " .. item_key .. ".\n")
			return player
		end
		if utils.table_count(player.inventory) >= config.inventory.max_slots and not player.inventory[item_key] then
			output.add("Cannot buy " .. quantity .. " " .. item_key .. ": inventory is full (max " .. config.inventory.max_slots .. " slots).\n")
			return player
		end
		player.gold = player.gold - total_cost
		player.inventory = player.inventory or {}
		player.inventory[item_key] = (player.inventory[item_key] or 0) + quantity
		output.add("You bought " .. quantity .. " " .. item_key .. " for " .. total_cost .. " gold.\n")
	end
	return player
end

function buy.rest_in_tavern(player_data, game_time, time)
	player_data.health = player_data.max_health
	player_data.mana = player_data.max_mana
	player_data.fatigue = 0
	game_time.hour = 6
	game_time.minute = 0
	game_time.day = game_time.day + 1
	if game_time.day > 30 then
		game_time.day = 1
		game_time.month = game_time.month + 1
		if game_time.month > 12 then
			game_time.month = 1
			game_time.year = game_time.year + 1
		end
	end
	time.tick_time(0)
	return player_data
end

return buy