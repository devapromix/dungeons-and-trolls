local json = require("libraries.json")
local output = require("output")
local items = require("items")

local skills = {}

function skills.load_skills()
    local skills_file = "assets/data/skills.json"
    if love.filesystem.getInfo(skills_file) then
        local content = love.filesystem.read(skills_file)
        if content then
            return json.decode(content)
        else
            output.add("Failed to read skills file.\n")
            return {}
        end
    else
        output.add("Skills file not found.\n")
        return {}
    end
end

function skills.get_skill_data(skills_data, skill_name)
    if not skills_data or not skills_data.skills or not skill_name then return nil end
    for _, skill in ipairs(skills_data.skills) do
        if skill.name == skill_name then
            return skill
        end
    end
    return nil
end

function skills.apply_skill_effects(player, skills_data, damage)
    local critical_multiplier = 1
    if player.equipment and player.equipment.weapon then
        local item_data = items.get_item_data(items.load_items(), player.equipment.weapon)
        if item_data then
            for _, tag in ipairs(item_data.tags) do
                if tag:match("^weapon=") then
                    local swords_skill = player.skills and player.skills.Swords or 0
                    local skill_data = skills.get_skill_data(skills_data, "Swords")
                    if skill_data and math.random() < (swords_skill / 100) then
                        critical_multiplier = 2
                        output.add("Critical hit! Damage doubled.\n")
                    end
                end
            end
        end
    end
    return damage * critical_multiplier
end

function skills.upgrade_skill(player, skills_data, skill_name)
    if not player.skills or not player.skills[skill_name] then return end
    local skill_data = skills.get_skill_data(skills_data, skill_name)
    if not skill_data then return end
    if player.skills[skill_name] >= skill_data.max_level then
        output.add(skill_name .. " skill is already at maximum level (" .. skill_data.max_level .. ").\n")
        return
    end
    player.skills[skill_name] = player.skills[skill_name] + 1
    output.add(skill_name .. " skill increased to " .. player.skills[skill_name] .. ".\n")
end

return skills