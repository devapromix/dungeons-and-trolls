local enter = {}

local function print_available_buildings()
    output.add("Available buildings:\n")
	local interiors_data = shop.load_interiors()
    for _, interior in ipairs(interiors_data.interiors or {}) do
		output.add(" * '" .. interior.id .. "' - " .. interior.hint .. "\n")
	end
end

function enter.exec(command_parts, player, map_data)
    if not player_module.check_player_alive("enter a building", player) then
        return player
    end
    if player.state ~= "overworld" then
        output.add("You are already inside a building.\n")
        return player
    end
    if map_data[player.world].tiles[player.y][player.x] ~= "v" then
        output.add("You must be in a village to enter a building.\n")
        return player
    end
    if #command_parts < 2 then
        output.add("Please specify a building to enter:\n")
		print_available_buildings()
        return player
    end

    local building_parts = {}
    for i = 2, #command_parts do
        table.insert(building_parts, command_parts[i]:lower())
    end
    local str_building = table.concat(building_parts, " ")
    
    local aliases = {
        ["shop"] = "weapon shop",
        ["weapon"] = "weapon shop",
        ["armor"] = "armor shop",
        ["magic"] = "magic shop",
        ["tavern"] = "tavern",
        ["smith"] = "forge"
    }
    
    local building = aliases[str_building] or str_building
    
    local interiors_data = shop.load_interiors()
    for _, interior in ipairs(interiors_data.interiors or {}) do
        if interior.id == building then
            player.state = building
            shop.display_interior(building, player)
            return player
        end
    end
    
    output.add("Unknown building: '" .. building .. "'.\n")
	print_available_buildings()
    return player
end

return enter