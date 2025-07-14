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
		if string.len(new_name) < 3 then
			output.add("Name must be at least 3 characters long.\n")
			return player
		end
		if player.name ~= "Player" then
			output.add("You can only set your hero's name once.\n")
			return player
		end
		new_name = new_name:sub(1, 1):upper() .. new_name:sub(2)
		player.name = new_name
		output.add("Your name has been changed to: " .. new_name .. "\n")
	else
		output.add("Name must contain only letters a-z and A-Z.\n")
	end
	return player
end

return name