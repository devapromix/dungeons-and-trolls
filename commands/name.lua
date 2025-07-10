local name = {}

function name.exec(command_parts, player)
	if not player_module.check_player_alive("change name", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Your current name is: " .. player.name .. "\n")
		return player
	end
	local new_name = table.concat(command_parts, " ", 2)
	if new_name:match("^[a-zA-Z]+$") then
		player.name = new_name
		output.add("Your name has been changed to: " .. new_name .. "\n")
	else
		output.add("Name must contain only English letters (a-z, A-Z).\n")
	end
	return player
end

return name