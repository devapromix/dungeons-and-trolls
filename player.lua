local output = require("output")
local map = require("map")
local time = require("time")
local items = require("items")

local player = {}

function player.clamp_player_stats(player_data)
    player_data.health = math.min(100, math.max(0, player_data.health))
    player_data.mana = math.min(100, math.max(0, player_data.mana))
    player_data.hunger = math.min(100, math.max(0, player_data.hunger))
    player_data.fatigue = math.min(100, math.max(0, player_data.fatigue))
    player_data.thirst = math.min(100, math.max(0, player_data.thirst))
    player_data.attack = math.max(0, player_data.attack)
    player_data.defense = math.max(0, player_data.defense)
    return player_data
end

function player.clamp_player_skills(player_data, skills_data)
    if not player_data.skills then
        player_data.skills = {}
    end
    for _, skill in ipairs(skills_data.skills) do
        player_data.skills[skill.name] = math.min(skill.max_level, math.max(0, player_data.skills[skill.name] or skill.initial_level))
    end
    return player_data
end

function player.equip_item(player_data, items_data, item_name)
    if not player_data.alive then
        output.add("You are dead and cannot equip items.\nStart a new game with the 'new' command.\n")
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
    if not player_data.alive then
        output.add("You are dead and cannot unequip items.\nStart a new game with the 'new' command.\n")
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
    if not player_data.alive then
        output.add("You are dead and cannot move.\nStart a new game with the 'new' command.\n")
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
        for y = math.max(1, player_data.y - player_data.radius), math.min(config.map.height, player_data.y + player_data.radius) do
            for x = math.max(1, player_data.x - player_data.radius), math.min(config.map.width, player_data.x + player_data.radius) do
                if math.sqrt((x - player_data.x)^2 + (y - player_data.y)^2) <= player_data.radius then
                    map_data.visited[y][x] = true
                end
            end
        end
        output.add("You moved " .. move.dir .. ".\n")
        local location = map.get_location_description(map_data.tiles[player_data.y][player_data.x])
        output.add("You are in " .. location.name .. ". " .. location.description .. "\n")
        local items_string = items.get_tile_items_string(map_data, player_data.x, player_data.y)
        output.add(items_string)
        local enemies_string = enemies.get_tile_enemies_string(map_data, player_data.x, player_data.y)
        output.add(enemies_string)
        if map_data.fire.active and map_data.fire.x == player_data.x and map_data.fire.y == player_data.y then
            output.add("A fire is burning here.\n")
        end
        local current_biome = map_data.tiles[player_data.y][player_data.x]
        local effects = map.get_biome_effects(current_biome)
        time.tick_time(120)
        player_data.fatigue = math.min(100, math.max(0, player_data.fatigue + (player_data.mana <= 0 and effects.fatigue * 2 or effects.fatigue)))
        player_data.hunger = math.min(100, math.max(0, player_data.hunger + effects.hunger))
        player_data.thirst = math.min(100, math.max(0, player_data.thirst + effects.thirst))
        if player_data.hunger >= 100 then
            player_data.hunger = 100
            player_data.alive = false
            output.add("You died from starvation.\n")
        elseif player_data.fatigue >= 100 then
            player_data.fatigue = 100
            player_data.alive = false
            output.add("You died from exhaustion.\n")
        elseif player_data.health <= 0 then
            player_data.health = 0
            player_data.alive = false
            output.add("You died from injuries.\n")
        elseif player_data.thirst >= 100 then
            player_data.thirst = 100
            player_data.alive = false
            output.add("You died from thirst.\n")
        end
        return true
    else
        output.add("You can't move further " .. move.dir .. ".\n")
        return false
    end
end

return player