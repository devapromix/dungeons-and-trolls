local cook = {}

function cook.exec(command_parts, player, map_data, items_data, output, items, time)
	if not player_module.check_player_alive("cook an item", player) then
		return player
	end
	if not fire.check_fire(player.world, player.x, player.y) then
		output.add("You need an active fire to cook.\n")
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify a recipe to cook (e.g., 'cook Meat').\n")
		return player
	end
	local recipe_name = commands.get_item_name_from_parts(command_parts, 2)
	if not commands.validate_parameter(recipe_name, "recipe", output) then
		return player
	end
	local recipes = utils.load_json_file("assets/data/recipes.json", "Recipes file")
	if not recipes then
		output.add("No recipes found.\n")
		return player
	end
	for _, recipe in ipairs(recipes) do
		if string.lower(recipe.name) == string.lower(recipe_name) and recipe.requires_fire then
			local input_items = type(recipe.input) == "table" and recipe.input or {recipe.input}
			local has_all_items = true
			for _, input in ipairs(input_items) do
				local found = false
				for inv_item, _ in pairs(player.inventory) do
					if string.lower(inv_item) == string.lower(input) then
						found = true
						break
					end
				end
				if not found or not player.inventory[input] or player.inventory[input] < 1 then
					has_all_items = false
					break
				end
			end
			if has_all_items then
				for _, input in ipairs(input_items) do
					player.inventory[input] = player.inventory[input] - 1
					if player.inventory[input] == 0 then
						player.inventory[input] = nil
					end
				end
				player.inventory[recipe.output] = (player.inventory[recipe.output] or 0) + recipe.quantity
				time.tick_time(recipe.cooking_time)
				output.add("You cooked " .. recipe.output .. ".\n")
				return player
			else
				output.add("You don't have all required items for this recipe.\n")
				return player
			end
		end
	end
	output.add("No recipe found for " .. recipe_name .. ".\n")
	return player
end

return cook