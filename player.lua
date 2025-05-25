local player = {}

function player.clamp_player_stats(player_data)
    player_data.health = math.min(100, math.max(0, player_data.health))
    player_data.mana = math.min(100, math.max(0, player_data.mana))
    player_data.hunger = math.min(100, math.max(0, player_data.hunger or 0))
    player_data.fatigue = math.min(100, math.max(0, player_data.fatigue or 0))
    player_data.thirst = math.min(100, math.max(0, player_data.thirst or 0))
    player_data.gold = math.max(0, player_data.gold or 0)
    player_data.attack = math.max(0, player_data.attack or 0)
    player_data.defense = math.max(0, player_data.defense or 0)
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

    local attack_value, defense_value
    for _, tag in ipairs(item_data.tags) do
        if tag:match("^weapon=") then
            attack_value = tonumber(tag:match("^weapon=(%S+)"))
        elseif tag:match("^armor=") then
            defense_value = tonumber(tag:match("^armor=(%S+)"))
        end
    end

    if not attack_value and not defense_value then
        output.add(item_key .. " cannot be equipped.\n")
        return player_data
    end

    player_data.equipment = player_data.equipment or { weapon = nil, armor = nil }

    if attack_value then
        if player_data.equipment.weapon then
            output.add("You already have a weapon equipped. Unequip it first.\n")
            return player_data
        end
        player_data.equipment.weapon = item_key
        player_data.attack = player_data.attack + attack_value
        output.add("Equipped " .. item_key .. " as weapon (+" .. attack_value .. " attack).\n")
    elseif defense_value then
        if player_data.equipment.armor then
            output.add("You already have armor equipped. Unequip it first.\n")
            return player_data
        end
        player_data.equipment.armor = item_key
        player_data.defense = player_data.defense + defense_value
        output.add("Equipped " .. item_key .. " as armor (+" .. defense_value .. " defense).\n")
    end

    return player_data
end

function player.unequip_item(player_data, items_data, identifier)
    if not player_data.alive then
        output.add("You are dead and cannot unequip items.\nStart a new game with the 'new' command.\n")
        return player_data
    end

    if not player_data.equipment then
        output.add("No items are equipped.\n")
        return player_data
    end

    local item_key, slot
    if identifier == "weapon" or identifier == "armor" then
        slot = identifier
        item_key = player_data.equipment[slot]
    else
        item_key = items.find_item_key(player_data.inventory, identifier)
        if not item_key or (player_data.equipment.weapon ~= item_key and player_data.equipment.armor ~= item_key) then
            output.add(identifier .. " is not equipped.\n")
            return player_data
        end
        slot = player_data.equipment.weapon == item_key and "weapon" or "armor"
    end

    if not item_key then
        output.add("No " .. slot .. " is equipped.\n")
        return player_data
    end

    local item_data = items.get_item_data(items_data, item_key)
    if not item_data then
        output.add("No data found for " .. item_key .. ".\n")
        return player_data
    end

    local attack_value, defense_value
    for _, tag in ipairs(item_data.tags) do
        if tag:match("^weapon=") then
            attack_value = tonumber(tag:match("^weapon=(%S+)"))
        elseif tag:match("^armor=") then
            defense_value = tonumber(tag:match("^armor=(%S+)"))
        end
    end

    if slot == "weapon" and attack_value then
        player_data.attack = math.max(0, player_data.attack - attack_value)
        output.add("Unequipped " .. item_key .. " (removed " .. attack_value .. " attack).\n")
        player_data.equipment.weapon = nil
    elseif slot == "armor" and defense_value then
        player_data.defense = math.max(0, player_data.defense - defense_value)
        output.add("Unequipped " .. item_key .. " (removed " .. defense_value .. " defense).\n")
        player_data.equipment.armor = nil
    else
        output.add("Cannot unequip " .. item_key .. " from " .. slot .. ".\n")
    end

    return player_data
end

return player