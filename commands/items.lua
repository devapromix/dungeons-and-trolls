local module = {}

function module.exec(player, player_module, items)
	if not player_module.check_player_alive("check your inventory", player) then
		return
	end
	output.add("Inventory (" .. commands.table_count(player.inventory) .. "/" .. config.inventory.max_slots .. "):\n")
	if next(player.inventory) == nil then
		output.add("(empty)\n")
	else
		for item, quantity in pairs(player.inventory) do
			local equipped = items.is_item_equipped(player, item) and " (equipped)" or ""
			if quantity > 1 then
				output.add(item .. " (" .. quantity .. ")" .. equipped .. "\n")
			else
				output.add(item .. equipped .. "\n")
			end
		end
	end
	output.add("Gold: " .. player.gold .. "\n")
end

return module