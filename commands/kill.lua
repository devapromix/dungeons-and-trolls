local kill = {}

function kill.exec(command_parts, player, map_data, items_data, enemies_data, skills_data, time, map, output, player_module)
    if #command_parts < 2 then
        output.add("Please specify an enemy to kill (e.g., 'kill Goblin').\n")
        return player
    end
    
    local enemy_name = commands.get_item_name_from_parts(command_parts, 2)
    if commands.validate_parameter(enemy_name, "enemy", output) then
        combat.attack_enemy(enemy_name, map_data, player, enemies_data, items_data, skills_data, time, map, output, player_module)
    end
    
    return player
end

return kill