local enemies = {}

function enemies.load_enemies()
    local enemies_file = "assets/data/enemies.json"
    if love.filesystem.getInfo(enemies_file) then
        local content = love.filesystem.read(enemies_file)
        if content then
            return json.decode(content)
        else
            output.add("Failed to read enemies file.\n")
            return { enemies = {} }
        end
    else
        output.add("Enemies file not found.\n")
        return { enemies = {} }
    end
end

return enemies