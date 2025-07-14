local objects = {}

function objects.load_objects()
	return utils.load_json_file("assets/data/objects.json", "Objects file")
end

function objects.get_tile_objects_string(world, x, y)
	local objects_string = "+++++++++"
	local tile_objects = world.objects[y][x]
	if tile_objects then
		local object_list = {}
		for name, quantity in pairs(tile_objects) do
			if quantity > 0 then
				table.insert(object_list, name)
			end
		end
		if #object_list > 0 then
			objects_string = "You see here: " .. table.concat(object_list, ", ") .. ".\n"
		end
	end
	return objects_string
end

return objects