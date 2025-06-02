local game = {
	initialized = false,
}

function game.welcome()
    output.add("Welcome to " .. config.game.name .. " v." .. config.game.version .. "\n")
	if config.debug then
		output.add("Debug mode: on\n")
	end
    game.initialized = false
    if love.filesystem.getInfo("game.json") then
        game.load_game()
        output.add("Type 'help' to see a list of available commands.\n")
    else
        game.new_game()
    end
end

function game.about()
    output.add(config.game.name .. " v." .. config.game.version .. "\n\n")
    output.add("Enter the mysterious Troll Dungeon, a dark and dangerous maze hidden deep underground. Legends speak of the Sword of Dawn, a powerful artifact guarded by ancient magic and deadly creatures. As the brave hero, you must navigate traps, solve puzzles, and face the troll guardians to claim the sword. Only by wielding the Sword of Dawn can you defeat the final evil and win the game.\n")
    output.add("\nAuthor: Apromix\n")
    output.add("\nSources: https://github.com/devapromix/dungeons-and-trolls\n")
end

function game.new_game()
    map.initialize_game(locations_data)
    player = player_module.starter_kit(player)
    game.initialized = true
    output.add("Created new game.\n")
    map.display_location_and_items(player, map_data)
    output.add("Type 'help' to see a list of available commands.\n")
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
        fire = {
            overworld = map_data.overworld.fire,
            underworld = map_data.underworld.fire
        }
    }
    local save_string = json.encode(save_data)
    love.filesystem.write("game.json", save_string)
    output.add("Game saved.\n")
end

function game.load_game()
    if love.filesystem.getInfo("game.json") then
        local save_string = love.filesystem.read("game.json")
        if save_string then
            local save_data = json.decode(save_string)
            if save_data then
                if save_data.version ~= config.game.version then
                    output.add("Saved game version (" .. (save_data.version or "unknown") .. ") is incompatible with current game version (" .. config.game.version .. ").\n")
                    output.add("Please start a new game with the 'new' command.\n")
                    game.initialized = false
                    return false
                end
                map_data = save_data.map or { overworld = {}, underworld = {} }
                player = save_data.player
                game_time = save_data.time or { year = 1280, month = 4, day = 1, hour = 6, minute = 0 }
                input.history = save_data.history or {}
                map_data.overworld.fire = save_data.fire and save_data.fire.overworld or { x = nil, y = nil, active = false }
                map_data.underworld.fire = save_data.fire and save_data.fire.underworld or { x = nil, y = nil, active = false }
                player = player_module.clamp_player_stats(player)
                player = player_module.clamp_player_skills(player, skills_data)
                player.inventory = player.inventory or {}
                player.equipment = player.equipment or { weapon = nil, armor = nil }
                player.skills = player.skills or {}
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
                    output.add("Cannot load game: player is dead. Start a new game with the 'new' command.\n")
                    game.initialized = false
                    return false
                end
                output.add("Loaded saved game.\n")
                map.display_location_and_items(player, map_data)
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