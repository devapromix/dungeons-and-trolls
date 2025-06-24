json = require("libraries.json")
items = require("items")
enemies = require("enemies")
player_module = require("player")
combat = require("combat")
map = require("map")
game = require("game")
music = require("game.music")
skills = require("game.skills")
output = require("game.output")
utils = require("game.utils")
time = require("game.time")
const = require("game.const")
commands = require("commands")
command_buy = require("commands.buy")
command_recipes = require("commands.recipes")
command_move = require("commands.move")
command_items = require("commands.items")
command_cook = require("commands.cook")
command_rest = require("commands.rest")
command_look = require("commands.look")
command_fishing = require("commands.fishing")
command_volume = require("commands.volume")
command_light = require("commands.light")
command_train = require("commands.train")
command_skills = require("commands.skills")
command_kill = require("commands.kill")
command_examine = require("commands.examine")
command_gear = require("commands.gear")
command_enter = require("commands.enter")
command_leave = require("commands.leave")
command_trollcave = require("commands.trollcave")

function love.load()
	input = {
		text = ">",
		x = 5,
		y = love.graphics.getHeight() - 40,
		width = love.graphics.getWidth() - 10,
		height = 30,
		font = love.graphics.newFont(16),
		cursor_visible = true,
		cursor_timer = 0,
		cursor_blink_speed = 0.5,
		history = {},
		history_index = 0
	}
	
	items_data = items.load_items()
	locations_data = map.load_locations()
	enemies_data = enemies.load_enemies()
	skills_data = skills.load_skills()
	
	game.welcome()
end

function love.update(dt)
	input.cursor_timer = input.cursor_timer + dt
	if input.cursor_timer >= input.cursor_blink_speed then
		input.cursor_visible = not input.cursor_visible
		input.cursor_timer = 0
	end
end

function love.textinput(t)
	input.text = input.text .. t
	input.history_index = 0
end

function love.keypressed(key)
	if key == "backspace" and #input.text > 1 then
		input.text = input.text:sub(1, -2)
		input.history_index = 0
	end
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
		input.text = ">"
		input.history_index = 0
	end
	if key == "up" and input.history_index < #input.history then
		input.history_index = input.history_index + 1
		input.text = ">" .. input.history[input.history_index]
	elseif key == "down" then
		if input.history_index > 1 then
			input.history_index = input.history_index - 1
			input.text = ">" .. input.history[input.history_index]
		elseif input.history_index == 1 then
			input.history_index = 0
			input.text = ">"
		end
	end
end

function love.draw()
	love.graphics.setFont(output.font)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(output.text, output.x, output.y, output.width, "left")
	
	love.graphics.setFont(input.font)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(input.text, input.x, input.y)
	
	if input.cursor_visible then
		local text_width = input.font:getWidth(input.text)
		love.graphics.setColor(1, 1, 1)
		love.graphics.line(
			input.x + text_width,
			input.y,
			input.x + text_width,
			input.y + input.font:getHeight()
		)
	end
end

function love.resize(w, h)
	input.y = h - 40
	input.width = w - 10
	output.width = w - 10
	output.height = h - 50
end

function love.quit()
	if game.initialized then
		game.save_game()
	end
end