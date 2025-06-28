local chop = {}

function chop.exec(player, map_data, items_data, time, player_module, items)
    if not player_module.check_player_alive("chop wood", player) then
        return player
    end
    local location = map.get_location_by_symbol(map_data[player.world].tiles[player.y][player.x])
    if not location.chop_allowed then
        output.add("You cannot chop wood in this location.\n")
        return player
    end
    if not player_module.has_chop_item(player, items_data) then
        output.add("You need an equipped item suitable for chopping (e.g., an axe) to chop wood.\n")
        return player
    end
    map_data[player.world].items[player.y][player.x]["Firewood"] = (map_data[player.world].items[player.y][player.x]["Firewood"] or 0) + 1
    player_module.add_hunger(player, 2)
    player_module.add_thirst(player, 2)
    player_module.add_fatigue(player, 5)
    time.tick_time(60)
    output.add("You chop some wood.\n\n")
	map.display_location(player, map_data)
    return player
end

return chop