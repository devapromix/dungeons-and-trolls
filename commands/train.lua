local train = {}

local attributes = {"Strength", "Dexterity", "Vitality", "Intelligence"}

function train.find_attribute_key(attribute_name)
	if not attribute_name or attribute_name == "" then return nil end
	local lower_name = string.lower(attribute_name)
	for _, attr in ipairs(attributes) do
		local lower_attr = string.lower(attr)
		if lower_attr == lower_name or (#lower_name >= 3 and string.find(lower_attr, lower_name, 1, true) == 1) then
			return attr
		end
	end
	return nil
end

function train.find_skill_key(skill_name, skills_data)
	if not skill_name or skill_name == "" then return nil end
	local lower_name = string.lower(skill_name)
	for _, skill in ipairs(skills_data.skills) do
		local lower_skill = string.lower(skill.name)
		if lower_skill == lower_name or (#lower_name >= 3 and string.find(lower_skill, lower_name, 1, true) == 1) then
			return skill.name
		end
	end
	return nil
end

function train.train_skill(player, skill_key, shop_type)
	local skills_data = skills.load_skills()
	local skill_name = train.find_skill_key(skill_key, skills_data)
	if not skill_name then
		output.add("No skill found for '" .. skill_key .. "'.\n")
		return player
	end
	local interiors = shop.load_interiors().interiors
	local shop_interior = nil
	for _, int in ipairs(interiors) do
		if int.id == shop_type then
			shop_interior = int
			break
		end
	end
	if not shop_interior or not shop_interior.trainable_skills then
		output.add("No skills can be trained in this building.\n")
		return player
	end
	local trainable_skill = nil
	local skill_price = nil
	for _, skill in ipairs(shop_interior.trainable_skills) do
		if utils.equals(skill.name, skill_name) then
			trainable_skill = skill.name
			skill_price = skill.price
			break
		end
	end
	if not trainable_skill then
		output.add("Skill '" .. skill_name .. "' cannot be trained in this building.\n")
		return player
	end
	if player.gold < skill_price then
		output.add("You need " .. skill_price .. " gold to train " .. trainable_skill .. ".\n")
		return player
	end
	if player.skills[trainable_skill] and player.skills[trainable_skill].level >= config.skill.max then
		output.add(trainable_skill .. " is already at maximum level (" .. config.skill.max .. ").\n")
		return player
	end

	if not player.skills then
		player.skills = {}
	end
	if not player.skills[trainable_skill] then
		player.skills[trainable_skill] = { level = 0, progress = 0 }
	end

	player.gold = player.gold - skill_price
	player.skills[trainable_skill].level = player.skills[trainable_skill].level + 1
	output.add("You paid " .. skill_price .. " gold to train " .. trainable_skill .. " to level " .. player.skills[trainable_skill].level .. ".\n")
	return player
end

function train.exec(command_parts, player)
	if not player_module.check_player_alive("train", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify an attribute or skill to train (e.g., 'train strength' or 'train Swords').\n")
		output.add("\nAttributes:\n")
		for _, attr in ipairs(attributes) do
			output.add(" * " .. attr .. "\n")
		end
		output.add("\nSkills:\n")
		local skills_data = skills.load_skills()
		for _, skill in ipairs(skills_data.skills) do
			output.add(" * " .. skill.name .. "\n")
		end
		return player
	end
	local name = commands.get_item_name_from_parts(command_parts, 2)
	local attr_key = train.find_attribute_key(name)
	if attr_key then
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
		if attr_key == "vitality" then player = player_module.update_max_health(player) end
		if attr_key == "intelligence" then player = player_module.update_max_mana(player) end
		output.add("You trained " .. attr_key .. "!\n")
		output.add("Current value: " .. player[attr_key] .. ".\n")
		output.add("Level points remaining: " .. player.levelpoints .. ".\n")
		return player
	end
	if player.state == "overworld" then
		output.add("You can only train skills inside a building.\n")
		return player
	end
	return train.train_skill(player, name, player.state)
end

return train