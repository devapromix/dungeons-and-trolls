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

function utils.table_contains(table, element)
	for _, value in ipairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function utils.table_count(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

function utils.find_item_key(item_table, item_name, allow_partial_match)
	if not item_table or not item_name or item_name == "" then return nil end
	local lower_name = string.lower(item_name)
	local matches = {}
	for key in pairs(item_table) do
		if string.lower(key) == lower_name then
			return key
		elseif allow_partial_match and string.find(string.lower(key), lower_name, 1, true) then
			table.insert(matches, key)
		end
	end
	if #matches > 0 then
		return matches[1]
	end
	return nil
end

function utils.parse_item_command(command_parts, start_index, output)
	local quantity = 1
	local item_name
	if tonumber(command_parts[start_index]) then
		quantity = math.floor(tonumber(command_parts[start_index]))
		if #command_parts >= start_index + 1 then
			item_name = table.concat(command_parts, " ", start_index + 1)
		else
			output.add("Please specify an item name after the quantity.\n")
			return nil, nil
		end
	else
		item_name = table.concat(command_parts, " ", start_index)
	end
	if item_name and #item_name < 3 then
		output.add("Item name '" .. item_name .. "' must be at least 3 characters long.\n")
		return nil, nil
	end
	if quantity <= 0 then
		output.add("Invalid item quantity specified.\n")
		return nil, nil
	end
	return quantity, item_name
end

return utils