local game = {}

function game.new_game()
    map.initialize_game(locations_data)
    output.add("Created new game.\n")
    map.display_location_and_items(player, map_data)
    output.add("Type 'help' to see a list of available commands.\n")
end

function game.save_game()
    local save_data = {
        map = map_data,
        player = player,
        history = input.history,
        time = game_time,
        version = config.game.version,
        fire = map_data.fire
    }
    
    local save_string = json.encode(save_data)
    love.filesystem.write("game.json", save_string)
    output.add("Game saved.\n")
end

function game.load_game()

end

return game