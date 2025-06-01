local game = {}

function game.new_game()
    map.initialize_game(locations_data)
    output.add("Created new game.\n")
    map.display_location_and_items(player, map_data)
    output.add("Type 'help' to see a list of available commands.\n")
end

function game.save_game()

end

function game.load_game()

end

return game