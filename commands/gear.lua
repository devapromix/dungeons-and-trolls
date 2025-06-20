local gear = {}

function gear.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("check gear", player) then
		return player
	end
	local weapon = player.equipment and player.equipment.weapon or "None"
	local armor = player.equipment and player.equipment.armor or "None"
	output.add("Worn equipment:\n")
	output.add("Main weapon: " .. weapon .. "\n")
	output.add("Body armour: " .. armor .. "\n")
	return player
end

return gear