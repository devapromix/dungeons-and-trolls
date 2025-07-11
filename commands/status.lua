local status = {}

function status.exec(command_parts, player, player_module)
	if not player_module.check_player_alive("check status", player) then
		return player
	end
	local lines = {
		player.name .. " (" .. player.gender .. "):\n",
		"Level: " .. player.level .. "\n",
		"Experience: " .. player.experience .. "/" .. player_module.experience_to_next_level(player.level) .. "\n",
		"Level points: " .. player.levelpoints .. "\n\n",
		"Strength: " .. player.strength .. "\n",
		"Dexterity: " .. player.dexterity .. "\n",
		"Vitality: " .. player.vitality .. "\n",
		"Intelligence: " .. player.intelligence .. "\n\n",
		"Health: " .. player.health .. "/" .. player.max_health .. "\n",
		"Mana: " .. player.mana .. "/" .. player.max_mana .. "\n",
		"Hunger: " .. player.hunger .. "\n",
		"Thirst: " .. player.thirst .. "\n",
		"Fatigue: " .. player.fatigue .. "\n",
		"Attack: " .. player.attack .. "\n",
		"Defense: " .. player.defense .. "\n\n",
		"Position: " .. player.x .. ", " .. player.y .. " (" .. player.world .. ")\n\n",
	}
	if not player.alive then
		table.insert(lines, "\nYou are DEAD.\n\n")
		table.insert(lines, const.aliveSTART_NEW)
	end
	output.add(table.concat(lines))
	return player
end

return status