local skills = {}

function skills.exec(skills_module)
	output.add("Skills:\n")
	skills_module.draw()
end

return skills