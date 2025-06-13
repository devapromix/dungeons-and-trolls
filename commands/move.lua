local move = {}

function move.exec(direction, player, map_data, config, time, output, player_module, map, music)
    if not player_module.check_player_alive("move " .. direction, player) then
        return player
    end

    if direction == "up" then
        if map.move_up(player, map_data) then
            music.play_random()
            output.add("You climb up to the surface.\n")
            map.display_location(player, map_data)
        else
            output.add("There is no exit here.\n")
        end
    elseif direction == "down" then
        if map.move_down(player, map_data) then
            music.play_random()
            output.add("You descend into the underworld.\n")
            map.display_location(player, map_data)
        else
            output.add("There is no entrance here.\n")
        end
    else
        if player_module.move_player(direction, player, map_data, config, time, output) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    end

    return player
end

return move