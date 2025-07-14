local command_gender = {}

function command_gender.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("change gender", player) then
		return player
	end

	if #command_parts < 2 then
		output.add("Please specify a gender (e.g., 'gender male' or 'gender female').\n")
		return player
	end

	local requested_gender = command_parts[2]:lower()

	if requested_gender ~= "male" and requested_gender ~= "female" then
		output.add("Invalid gender. Please specify 'male' or 'female'.\n")
		return player
	end

	if player.gender == requested_gender then
		output.add("Your gender is already " .. requested_gender .. ".\n")
		return player
	end

	if player.gender == "female" then
		output.add("You cannot change your gender.\n")
		return player
	end
	if player.gender == "male" and requested_gender == "female" then
		player.gender = requested_gender
		output.add("Gender changed to " .. requested_gender .. ".\n")
	else
		output.add("Cannot change gender to " .. requested_gender .. ".\n")
	end

	return player
end

return command_gender