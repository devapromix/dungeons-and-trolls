local command_additem = {}

function command_additem.exec(command_parts, player, items_data, player_module)
	if not config.debug then
		output.add("Command only available in debug mode.\n")
		return player
	end
	if not player_module.check_player_alive("add item", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a quantity and item to add (e.g., 'additem 2 Healing Potion').\n")
		return player
	end
	local quantity, item_name = utils.parse_item_command(command_parts, 2, output)
	if not quantity or not item_name then
		return player
	end
	local item_data = items.get_item_data(items_data, item_name)
	if not item_data then
		output.add("No item found matching '" .. item_name .. "'.\n")
		return player
	end
	local item_key = item_data.name
	local add_qty = math.floor(quantity)
	player.inventory[item_key] = (player.inventory[item_key] or 0) + add_qty
	output.add("Added " .. add_qty .. " " .. item_key .. " to inventory.\n")
	if item_data.file then
		utils.output_text_file(item_data.file)
	end
	if items.is_artifact(item_data) then
		output.add("You acquired the legendary " .. item_key .. "!\n")
	end
	return player
end

return command_additem