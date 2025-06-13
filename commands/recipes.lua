local recipes = {}

function recipes.exec(player)
	local recipes = utils.load_json_file("assets/data/recipes.json", "Recipes file")
	if not recipes then
		output.add("No recipes found.\n")
		return
	end
	output.add("Recipes:\n")
	for _, recipe in ipairs(recipes) do
		local input_items = type(recipe.input) == "table" and recipe.input or {recipe.input}
		local ingredients = {}
		for _, input in ipairs(input_items) do
			local qty_in_inventory = player.inventory[input] or 0
			table.insert(ingredients, input .. " (1/" .. qty_in_inventory .. ")")
		end
		output.add(recipe.name .. " (" .. table.concat(ingredients, ", ") .. ")\n")
	end
end

return recipes