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

function utils.output_text_file(file_path)
    if love.filesystem.getInfo(file_path) then
        local content = love.filesystem.read(file_path)
        if content then
            output.add(content)
        else
            output.add("Failed to read file: ('" .. file_path .. "').\n")
        end
    else
        output.add("File '" .. file_path .. "' not found.\n")
    end
end

function utils.clamp(value, min, max)
  return value < min and min or (value > max and max or value)
end

function utils.get_item_tag_value(item_data, tag_prefix)
	for _, tag in ipairs(item_data.tags) do
		if tag:match("^" .. tag_prefix .. "=") then
			return tonumber(tag:match("^" .. tag_prefix .. "=(%S+)"))
		end
	end
	return nil
end

return utils