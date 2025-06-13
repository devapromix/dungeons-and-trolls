local skills = {}

function skills.exec(skills_module, output)
	output.add("Skills:\n")
	skills_module.draw()
end

return skills