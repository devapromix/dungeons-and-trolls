local biome = {}

function biome.add(world, x, y, tile, size)
	local biome_x, biome_y = x, y
	for i = 1, size do
		if not world.tiles[biome_y][biome_x]:match("[><]") then
			world.tiles[biome_y][biome_x] = tile
		end
		local d = math.random(1, 4)
		if d == 1 and biome_x - 1 >= 1 then
			biome_x = biome_x - 1
		elseif d == 2 and biome_x + 1 <= config.map.width then
			biome_x = biome_x + 1
		elseif d == 3 and biome_y - 1 >= 1 then
			biome_y = biome_y - 1
		elseif d == 4 and biome_y + 1 <= config.map.height then
			biome_y = biome_y + 1
		end
	end
	return biome_x, biome_y
end

return biome