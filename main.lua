require "import"

function love.load()
	items_data = items.load_items()
	locations_data = map.load_locations()
	enemies_data = enemies.load_enemies()
	skills_data = skills.load_skills()
	
	game.welcome()
end

function love.update(dt)
	input.update(dt)
end

function love.textinput(t)
	input.textinput(t)
end

function love.keypressed(key)
	input.keypressed(key)
	if key == "return" and #input.text > 1 then
		output.clear()
		local command = input.text:sub(2)
		local command_parts = {}
		for part in command:gmatch("%S+") do
			table.insert(command_parts, part)
		end
		commands.handle_command(command_parts, player, map_data, items_data, enemies_data, skills_data, config, game_time, input, output, time, player_module, items, enemies, map, skills, json)
		if utils.table_contains(input.history, command) then
			for i, hist_command in ipairs(input.history) do
				if hist_command == command then
					table.remove(input.history, i)
					break
				end
			end
		end
		local skip = { yes = true, y = true, no = true, n = true }
		if not skip[string.lower(command)] then
			table.insert(input.history, 1, command)
		end
		input.reset()
	end
end

function love.keyreleased(key)
	input.keyreleased(key)
end

function love.draw()
	love.graphics.setFont(output.font)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(output.text, output.x, output.y, output.width, "left")
	
	input.draw()
end

function love.resize(w, h)
	input.resize(w, h)
	output.width = w - 10
	output.height = h - 50
end

function love.quit()
	if game.initialized then
		game.save_game()
	end
end