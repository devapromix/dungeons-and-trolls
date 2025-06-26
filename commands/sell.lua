local sell = {}

function sell.find_shop_item(items_data, shop_type, item_name)
	if not items_data or not items_data.items or not shop_type or not item_name or item_name == "" then return nil, nil end
	local lower_name = string.lower(item_name)
	for _, item in ipairs(items_data.items) do
		if string.lower(item.name) == lower_name then
			for _, tag in ipairs(item.tags) do
				if tag == shop_type or (shop_type == "forge" and tag == "weapon shop") then
					for _, price_tag in ipairs(item.tags) do
						if price_tag:match("^price=") then
							return item.name, tonumber(price_tag:match("^price=(%S+)"))
						end
					end
				end
			end
		end
	end
	return nil, nil
end

function sell.exec(command_parts, player, items_data, player_module)
	if not player_module.check_player_alive("sell", player) then
		return player
	end
	if player.state == "overworld" then
		output.add("You can only sell items in a shop or tavern.\n")
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify what to sell (e.g., 'sell 5 Apple').\n")
		return player
	end
	local shop_type = player.state
	local quantity = 1
	local item_name_start_index = 2
	if tonumber(command_parts[2]) then
		quantity = math.floor(tonumber(command_parts[2]))
		item_name_start_index = 3
		if #command_parts < 3 then
			output.add("Please specify an item name after the quantity (e.g., 'sell 5 Apple').\n")
			return player
		end
	end
	if quantity <= 0 then
		output.add("Invalid item quantity specified.\n")
		return player
	end
	local item_name = table.concat(command_parts, " ", item_name_start_index)
	local item_key = items.find_item_key(player.inventory, item_name)
	if not item_key then
		output.add("You don't have " .. item_name .. " in your inventory.\n")
		return player
	end
	if items.is_item_equipped(player, item_key) then
		output.add("You cannot sell " .. item_key .. " because it is equipped.\n")
		return player
	end
	local available_qty = player.inventory[item_key] or 0
	if quantity > available_qty then
		output.add("You don't have enough " .. item_key .. " to sell that amount.\n")
		return player
	end
	local shop_item_key, price = sell.find_shop_item(items_data, shop_type, item_key)
	if not shop_item_key or not price then
		output.add("You cannot sell " .. item_key .. " in this shop.\n")
		return player
	end
	local sell_price = math.max(1, math.floor(price / 3))
	local total_gold = sell_price * quantity
	player.inventory[item_key] = player.inventory[item_key] - quantity
	if player.inventory[item_key] <= 0 then
		player.inventory[item_key] = nil
	end
	player.gold = player.gold + total_gold
	output.add("You sold " .. quantity .. " " .. item_key .. " for " .. total_gold .. " gold.\n")
	return player
end

return sell