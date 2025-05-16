local time = {}

function time.tick_time(minutes)
    game_time.minute = game_time.minute + minutes
    while game_time.minute >= 60 do
        game_time.minute = game_time.minute - 60
        game_time.hour = game_time.hour + 1
    end
    while game_time.hour >= 24 do
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

return time