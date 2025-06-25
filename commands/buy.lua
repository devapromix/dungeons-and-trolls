local buy = {}

function buy.exec(command_parts, player, game_time, time, player_module)
	if not player_module.check_player_alive("buy", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You can only buy items or a room in a shop or tavern.\n")
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify what to buy (e.g., 'buy room' or 'buy Healing Potion').\n")
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
		local item_name = table.concat(command_parts, " ", 2)
		local item_key
		local price
		for _, item in ipairs(game.shop_items_cache[shop_type]) do
			if string.lower(item.name) == string.lower(item_name) then
				item_key = item.name
				price = item.price
				break
			end
		end
		if not item_key then
			output.add("Item '" .. item_name .. "' is not available in this shop.\n")
			return player
		end
		if player.gold < price then
			output.add("You need " .. price .. " gold to buy " .. item_key .. ".\n")
			return player
		end
		player.gold = player.gold - price
		player.inventory = player.inventory or {}
		player.inventory[item_key] = (player.inventory[item_key] or 0) + 1
		output.add("You bought " .. item_key .. " for " .. price .. " gold.\n")
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