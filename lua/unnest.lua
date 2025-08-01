local M = {}

local api = vim.api

M.winlayout_to_cmds = function(winlayout)
	local commands = {} ---@type string[]

	---@param winid integer
	---@param cmd string
	---@param mod? string
	local function get_cmds_for_win(winid, cmd, mod)
		table.insert(
			commands,
			('%s %s %s'):format(
				mod or '',
				cmd,
				vim.fn.fnameescape(api.nvim_buf_get_name(api.nvim_win_get_buf(winid)))))
		if vim.wo[winid].diff then
			table.insert(commands, "diffthis")
		end
	end

	---@param layout vim.fn.winlayout.ret
	---@param is_first boolean
	local function process_winlayout(layout, is_first)
		local type = layout[1]

		---@param data vim.fn.winlayout.ret[]
		---@param split_type "vsplit"|"split"
		---@param first boolean
		local function process_splits(data, split_type, first)
			process_winlayout(data[1], first)

			for i = 2, #data do
				local winid = nil
				if data[i][1] == 'leaf' then
					winid = data[i][2]
				end

				local position = i == #data and "botright" or "belowright"

				get_cmds_for_win(winid --[[@as integer]], split_type, position)

				if data[i][1] ~= 'leaf' then
					process_winlayout(data[i], false)
				end
			end
		end

		if type == 'leaf' then
			local winid = layout[2]
			if is_first then
				get_cmds_for_win(winid --[[@as integer]], "edit")
			end
		elseif type == 'col' then
			process_splits(layout[2] --[[@as vim.fn.winlayout.ret[] ]], "split", is_first)
		elseif type == 'row' then
			process_splits(layout[2] --[[@as vim.fn.winlayout.ret[] ]], "vsplit", is_first)
		end
	end

	process_winlayout(winlayout, true)
	return commands
end

return M
