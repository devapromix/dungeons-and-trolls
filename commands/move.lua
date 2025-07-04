local move = {}

function move.move_player(direction, player_data, map_data, config, time, output, map, music, fire)
    if not move.check_player_alive("move", player_data, output) then
        return false
    end
    
    local moves = {
        north = {y = -1, x_min = 1, x_max = config.map.width, y_min = 2, y_max = config.map.height, dir = "north"},
        south = {y = 1, x_min = 1, x_max = config.map.width, y_min = 1, y_max = config.map.height - 1, dir = "south"},
        east = {x = 1, x_min = 1, x_max = config.map.width - 1, y_min = 1, y_max = config.map.height, dir = "east"},
        west = {x = -1, x_min = 2, x_max = config.map.width, y_min = 1, y_max = config.map.height, dir = "west"}
    }
    
    local move_data = moves[direction]
    if not move_data then return false end
    
    local new_x = player_data.x + (move_data.x or 0)
    local new_y = player_data.y + (move_data.y or 0)
    
    if new_x >= move_data.x_min and new_x <= move_data.x_max and new_y >= move_data.y_min and new_y <= move_data.y_max then
        local target_symbol = map_data[player_data.world].tiles[new_y][new_x]
        local location_data = map.get_location_description(target_symbol)
        
        if not location_data.passable then
            output.add("You cannot pass through the wall.\n")
            return false
        end
        
        if fire_data[player_data.world].active and (fire_data[player_data.world].x ~= new_x or fire_data[player_data.world].y ~= new_y) then
            fire_data[player_data.world].active = false
            fire_data[player_data.world].x = nil
            fire_data[player_data.world].y = nil
            output.add("The fire goes out as you leave the location.\n")
        end

        if map_data[player_data.world].tiles[player_data.y][player_data.x] == "v" then
            if player_data.x ~= new_x or player_data.y ~= new_y then
                music.play_random()
            end
        end

        player_data.x = new_x
        player_data.y = new_y
        
		map.update_visibility(player_data, map_data)
        
        output.add("You moved " .. move_data.dir .. ".\n")
        map.display_location(player_data, map_data)
        
        local current_biome = map_data[player_data.world].tiles[player_data.y][player_data.x]
        local effects = map.get_biome_effects(current_biome)
        
        time.tick_time(60)
        player_data.fatigue = utils.clamp(player_data.fatigue + (player_data.mana <= 0 and effects.fatigue * 2 or effects.fatigue), 0, 100)
        player_data.hunger = utils.clamp(player_data.hunger + effects.hunger, 0, 100)
        player_data.thirst = utils.clamp(player_data.thirst + effects.thirst, 0, 100)
        
        return true
    else
        output.add("You can't move further " .. move_data.dir .. ".\n")
        return false
    end
end

function move.check_player_alive(action, player_data, output)
    if not player_data.alive then
        output.add("You are DEAD and cannot " .. action .. ".\n\n")
        output.add(const.START_NEW_GAME_MSG)
        return false
    end
    return true
end

function move.exec(direction, player, map_data, config, time, output, player_module, map, music, utils, fire)
    if not move.check_player_alive("move " .. direction, player, output) then
        return player
    end

    if direction == "up" then
        if map.move_up(player, map_data) then
            music.play_random()
            output.add("You climb up to the surface.\n")
            map.display_location(player, map_data)
        else
            output.add("There is no entrance here.\n")
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
        if move.move_player(direction, player, map_data, config, time, output, map, music, fire) then
            local status_message = player_module.check_player_status(player)
            if status_message ~= "" then
                output.add(status_message)
            end
        end
    end

    return player
end

return move