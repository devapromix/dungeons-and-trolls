local sell = {}

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
	local quantity, item_name = utils.parse_item_command(command_parts, 2, output)
	if not quantity or not item_name then
		return player
	end
	local item_key = utils.find_item_key(player.inventory, item_name, true)
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
	local shop_item_key, price
	for _, item in ipairs(items_data.items) do
		if utils.find_item_key({[item.name] = true}, item_key, false) then
			for _, tag in ipairs(item.tags) do
				if tag == shop_type or (shop_type == "forge" and tag == "weapon shop") then
					for _, price_tag in ipairs(item.tags) do
						if price_tag:match("^price=") then
							shop_item_key = item.name
							price = tonumber(price_tag:match("^price=(%S+)"))
							break
						end
					end
				end
			end
		end
	end
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