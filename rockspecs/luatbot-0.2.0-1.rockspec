package = 'luatbot'
version = '0.2.0-1'

source = {
	url = 'git+https://github.com/ghesy/luatbot.git',
}

description = {
	homepage = 'https://github.com/ghesy/luatbot',
	license = 'Unlicense',
}

dependencies = {
	'telegram-bot-lua',
	'penlight',
}

build = {
	type = 'builtin',
	modules = {
		['luatbot'] = 'src/main.lua',
		['luatbot.util'] = 'src/util.lua',
	}
}
