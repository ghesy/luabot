local M = {}

function M.choices(prompt, choices, extras)
	local t = {
		input = {
			{
				var = 'choice',
				prompt = prompt,
				type = choices
			}
		},
		go = function(s)
			return s.input.choice
		end
	}
	for k, v in pairs(extras or {}) do
		t[k] = v
	end
	return t
end

function M.text(t)
	return setmetatable(t, {
		__index = function(_, key)
			error(string.format("text object '%s' isn't defined", key))
		end
	})
end

return M
