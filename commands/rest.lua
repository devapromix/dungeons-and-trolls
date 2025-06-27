local rest = {}

function rest.exec(player, map_data, game_time, time)
	if not player_module.check_player_alive("rest", player) then
		return player
	end
	if player.state ~= "overworld" then
		output.add("You cannot rest inside a building.\n")
		return player
	end
	if player.health >= player.max_health and player.mana >= player.max_mana and player.fatigue <= 0 then
		output.add("You don't need to rest.\n")
		return player
	end
	local hours_to_full = math.max(
		math.ceil((player.max_health - player.health) / 10),
		math.ceil((player.max_mana - player.mana) / 10),
		math.ceil(player.fatigue / 10)
	)
	local hours_to_morning = game_time.hour >= 18 and (24 - game_time.hour + 6) or game_time.hour < 6 and (6 - game_time.hour) or 0
	local rest_hours = hours_to_morning > 0 and utils.clamp(hours_to_full, 0, hours_to_morning) or hours_to_full
	local rest_multiplier = fire.check_fire(player.world, player.x, player.y) and 2 or 1
	output.add("You rest for " .. rest_hours .. " hour(s)...\n")
	player.health = player.health + rest_hours * 10 * rest_multiplier
	player.mana = player.mana + rest_hours * 10 * rest_multiplier
	player.fatigue = player.fatigue - rest_hours * 10 * rest_multiplier
	player.hunger = player.hunger + rest_hours * 0.5
	player.thirst = player.thirst + rest_hours * 2.5
	player = player_module.clamp_player_stats(player)
	time.tick_time(rest_hours * 60)
	output.add("Your health, mana, and fatigue have been restored.\n")
	if rest_multiplier > 1 then
		output.add("Resting by the fire makes you recover twice as fast!\n")
	end
	if rest_hours > 0 then
		output.add("You feel hungrier and thirstier.\n")
	end
	local status_message = player_module.check_player_status(player)
	if status_message ~= "" then
		output.add(status_message)
	end
	return player
end

return rest