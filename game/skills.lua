local skills = {}

function skills.load_skills()
	return utils.load_json_file("assets/data/skills.json", "Skills file")
end

function skills.get_skill_data(skills_data, skill_name)
	if not skills_data or not skills_data.skills or not skill_name then return nil end
	for _, skill in ipairs(skills_data.skills) do
		if utils.equals(skill.name, skill_name) then
			return skill
		end
	end
	return nil
end

function skills.apply_skill_effects(player, skills_data, damage)
	local critical_multiplier = 1
	if player.equipment and player.equipment.weapon then
		local item_data = items.get_item_data(items.load_items(), player.equipment.weapon)
		if item_data and item_data.skill then
			local swords_skill = player.skills and player.skills[item_data.skill] or 0
			local skill_data = skills.get_skill_data(skills_data, item_data.skill)
			if skill_data and math.random() < (swords_skill / 100) then
				output.add("Critical hit!\n")
				return damage + player.strength
			end
		end
	end
	return damage
end

function skills.upgrade_skill(player, skills_data, item_data)
	if not item_data or not item_data.skill then
		output.add("No skill associated with equipped item.\n")
		return
	end
	local skill_name = item_data.skill
	local skill_data = skills.get_skill_data(skills_data, skill_name)
	if not skill_data then
		output.add("No skill data found for " .. skill_name .. ".\n")
		return
	end
	if not player.skills then
		player.skills = {}
	end
	if not player.skills[skill_name] then
		player.skills[skill_name] = 0
	end
	if player.skills[skill_name] < 40 then 
		player.skills[skill_name] = player.skills[skill_name] + 1
		output.add(skill_name .. " skill increased to " .. player.skills[skill_name] .. ".\n")
	else
		output.add(skill_name .. " is already at maximum level (40).\n")
	end
end

function skills.draw()
	for _, skill in ipairs(skills_data.skills) do
		local level = player.skills and player.skills[skill.name] or 0
		output.add(skill.name .. ": " .. level .. "\n")
	end
end

return skills