local train = {}

function train.find_attribute_key(attribute_name)
	if not attribute_name or attribute_name == "" then return nil end
	local lower_name = string.lower(attribute_name)
	local attributes = {"strength", "dexterity", "vitality", "intelligence"}
	for _, attr in ipairs(attributes) do
		local lower_attr = string.lower(attr)
		if lower_attr == lower_name or (#lower_name >= 3 and string.find(lower_attr, lower_name, 1, true) == 1) then
			return attr
		end
	end
	return nil
end

function train.exec(command_parts, player)
	if not player_module.check_player_alive("train an attribute", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify an attribute to train (e.g., 'train strength').\n")
		return player
	end
	local attribute_name = commands.get_item_name_from_parts(command_parts, 2)
	if not commands.validate_parameter(attribute_name, "attribute", output) then
		return player
	end
	local attr_key = train.find_attribute_key(attribute_name)
	if not attr_key then
		output.add("No attribute found for '" .. attribute_name .. "'.\n")
		return player
	end
	if player.levelpoints <= 0 then
		output.add("You don't have enough level points to train.\n")
		return player
	end

	if player[attr_key] >= config.skill.max then
		output.add("You have already mastered " .. attr_key .. ".\n")
		return player
	end

	player[attr_key] = player[attr_key] + 1
	player.levelpoints = player.levelpoints - 1
	output.add("You trained " .. attr_key .. "!\n")
	output.add("Current value: " .. player[attr_key] .. ".\n")
	output.add("Level points remaining: " .. player.levelpoints .. ".\n")
	return player
end

return train
