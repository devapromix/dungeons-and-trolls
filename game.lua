local game = {
	initialized = false,
	unique_items = {},
	shop_items_cache = {}
}

function game.initialize_unique_items(items_data)
	game.unique_items = {}
	for _, item in ipairs(items_data.items) do
		if items.is_artifact(item) then
			game.unique_items[item.name] = false
		end
	end
end

function game.welcome()
	output.add("Welcome to " .. config.game.name .. "\n\n")
	if config.debug then
		output.add("Debug mode: on\n\n")
	end
	game.intro()
	game.initialized = false
	if love.filesystem.getInfo("game.json") then
		game.load_game()
		output.add(const.TYPE_HELP_MSG)
	else
		game.new_game()
	end
end

function game.about()
	output.add(config.game.name .. "\n\n")
	output.add("Version: " .. config.game.version .. "\n\n")
	utils.output_text_file("assets/data/about.txt")
end

function game.help()
	utils.output_text_file("assets/data/help.txt")
end

function game.intro()
	utils.output_text_file("assets/data/intro.txt")
end

function game.victory()
	utils.output_text_file("assets/data/victory.txt")
end

function game.defeat()
	utils.output_text_file("assets/data/defeat.txt")
end

function game.new_game()
	music.play_random()
	map.initialize_game(locations_data)
	fire_data = {
		overworld = { x = nil, y = nil, active = false },
		underworld = { x = nil, y = nil, active = false }
	}
	game_time = { year = 1280, month = 4, day = 1, hour = 6, minute = 0, playtime = 0 }
	input.history = {}
	game.shop_items_cache = {}
	game.initialized = true
	output.add("Created new game.\n\n")
	map.display_location(player, map_data)
	output.add(const.TYPE_HELP_MSG)
end

function game.save_game()
	if not game.initialized then
		return
	end
	local save_data = {
		map = map_data,
		player = player,
		history = input.history,
		time = game_time,
		version = config.game.version,
		fire = fire_data,
		unique_items = game.unique_items,
		shop_items_cache = game.shop_items_cache
	}
	local save_string = json.encode(save_data)
	love.filesystem.write("game.json", save_string)
	output.add("Game saved.\n")
end

function game.load_game()
	music.play_random()
	if love.filesystem.getInfo("game.json") then
		local save_string = love.filesystem.read("game.json")
		if save_string then
			local save_data = json.decode(save_string)
			if save_data then
				if save_data.version ~= config.game.version then
					output.add("Saved game version (" .. (save_data.version or "unknown") .. ") is incompatible with current game version (" .. config.game.version .. ").\n")
					output.add(const.START_NEW_GAME_MSG)
					game.initialized = false
					return false
				end
				map_data = save_data.map or { overworld = {}, underworld = {} }
				player = save_data.player
				player.equipment_status = player.equipment_status or { weapon = "", armor = "" }
				player.spellbook = player.spellbook or {}
				game_time = save_data.time or { year = 1280, month = 4, day = 1, hour = 6, minute = 0, playtime = 0 }
				input.history = save_data.history or {}
				game.unique_items = save_data.unique_items or {}
				game.shop_items_cache = save_data.shop_items_cache or {}
				fire_data = save_data.fire or {
					overworld = { x = nil, y = nil, active = false },
					underworld = { x = nil, y = nil, active = false }
				}
				game.initialize_unique_items(items_data)
				for item_name, exists in pairs(save_data.unique_items or {}) do
					game.unique_items[item_name] = exists
				end
				player = player_module.clamp_player_stats(player)
				player.inventory = player.inventory or {}
				player.equipment = player.equipment or { weapon = nil, armor = nil }
				player.skills = player.skills or {}
				player.spellbook = player.spellbook or {}
				for _, skill in ipairs(skills_data.skills) do
					player.skills[skill.name] = player.skills[skill.name] or skill.initial_level
				end
				player.level = player.level or 1
				player.experience = player.experience or 0
				if player.alive == nil then
					player.alive = (player.hunger < 100 and player.fatigue < 100 and player.health > 0 and player.thirst < 100)
				end
				for world in pairs({ overworld = true, underworld = true }) do
					if not map_data[world].tiles or not map_data[world].visited or not map_data[world].items or not map_data[world].enemies then
						output.add("Invalid map data for " .. world .. ". Starting a new game.\n")
						game.new_game()
						return false
					end
					for y = 1, config.map.height do
						map_data[world].items[y] = map_data[world].items[y] or {}
						map_data[world].enemies[y] = map_data[world].enemies[y] or {}
						map_data[world].visited[y] = map_data[world].visited[y] or {}
						for x = 1, config.map.width do
							map_data[world].items[y][x] = map_data[world].items[y][x] or {}
							map_data[world].enemies[y][x] = map_data[world].enemies[y][x] or {}
							map_data[world].visited[y][x] = map_data[world].visited[y][x] or false
						end
					end
				end
				if not player.alive then
					output.add("Cannot load game: player is DEAD.\n\n")
					output.add(const.START_NEW_GAME_MSG)
					game.initialized = false
					return false
				end
				output.add("Loaded saved game.\n\n")
				map.display_location(player, map_data)
				game.initialized = true
				return true
			end
		end
		output.add("Failed to read saved game.\n")
	else
		output.add("No saved game found.\n")
	end
	game.initialized = false
	return false
end

return game