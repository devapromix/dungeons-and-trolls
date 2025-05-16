config = {
	font = {
		width = 25,
		height = 40,
	},
	
	text = {
		width = 55,
	},
	
	panel = {
		left = 1350,
	},
	
	inventory = {
		max_slots = 12,
	},
	
	debug = true,
	
	audio = {
		volume = 0.5,
	},
	
	game = {
		name = 'LotBD',
		version = '0.1',
	},
	
	gui = {
		scale = 4,
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
	t.identity = 'LegendOfTheBlackDragon'..config.game.version
	t.window.title = config.game.name
	t.window.width = window.width
	t.window.height = window.height
	--t.window.icon = "assets/icons/game.png"
end