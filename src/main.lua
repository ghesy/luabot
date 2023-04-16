local M = {}
local pl = require('pl.import_into')()

-- forward declarations
local onmessage, dopage, savedata, loaddata, isfile
local config = {}

-- states of open chats
local states = {}
local states_old = {}

function M.sendmsg(s, text)
	config.bot.send_message(s.chat_id, text)
end

function M.sendmd(s, text)
	config.bot.send_message(s.chat_id, text, 'Markdown')
end

function M.run(t)
	config.bot = require('telegram-bot-lua.core').configure(t.token)
	config.bot.on_message = onmessage
	config.text = t.text
	config.pages = t.pages
	local offset = 0
	local initialized = false
	if t.datafile then
		loaddata(t.datafile)
	end
	while true do
		if t.datafile then
			savedata(t.datafile)
		end
		if type(t.periodic) == 'function' then
			t.periodic()
		end
		if not initialized then
			config.bot.get_updates(1, -1, 100, nil, nil)
		end
		local updates = config.bot.get_updates(1, offset, 100, nil, nil)
		if updates and type(updates) == 'table' and updates.result then
			for _, u in pairs(updates.result) do
				if initialized then
					config.bot.process_update(u)
				end
				offset = u.update_id + 1
			end
		end
		initialized = true
	end
end

function onmessage(msg)
	local start = false
	if states[msg.chat.id] == nil then
		start = true
		states[msg.chat.id] = {}
	end
	local s = states[msg.chat.id]
	s.last_msg_time = os.time(os.date('!*t'))
	if start or msg.text == '/start' then
		s.chat_id = msg.chat.id
		s.page = 'start'
	elseif msg.text:lower() == '/cancel' and s.main_page then
		s.page = s.main_page
		s.input = {}
		s.input_num = 1
		s.last_input = nil
	elseif msg.text ~= nil then
		s.last_input = msg.text
	else
		return
	end
	dopage(s)
end

function dopage(s)
	if s.page == 'start' then
		s.main_page = nil
		s.vars  = {} -- vars; cleared on start and main_page
		s.pvars = {} -- persistent vars; cleared only on start
		s.input = {}
		s.input_num = 1
		s.last_input = nil
	elseif s.page == s.main_page then
		s.vars = {}
	end

	local p = config.pages[s.page]

	if p.print then
		M.sendmsg(s, p.print)
	end

	if p.input == nil or s.input_num > #p.input then
		local go
		go = type(p.go) == 'function' and p.go(s) or p.go
		go = type(go)   == 'function' and go(s)   or go
		if type(go) == 'function' then
			s.page = 'start' -- this is an error case, so go back to start
		elseif config.pages[go] == nil then
			M.sendmsg(s, config.text.page_nonexistent .. go)
		else
			s.page = go
		end
		s.input = {}
		s.input_num = 1
		dopage(s)
		return
	end

	local i = p.input[s.input_num]

	local free = type(i.type) == 'string'
	local choices = not free

	if s.last_input == nil then
		local msg = i.prompt
		if choices then
			for _, v in ipairs(i.type) do
				msg = (msg and msg .. '\n' or '')
					.. (v.separator and '===== ' or '/')
					.. v.name
					.. (v.separator and ' =====' or '')
			end
		end
		M.sendmsg(s, msg)
		return
	end

	if free and i.type == 'string' then
		s.input[i.var] = s.last_input
		s.input_num = s.input_num + 1
	elseif free and i.type == 'number' and tonumber(s.last_input) then
		s.input[i.var] = tonumber(s.last_input)
		s.input_num = s.input_num + 1
	elseif free and i.type == 'number' then
		M.sendmsg(s, config.text.invalid_answer_expected_number)
	elseif free then
		M.sendmsg(s, config.text.invalid_answer)
	elseif choices then
		local match = nil
		for _, v in ipairs(i.type) do
			if v.name and v.value and v.separator == nil then
				if s.last_input == '/' .. v.name then
					match = v
					break
				elseif v.default == true then
					match = v
				end
			end
		end
		if match == nil then
			M.sendmsg(s, config.text.invalid_answer_expected_choice)
		else
			s.input[i.var] = match.value
			s.input_num = s.input_num + 1
		end
	end

	s.last_input = nil
	dopage(s)
end

function savedata(path)
	local time = os.time(os.date('!*t'))
	local threshold = 60 * 60 * 24 * 30
	for id in pairs(states) do
		if time - states[id].last_msg_time > threshold then
			states[id] = nil
		end
	end
	if not pl.tablex.deepcompare(states, states_old) then
		pl.pretty.dump(states, path)
		states_old = pl.tablex.deepcopy(states)
	end
end

function loaddata(path)
	if pl.path.isfile(path) then
		states = assert(pl.pretty.read(pl.file.read(path)))
	end
end

return M
