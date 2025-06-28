local gear = {}

function gear.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("check gear", player) then
		return player
	end
	local weapon = player.equipment and player.equipment.weapon or "None"
	local armor = player.equipment and player.equipment.armor or "None"
	local weapon_status = player.equipment_status and player.equipment_status.weapon or ""
	local armor_status = player.equipment_status and player.equipment_status.armor or ""
	output.add("Worn equipment:\n")
	output.add("Main weapon: " .. weapon .. (weapon_status ~= "" and " (" .. weapon_status .. ")" or "") .. "\n")
	output.add("Body armour: " .. armor .. (armor_status ~= "" and " (" .. armor_status .. ")" or "") .. "\n")
	return player
end

return gear