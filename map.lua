local map = {}

local default_location = { name = "Unknown", description = "An unknown location.", passable = true }
local default_effects = { thirst = 2, hunger = 0.5, fatigue = 1 }

function map.load_locations()
	return utils.load_json_file("assets/data/locations.json", "Locations file")
end

local function get_location_by_symbol(symbol)
	for _, location in ipairs(locations_data.locations or {}) do
		if location.symbol == symbol then
			return location
		end
	end
	return nil
end

function map.get_location_description(symbol)
	local location = get_location_by_symbol(symbol)
	if location then
		return { name = location.name, description = location.description, passable = location.passable }
	end
	return default_location
end

function map.get_biome_effects(symbol)
	local location = get_location_by_symbol(symbol)
	return location and location.effects or default_effects
end

function map.cellular_automaton(tiles, width, height, iterations)
	local new_tiles = {}
	for y = 1, height do
		new_tiles[y] = {}
		for x = 1, width do
			new_tiles[y][x] = tiles[y][x]
		end
	end
	for _ = 1, iterations do
		for y = 1, height do
			for x = 1, width do
				local neighbors = 0
				for dy = -1, 1 do
					for dx = -1, 1 do
						if dx == 0 and dy == 0 then
							goto continue
						end
						local nx, ny = x + dx, y + dy
						if nx >= 1 and nx <= width and ny >= 1 and ny <= height and tiles[ny][nx] ~= "o" then
							neighbors = neighbors + 1
						end
						::continue::
					end
				end
				if neighbors < 4 then
					new_tiles[y][x] = "o"
				elseif neighbors >= 5 then
					new_tiles[y][x] = tiles[y][x]
				end
			end
		end
		for y = 1, height do
			for x = 1, width do
				tiles[y][x] = new_tiles[y][x]
			end
		end
	end
	return tiles
end

function map.biome(world, x, y, tile, size)
	local biome_x, biome_y = x, y
	for i = 1, size do
		if not world.tiles[y][x]:match("[><]") then
			world.tiles[biome_y][biome_x] = tile
		end
		d = math.random(1, 4)
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

function map.fill(world, symbol)
	for y = 1, config.map.height do
		for x = 1, config.map.width do
			world.tiles[y][x] = symbol
		end
	end
end

function map.get_random_location_symbol(is_passable, is_underworld)
	local location = nil
	repeat
		location = locations_data.locations[math.random(1, #locations_data.locations)]
	until location.passable == is_passable and location.underworld == is_underworld and location.special == false
	return location.symbol
end

function map.gen_world(world, is_underworld, biome_amount, biome_size)
	for i = 1, biome_amount do
		x = math.random(1, config.map.width - 1)
		y = math.random(1, config.map.height - 1)
		map.biome(world, x, y, map.get_random_location_symbol(true, is_underworld), biome_size)
	end
end

local function is_valid_position(x, y)
	return x >= 1 and x <= config.map.width and y >= 1 and y <= config.map.height
end

function map.add_passage(map_data, x, y)
	map_data.overworld.tiles[y][x] = ">"
	map_data.underworld.tiles[y][x] = "<"
end

function map.add_passages(map_data)
	local center_x, center_y = math.floor(config.map.width / 2), math.floor(config.map.height / 2)
	for i = 1, 5 do
		local x, y
		repeat
			x = center_x + math.random(-15, 15)
			y = center_y + math.random(-10, 10)
		until is_valid_position(x, y) and not map_data.overworld.tiles[y][x]:match("[><]")
		map.biome(map_data.underworld, x, y, map.get_random_location_symbol(true, true), 75)
		map.add_passage(map_data, x, y)
	end
end

function map.add_troll_cave()
	local troll_x, troll_y
	local center_x, center_y = math.floor(config.map.width / 2), math.floor(config.map.height / 2)
	repeat
		troll_x = center_x + math.random(-15, 15)
		troll_y = center_y + math.random(-15, 15)
		local distance = math.sqrt((troll_x - center_x)^2 + (troll_y - center_y)^2)
	until distance >= 12 and distance <= 15 and is_valid_position(troll_x, troll_y) and not map_data.underworld.tiles[troll_y][troll_x]:match("[><]")
	map.biome(map_data.underworld, troll_x, troll_y, map.get_random_location_symbol(true, true), 50)
	map.add_passage(map_data, troll_x, troll_y + 1)
	map_data.underworld.tiles[troll_y][troll_x] = "t"
	map_data.underworld.enemies[troll_y][troll_x]["Troll King"] = 1
	return troll_x, troll_y
end

function map.initialize_game(locations_data)
	map_data = {
		overworld = {
			tiles = {},
			visited = {},
			items = {},
			enemies = {},
			fire = { x = nil, y = nil, active = false }
		},
		underworld = {
			tiles = {},
			visited = {},
			items = {},
			enemies = {},
			fire = { x = nil, y = nil, active = false },
			troll_cave = { x = nil, y = nil }
		}
	}
	
	player = {
		x = math.floor(config.map.width / 2),
		y = math.floor(config.map.height / 2),
		world = "overworld",
		symbol = "@",
		health = 100,
		mana = 100,
		hunger = 0,
		fatigue = 0,
		thirst = 0,
		attack = 5,
		defense = 3,
		alive = true,
		gold = 0,
		inventory = { ["Short Sword"] = 1, ["Leather Armor"] = 1 },
		equipment = { weapon = "Short Sword", armor = "Leather Armor" },
		skills = {},
		radius = 3,
		level = 1,
		experience = 0
	}
	
	game_time = {
		year = 1280,
		month = 4,
		day = 1,
		hour = 6,
		minute = 0
	}
	
	local function initialize_world(world, is_underworld)
		for y = 1, config.map.height do
			world.tiles[y] = {}
			world.visited[y] = {}
			world.items[y] = {}
			world.enemies[y] = {}
			for x = 1, config.map.width do
				local symbol = map.get_random_location_symbol(true, is_underworld)
				world.tiles[y][x] = symbol
				world.visited[y][x] = false
				world.items[y][x] = {}
				world.enemies[y][x] = {}
				local location_data
				for _, loc in ipairs(locations_data.locations) do
					if loc.symbol == symbol then
						location_data = loc
						break
					end
				end
				if location_data and location_data.items then
					for _, item in ipairs(location_data.items) do
						if math.random() < item.chance then
							local quantity = math.random(item.quantity[1], item.quantity[2])
							world.items[y][x][item.name] = quantity
						end
					end
				end
				if location_data and location_data.enemies then
					for _, enemy in ipairs(location_data.enemies) do
						if math.random() < enemy.chance then
							local quantity = math.random(enemy.quantity[1], enemy.quantity[2])
							world.enemies[y][x][enemy.name] = quantity
						end
					end
				end
			end
		end
	end
	
	initialize_world(map_data.overworld, false)
	initialize_world(map_data.underworld, true)
	map.fill(map_data.overworld, map.get_random_location_symbol(true, false))
	map.gen_world(map_data.overworld, false, 45, 200)
	map.fill(map_data.underworld, map.get_random_location_symbol(false, true))
	if not config.debug then
		map.gen_world(map_data.underworld, true, 20, 150)
	end
	map.add_passages(map_data)
	local troll_x, troll_y = map.add_troll_cave()
	map_data.underworld.troll_cave.x = troll_x
	map_data.underworld.troll_cave.y = troll_y
	map.update_visibility(player, map_data)
end

function map.move_up(player, map_data)
	if config.debug or map_data[player.world].tiles[player.y][player.x] == "<" then
		player.world = "overworld"
		map.update_visibility(player, map_data)
		return true
	end
	return false
end

function map.move_down(player, map_data)
	if config.debug or map_data[player.world].tiles[player.y][player.x] == ">" then
		player.world = "underworld"
		map.update_visibility(player, map_data)
		return true
	end
	return false
end

function map.update_visibility(player, map_data)
	for y = utils.clamp(player.y - player.radius, 1, config.map.height), utils.clamp(player.y + player.radius, 1, config.map.height) do
		for x = utils.clamp(player.x - player.radius, 1, config.map.width), utils.clamp(player.x + player.radius, 1, config.map.width) do
			if math.sqrt((x - player.x)^2 + (y - player.y)^2) <= player.radius then
				map_data[player.world].visited[y][x] = true
			end
		end
	end
end

function map.display_location(player, map_data)
	local location = map.get_location_description(map_data[player.world].tiles[player.y][player.x])
	output.add("You are in " .. location.name .. ". " .. location.description .. "\n")
	
	local directions = {
		north = {x = player.x, y = player.y - 1, name = "North"},
		south = {x = player.x, y = player.y + 1, name = "South"},
		east = {x = player.x + 1, y = player.y, name = "East"},
		west = {x = player.x - 1, y = player.y, name = "West"}
	}
	
	local visible_directions = {}
	for dir, data in pairs(directions) do
		if is_valid_position(data.x, data.y) then
			local tile_symbol = map_data[player.world].tiles[data.y][data.x]
			local tile_data = map.get_location_description(tile_symbol)
			visible_directions[dir] = tile_data.name
		end
	end
	
	local direction_groups = {}
	for dir, name in pairs(visible_directions) do
		direction_groups[name] = direction_groups[name] or {}
		table.insert(direction_groups[name], directions[dir].name)
	end
	
	local direction_strings = {}
	for biome, dirs in pairs(direction_groups) do
		local dir_names = table.concat(dirs, ", ")
		table.insert(direction_strings, "To " .. dir_names .. " you see " .. biome .. ".")
	end
	
	output.add("\n")
	if #direction_strings > 0 then
		output.add(table.concat(direction_strings, "\n") .. "\n")
	end
	
	local items_string = items.get_tile_items_string(map_data[player.world], player.x, player.y)
	output.add(items_string)
	local enemies_string = enemies.get_tile_enemies_string(map_data[player.world], player.x, player.y)
	output.add(enemies_string)
	if map_data[player.world].fire.active and map_data[player.world].fire.x == player.x and map_data[player.world].fire.y == player.y then
		output.add(const.FIRE_IS_BURNING)
	end
end

function map.draw()
	for y = 1, config.map.height do
		local line = ""
		for x = 1, config.map.width do
			if x == player.x and y == player.y then
				if player.alive then
					line = line .. player.symbol
				else
					line = line .. "X"
				end
			elseif config.debug or map_data[player.world].visited[y][x] then
				line = line .. map_data[player.world].tiles[y][x]
			else
				line = line .. " "
			end
		end
		output.add(line .. "\n")
	end
end

return map