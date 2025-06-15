local time = {}

function time.tick_time(minutes)
	game_time.playtime = (game_time.playtime or 0) + minutes
	game_time.minute = game_time.minute + minutes
	while game_time.minute >= 60 do
		game_time.minute = game_time.minute - 60
		game_time.hour = game_time.hour + 1
	end
	while game_time.hour >= 24 do
		music.play_random()
		game_time.hour = game_time.hour - 24
		game_time.day = game_time.day + 1
	end
	while game_time.day > 30 do
		game_time.day = game_time.day - 30
		game_time.month = game_time.month + 1
	end
	while game_time.month > 12 do
		game_time.month = game_time.month - 12
		game_time.year = game_time.year + 1
	end
end

function time.format_playtime(playtime)
	local months = math.floor(playtime / (60 * 24 * 30))
	local days = math.floor((playtime % (60 * 24 * 30)) / (60 * 24))
	local hours = math.floor((playtime % (60 * 24)) / 60)
	local minutes = playtime % 60
	local time_parts = {}
	if months > 0 then
		local month_str = months == 1 and "month" or "months"
		table.insert(time_parts, months .. " " .. month_str)
	end
	if days > 0 then
		local day_str = days == 1 and "day" or "days"
		table.insert(time_parts, days .. " " .. day_str)
	end
	if hours > 0 then
		local hour_str = hours == 1 and "hour" or "hours"
		table.insert(time_parts, hours .. " " .. hour_str)
	end
	if minutes > 0 or #time_parts == 0 then
		local minute_str = minutes == 1 and "minute" or "minutes"
		table.insert(time_parts, minutes .. " " .. minute_str)
	end
	return table.concat(time_parts, ", ")
end

return time