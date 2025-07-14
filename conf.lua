config = {
	inventory = {
		max_slots = 18,
	},
	
	debug = false,
	
	audio = {
		volume = 0.3,
	},
	
	game = {
		name = 'Dungeons and Trolls',
		version = '0.6.0',
	},
	
	map = {
        width = 127,
        height = 37,
	},
	
	skill = {
		max = 40,
	}
}

window = {
	width = 1920,
	height = 1080,
	fullscreen = true,
}

for _, v in ipairs(arg) do
    if v == "-d" then
        config.debug = true
        break
    end
end

function love.conf (t)
	t.console = config.debug
	t.window.fullscreen = window.fullscreen
	t.window.msaa = 0
	t.window.fsaa = 0
	t.window.display = 1
	t.window.resizable = false
	t.window.vsync = false
	t.identity = "Dungeons_and_Trolls"
	t.window.title = config.game.name
	t.window.width = window.width
	t.window.height = window.height
	t.window.icon = "assets/icons/game.png"
end