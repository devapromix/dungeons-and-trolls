local input = {
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
	history_index = 0,
	backspace_held = false,
	backspace_timer = 0,
	backspace_initial_delay = 0.6,
	backspace_repeat_delay = 0.05,
	backspace_first_press = true
}

function input.reset()
	input.text = ">"
	input.history_index = 0
end

function input.textinput(t)
	input.text = input.text .. t
	input.history_index = 0
end

function input.keypressed(key)
	if key == "backspace" then
		if #input.text > 1 then
			input.text = input.text:sub(1, -2)
			input.history_index = 0
		end
		input.backspace_held = true
		input.backspace_timer = 0
		input.backspace_first_press = true
	end
	if key == "escape" then
		input.reset()
	end
	if key == "up" and input.history_index < #input.history then
		input.history_index = input.history_index + 1
		input.text = ">" .. input.history[input.history_index]
	elseif key == "down" then
		if input.history_index > 1 then
			input.history_index = input.history_index - 1
			input.text = ">" .. input.history[input.history_index]
		elseif input.history_index == 1 then
			input.reset()
		end
	end
end

function input.keyreleased(key)
	if key == "backspace" then
		input.backspace_held = false
		input.backspace_timer = 0
		input.backspace_first_press = true
	end
end

function input.update(dt)
	input.cursor_timer = input.cursor_timer + dt
	if input.cursor_timer >= input.cursor_blink_speed then
		input.cursor_visible = not input.cursor_visible
		input.cursor_timer = 0
	end
	
	if input.backspace_held and #input.text > 1 then
		input.backspace_timer = input.backspace_timer + dt
		local delay = input.backspace_first_press and input.backspace_initial_delay or input.backspace_repeat_delay
		if input.backspace_timer >= delay then
			input.text = input.text:sub(1, -2)
			input.backspace_timer = 0
			input.backspace_first_press = false
			input.history_index = 0
		end
	end
end

function input.draw()
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

function input.resize(w, h)
	input.y = h - 40
	input.width = w - 10
end

return input