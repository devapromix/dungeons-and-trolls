local output = {
    text = "",
    x = 5,
    y = 5,
    width = love.graphics.getWidth() - 10,
    height = love.graphics.getHeight() - 50,
    font = love.graphics.newFont("assets/fonts/UbuntuMono-R.ttf", 20)
}

if output.font == nil then
    output.font = love.graphics.newFont(16)
end

function output.clear()
    output.text = ""
end

function output.add(str, new_line)
    if new_line == nil then new_line = true end
    if new_line then
        output.text = output.text .. str
    else
        output.text = output.text .. str
    end
end

return output