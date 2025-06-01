local utils = {}

function utils.load_json_file(file_path, error_message)
    if love.filesystem.getInfo(file_path) then
        local content = love.filesystem.read(file_path)
        if content then
            return json.decode(content)
        else
            output.add("Failed to read " .. error_message .. ".\n")
            return {}
        end
    else
        output.add(error_message .. " not found.\n")
        return {}
    end
end

return utils