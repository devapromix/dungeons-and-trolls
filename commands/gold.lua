local gold = {}

function gold.exec(command_parts, player, player_module)
	if not config.debug then
		output.add("Command only available in debug mode.\n")
		return player
	end
	if not player_module.check_player_alive("add gold", player) then
		return player
	end
	if #command_parts < 2 then
		output.add("Please specify an amount of gold (e.g., 'gold 100').\n")
		return player
	end
	local amount = tonumber(command_parts[2])
	if not amount or amount < 1 or amount > 10000 then
		output.add("Amount must be a number between 1 and 10000.\n")
		return player
	end
	player.gold = player.gold + math.floor(amount)
	output.add("Added " .. math.floor(amount) .. " gold. Total gold: " .. player.gold .. ".\n")
	return player
end

return gold