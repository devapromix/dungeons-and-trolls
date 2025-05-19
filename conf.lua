config = {
	inventory = {
		max_slots = 12,
	},
	
	debug = true,
	
	audio = {
		volume = 0.5,
	},
	
	game = {
		name = 'Dungeons and Trolls',
		version = '0.1.0',
	},
	
	map = {
        width = 127,
        height = 37,
	}
}

window = {
	width = 1920,
	height = 1080,
	fullscreen = true,
}

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