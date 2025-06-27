local fire = {}

fire_data = {
	overworld = { x = nil, y = nil, active = false },
	underworld = { x = nil, y = nil, active = false }
}

function fire.make_fire(player, world)
	if not player_module.check_player_alive("make a fire", player) then
		return
	end
	local item_key = utils.find_item_key(player.inventory, "Firewood", true)
	if not item_key then
		output.add("You don't have firewood in your inventory.\n")
		return
	end
	if fire_data[world].active and fire_data[world].x == player.x and fire_data[world].y == player.y then
		output.add(const.FIRE_IS_BURNING)
		return
	end
	player.inventory[item_key] = player.inventory[item_key] - 1
	if player.inventory[item_key] <= 0 then
		player.inventory[item_key] = nil
	end
	fire_data[world].x = player.x
	fire_data[world].y = player.y
	fire_data[world].active = true
	output.add("You make a fire.\n")
	time.tick_time(15)
end

function fire.check_fire(world, x, y)
	return fire_data[world].active and fire_data[world].x == x and fire_data[world].y == y
end

function fire.extinguish_fire(world, x, y)
	if fire_data[world].active and (fire_data[world].x ~= x or fire_data[world].y ~= y) then
		fire_data[world].active = false
		fire_data[world].x = nil
		fire_data[world].y = nil
	end
end

return fire