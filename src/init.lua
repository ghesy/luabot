local M = {}

local config, onmessage, dopage -- forward declarations

local states = {} -- states of open chats
function M.getdata()
	return states
end
function M.setdata(data)
	states = data
end

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
	while true do
		if type(t.periodic) == 'function' then
			t.periodic()
		end
		config.bot.get_updates(1, -1, 100, nil, nil)
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
	if start or msg.text == '/start' then
		s.chat_id = msg.chat.id
		s.page = 'start'
		s.vars = {}
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
	local p = config.pages[s.page]

	if p.print then
		M.sendmsg(s, p.print)
	end

	if p.input == nil or s.input_num > #p.input then
		local go
		go = type(p.go) == 'function' and p.go(s) or p.go
		go = type(go)   == 'function' and go(s)   or go
		if config.pages[go] == nil then
			sendmsg(s, config.text.page_nonexistent .. go)
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
				msg = (msg and msg .. '\n\n' or '')
					.. (v.separator and '======== ' or '/')
					.. v.name
			end
		end
		sendmsg(s, msg)
		return
	end

	if free and i.type == 'string' then
		s.input[i.var] = s.last_input
		s.input_num = s.input_num + 1
	elseif free and i.type == 'number' and tonumber(s.last_input) then
		s.input[i.var] = tonumber(s.last_input)
		s.input_num = s.input_num + 1
	elseif free and i.type == 'number' then
		sendmsg(s, config.text.invalid_answer_expected_number)
	elseif free then
		sendmsg(s, config.text.invalid_answer)
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
			sendmsg(s, config.text.invalid_answer_expected_choice)
		else
			s.input[i.var] = match.value
			s.input_num = s.input_num + 1
		end
	end

	s.last_input = nil
	dopage(s)
end

return M
