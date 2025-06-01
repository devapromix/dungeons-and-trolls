local player = {}

function player.draw_status(player_data)
    output.add("Player:\n")
    output.add("Health: " .. player_data.health .. "\n")
    output.add("Mana: " .. player_data.mana .. "\n")
    output.add("Hunger: " .. player_data.hunger .. "\n")
    output.add("Fatigue: " .. player_data.fatigue .. "\n")
    output.add("Thirst: " .. player_data.thirst .. "\n")
    output.add("Attack: " .. player_data.attack .. "\n")
    output.add("Defense: " .. player_data.defense .. "\n")
    output.add("Level: " .. player_data.level .. "\n")
    output.add("Experience: " .. player_data.experience .. "\n")
    output.add("\nGold: " .. player_data.gold .. "\n")
    output.add("Position: " .. player_data.x .. ", " .. player_data.y .. "\n")
    output.add("\nEquipment:\n")
    output.add("Weapon: " .. (player_data.equipment and player_data.equipment.weapon or "None") .. "\n")
    output.add("Armor: " .. (player_data.equipment and player_data.equipment.armor or "None") .. "\n")
    output.add("\nSkills:\n")
    skills.draw()
    if not player_data.alive then
        output.add("\nYou are DEAD.\nUse 'new' command to start a new game.\n")
    end
end

function player.clamp_player_stats(player_data)
    player_data.health = utils.clamp(player_data.health, 0, 100)
    player_data.mana = utils.clamp(player_data.mana, 0, 100)
    player_data.hunger = utils.clamp(player_data.hunger, 0, 100)
    player_data.fatigue = utils.clamp(player_data.fatigue, 0, 100)
    player_data.thirst = utils.clamp(player_data.thirst, 0, 100)
    player_data.attack = utils.clamp(player_data.attack, 0, math.huge)
    player_data.defense = utils.clamp(player_data.defense, 0, math.huge)
    return player_data
end

function player.clamp_player_skills(player_data, skills_data)
    if not player_data.skills then
        player_data.skills = {}
    end
    if not skills_data or not skills_data.skills then
        output.add("Error: No valid skills data provided.\n")
        return player_data
    end
    for _, skill in ipairs(skills_data.skills) do
        if skill and skill.name and skill.max_level then
            local initial_level = skill.initial_level or 0
            player_data.skills[skill.name] = utils.clamp(player_data.skills[skill.name] or initial_level, 0, skill.max_level)
        else
            output.add("Warning: Invalid skill entry in skills data.\n")
        end
    end
    return player_data
end

function player.rest(player_data, map_data, game_time, time)
    if player_data.health >= 100 and player_data.mana >= 100 and player_data.fatigue <= 0 then
        output.add("You don't need to rest.\n")
        return player_data
    end
    local hours_to_full = math.max(
        math.ceil((100 - player_data.health) / 10),
        math.ceil((100 - player_data.mana) / 10),
        math.ceil(player_data.fatigue / 10)
    )
    local hours_to_morning = 0
    if game_time.hour >= 18 then
        hours_to_morning = (24 - game_time.hour) + 6
    elseif game_time.hour < 6 then
        hours_to_morning = 6 - game_time.hour
    end
    local rest_hours = hours_to_full
    if hours_to_morning > 0 then
        rest_hours = utils.clamp(hours_to_full, 0, hours_to_morning)
    end
    local rest_multiplier = map_data.fire.active and map_data.fire.x == player_data.x and map_data.fire.y == player_data.y and 2 or 1
    output.add("You rest for " .. rest_hours .. " hour(s)...\n")
    player_data.health = player_data.health + rest_hours * 10 * rest_multiplier
    player_data.mana = player_data.mana + rest_hours * 10 * rest_multiplier
    player_data.fatigue = player_data.fatigue - rest_hours * 10 * rest_multiplier
    player_data.hunger = player_data.hunger + rest_hours * 0.5
    player_data.thirst = player_data.thirst + rest_hours * 2.5
    player_data = player.clamp_player_stats(player_data)
    time.tick_time(rest_hours * 60)
    output.add("Your health, mana, and fatigue have been restored.\n")
    if rest_multiplier > 1 then
        output.add("Resting by the fire makes you recover twice as fast!\n")
    end
    if rest_hours > 0 then
        output.add("You feel hungrier and thirstier.\n")
    end
    local status_message = player.check_player_status(player_data)
    if status_message ~= "" then
        output.add(status_message)
    end
    return player_data
end

function player.equip_item(player_data, items_data, item_name)
    if not player.check_player_alive("equip items", player_data) then
        return player_data
    end
    
    local item_key = items.find_item_key(player_data.inventory, item_name)
    if not item_key then
        output.add("You don't have " .. item_name .. " in your inventory.\n")
        return player_data
    end
    
    local item_data = items.get_item_data(items_data, item_key)
    if not item_data then
        output.add("No data found for " .. item_key .. ".\n")
        return player_data
    end
    
    local is_weapon = false
    local is_armor = false
    local weapon_value = nil
    local armor_value = nil
    
    for _, tag in ipairs(item_data.tags) do
        if tag:match("^weapon=") then
            is_weapon = true
            weapon_value = tonumber(tag:match("^weapon=(%S+)"))
        elseif tag:match("^armor=") then
            is_armor = true
            armor_value = tonumber(tag:match("^armor=(%S+)"))
        end
    end
    
    if not is_weapon and not is_armor then
        output.add(item_key .. " cannot be equipped.\n")
        return player_data
    end
    
    if is_weapon then
        if player_data.equipment.weapon then
            local current_weapon_data = items.get_item_data(items_data, player_data.equipment.weapon)
            if current_weapon_data then
                for _, tag in ipairs(current_weapon_data.tags) do
                    if tag:match("^weapon=") then
                        player_data.attack = player_data.attack - tonumber(tag:match("^weapon=(%S+)"))
                        break
                    end
                end
            end
        end
        player_data.equipment.weapon = item_key
        player_data.attack = player_data.attack + weapon_value
        output.add("You equipped " .. item_key .. ".\n")
    elseif is_armor then
        if player_data.equipment.armor then
            local current_armor_data = items.get_item_data(items_data, player_data.equipment.armor)
            if current_armor_data then
                for _, tag in ipairs(current_armor_data.tags) do
                    if tag:match("^armor=") then
                        player_data.defense = player_data.defense - tonumber(tag:match("^armor=(%S+)"))
                        break
                    end
                end
            end
        end
        player_data.equipment.armor = item_key
        player_data.defense = player_data.defense + armor_value
        output.add("You equipped " .. item_key .. ".\n")
    end
    
    return player_data
end

function player.unequip_item(player_data, items_data, identifier)
    if not player.check_player_alive("unequip items", player_data) then
        return player_data
    end
    
    local slot
    if identifier:lower() == "weapon" then
        slot = "weapon"
    elseif identifier:lower() == "armor" then
        slot = "armor"
    else
        slot = items.is_item_equipped(player_data, identifier) and (player_data.equipment.weapon == identifier and "weapon" or "armor") or nil
    end
    
    if not slot then
        output.add(identifier .. " is not equipped or invalid slot specified.\n")
        return player_data
    end
    
    local equipped_item = player_data.equipment[slot]
    if not equipped_item then
        output.add("No " .. slot .. " is currently equipped.\n")
        return player_data
    end
    
    local item_data = items.get_item_data(items_data, equipped_item)
    if not item_data then
        output.add("No data found for " .. equipped_item .. ".\n")
        return player_data
    end
    
    if slot == "weapon" then
        for _, tag in ipairs(item_data.tags) do
            if tag:match("^weapon=") then
                player_data.attack = player_data.attack - tonumber(tag:match("^weapon=(%S+)"))
                break
            end
        end
        player_data.equipment.weapon = nil
        output.add("You unequipped " .. equipped_item .. ".\n")
    elseif slot == "armor" then
        for _, tag in ipairs(item_data.tags) do
            if tag:match("^armor=") then
                player_data.defense = player_data.defense - tonumber(tag:match("^armor=(%S+)"))
                break
            end
        end
        player_data.equipment.armor = nil
        output.add("You unequipped " .. equipped_item .. ".\n")
    end
    
    return player_data
end

function player.move_player(direction, player_data, map_data, config, time, output)
    if not player.check_player_alive("move", player_data) then
        return false
    end
    local moves = {
        north = {y = -1, x_min = 1, x_max = config.map.width, y_min = 2, y_max = config.map.height, dir = "north"},
        south = {y = 1, x_min = 1, x_max = config.map.width, y_min = 1, y_max = config.map.height - 1, dir = "south"},
        east = {x = 1, x_min = 1, x_max = config.map.width - 1, y_min = 1, y_max = config.map.height, dir = "east"},
        west = {x = -1, x_min = 2, x_max = config.map.width, y_min = 1, y_max = config.map.height, dir = "west"}
    }
    local move = moves[direction]
    if not move then return false end
    local new_x = player_data.x + (move.x or 0)
    local new_y = player_data.y + (move.y or 0)
    if new_x >= move.x_min and new_x <= move.x_max and new_y >= move.y_min and new_y <= move.y_max then
        if map_data.fire.active and (map_data.fire.x ~= new_x or map_data.fire.y ~= new_y) then
            map_data.fire.active = false
            map_data.fire.x = nil
            map_data.fire.y = nil
            output.add("The fire goes out as you leave the location.\n")
        end
        player_data.x = new_x
        player_data.y = new_y
        for y = utils.clamp(player_data.y - player_data.radius, 1, config.map.height), utils.clamp(player_data.y + player_data.radius, 1, config.map.height) do
            for x = utils.clamp(player_data.x - player_data.radius, 1, config.map.width), utils.clamp(player_data.x + player_data.radius, 1, config.map.width) do
                if math.sqrt((x - player_data.x)^2 + (y - player_data.y)^2) <= player_data.radius then
                    map_data.visited[y][x] = true
                end
            end
        end
        output.add("You moved " .. move.dir .. ".\n")
        map.display_location_and_items(player_data, map_data)
        local current_biome = map_data.tiles[player_data.y][player_data.x]
        local effects = map.get_biome_effects(current_biome)
        time.tick_time(120)
        player_data.fatigue = utils.clamp(player_data.fatigue + (player_data.mana <= 0 and effects.fatigue * 2 or effects.fatigue), 0, 100)
        player_data.hunger = utils.clamp(player_data.hunger + effects.hunger, 0, 100)
        player_data.thirst = utils.clamp(player_data.thirst + effects.thirst, 0, 100)
        return true
    else
        output.add("You can't move further " .. move.dir .. ".\n")
        return false
    end
end

function player.check_player_status(player_data)
    player_data = player.clamp_player_stats(player_data)
    if player_data.hunger >= 100 then
        player_data.hunger = utils.clamp(player_data.hunger, 0, 100)
        player_data.alive = false
        return "You died from starvation.\n"
    elseif player_data.fatigue >= 100 then
        player_data.fatigue = utils.clamp(player_data.fatigue, 0, 100)
        player_data.alive = false
        return "You died from exhaustion.\n"
    elseif player_data.health <= 0 then
        player_data.health = utils.clamp(player_data.health, 0, 100)
        player_data.alive = false
        return "You died from injuries.\n"
    elseif player_data.thirst >= 100 then
        player_data.thirst = utils.clamp(player_data.thirst, 0, 100)
        player_data.alive = false
        return "You died from thirst.\n"
    end
    return ""
end

function player.check_player_alive(action, player_data)
    if not player_data.alive then
        output.add("You are dead and cannot " .. action .. ".\nStart a new game with the 'new' command.\n")
        return false
    end
    return true
end

function player.attack_enemy(enemy_name, map_data, player_data, enemies_data, items_data, skills_data, time, map, output)
    if not player.check_player_alive("attack", player_data) then
        return
    end
    if not enemy_name or enemy_name == "" then
        output.add("Please specify an enemy to attack (e.g., 'attack Goblin').\n")
        return
    end
    local enemy_list = map_data.enemies[player_data.y][player_data.x]
    local enemy_key = items.find_item_key(enemy_list, enemy_name)
    if not enemy_key then
        output.add("No " .. enemy_name .. " found here.\n")
        return
    end
    local enemy_data = enemies.get_enemy_data(enemies_data, enemy_key)
    if not enemy_data then
        output.add("No data found for " .. enemy_key .. ".\n")
        return
    end
    output.add("You engage " .. enemy_key .. " in combat!\n")
    player.combat_round(enemy_key, enemy_data, map_data, player_data, items_data, skills_data, time, map, output)
end

function player.combat_round(enemy_name, enemy_data, map_data, player_data, items_data, skills_data, time, map, output)
    local enemy_health = enemy_data.health
    while player_data.health > 0 and enemy_health > 0 do
        local miss_chance = player_data.fatigue > 70 and ((player_data.fatigue - 70) / 30) * 0.5 or 0
        if math.random() >= miss_chance then
            local player_damage = utils.clamp(player_data.attack - enemy_data.defense, 0, math.huge)
            player_damage = skills.apply_skill_effects(player_data, skills_data, player_damage)
            if player_damage > 0 then
                enemy_health = enemy_health - player_damage
                output.add("You hit " .. enemy_name .. " for " .. player_damage .. " damage.\n")
            else
                output.add("Your attack is blocked by " .. enemy_name .. ".\n")
            end
        else
            output.add("You missed your attack due to fatigue!\n")
        end
        if enemy_health <= 0 then
            output.add("You defeated " .. enemy_name .. "!\n")
            player_data.experience = player_data.experience + enemy_data.experience
            output.add("Gained " .. enemy_data.experience .. " experience.\n")
            if player_data.equipment and player_data.equipment.weapon then
                local item_data = items.get_item_data(items_data, player_data.equipment.weapon)
                if item_data then
                    skills.upgrade_skill(player_data, skills_data, item_data)
                end
            end
            if enemy_data.drops then
                for _, drop in ipairs(enemy_data.drops) do
                    if math.random() < drop.chance then
                        local quantity = drop.quantity and math.random(drop.quantity[1], drop.quantity[2]) or 1
                        if drop.type == "gold" then
                            player_data.gold = player_data.gold + quantity
                            output.add("Gained " .. quantity .. " gold.\n")
                        elseif drop.type == "item" then
                            map_data.items[player_data.y][player_data.x][drop.name] = (map_data.items[player_data.y][player_data.x][drop.name] or 0) + quantity
                            output.add(drop.name .. " (" .. quantity .. ") dropped on the ground.\n")
                        end
                    end
                end
            end
            map_data.enemies[player_data.y][player_data.x][enemy_name] = map_data.enemies[player_data.y][player_data.x][enemy_name] - 1
            if map_data.enemies[player_data.y][player_data.x][enemy_name] <= 0 then
                map_data.enemies[player_data.y][player_data.x][enemy_name] = nil
            end
            map.display_location_and_items(player_data, map_data)
            return true
        end
        local enemy_damage = utils.clamp(enemy_data.attack - player_data.defense, 0, math.huge)
        if enemy_damage > 0 then
            player_data.health = player_data.health - enemy_damage
            output.add(enemy_name .. " hits you for " .. enemy_damage .. " damage.\n")
        else
            output.add(enemy_name .. "'s attack is blocked.\n")
        end
        if player_data.health <= 0 then
            player_data.alive = false
            output.add("You were defeated by " .. enemy_name .. ".\n")
            output.add("Game over. Start a new game with the 'new' command.\n")
            local save_data = {
                map = map_data,
                player = player_data,
                history = input.history,
                time = game_time,
                version = config.game.version,
                fire = map_data.fire
            }
            local save_string = json.encode(save_data)
            love.filesystem.write("game.json", save_string)
            return false
        end
        time.tick_time(10)
    end
    return false
end

return player