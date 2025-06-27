local repair = {}

function repair.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("repair equipment", player) then
		return player
	end

	if player.state ~= "forge" then
		output.add("You can only repair equipment in the forge.\n")
		return player
	end

	if not player.equipment_status or (not player.equipment_status.weapon and not player.equipment_status.armor) then
		output.add("You have no equipment to repair.\n")
		return player
	end

	if #command_parts < 2 then
		output.add("Usage: repair <slot | item_name | all>\n")
		output.add("Example: repair weapon, repair Short Sword, repair all\n")
		return player
	end

	local param = table.concat(command_parts, " ", 2):lower()
	local slots_to_repair = {}
	local cost = 0

	if param == "all" then
		if player.equipment_status.weapon == "broken" then
			table.insert(slots_to_repair, "weapon")
		end
		if player.equipment_status.armor == "broken" then
			table.insert(slots_to_repair, "armor")
		end
	else
		local slot = nil
		if param == "weapon" or param == "armor" then
			slot = param
		elseif player.equipment and player.equipment.weapon and player.equipment.weapon:lower() == param then
			slot = "weapon"
		elseif player.equipment and player.equipment.armor and player.equipment.armor:lower() == param then
			slot = "armor"
		end

		if slot and player.equipment_status[slot] == "broken" then
			table.insert(slots_to_repair, slot)
		else
			output.add("No broken equipment found for '" .. param .. "'.\n")
			return player
		end
	end

	if #slots_to_repair == 0 then
		output.add("No broken equipment to repair.\n")
		return player
	end

	cost = 20 * #slots_to_repair
	if player.gold < cost then
		output.add("You need " .. cost .. " gold to repair your equipment.\n")
		return player
	end

	player.gold = player.gold - cost
	for _, slot in ipairs(slots_to_repair) do
		player.equipment_status[slot] = ""
		output.add("Repaired " .. slot .. " (" .. player.equipment[slot] .. ").\n")
	end
	output.add("You paid " .. cost .. " gold for repairs.\n")

	return player
end

return repair