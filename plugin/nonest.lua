local g, api, env, v = vim.g, vim.api, vim.env, vim.v
if g.loaded_nonest then
	return
end
g.loaded_nonest = true

env.EDITOR = vim.iter(v.argv):map(vim.fn.shellescape):join(' ')

---@type 'edit'|'split'|'vsplit'|'tabedit'|'pedit'|'edit!'|'split!'|'vsplit!'|'tabedit!'
g.nonest_edit_cmd = g.nonest_edit_cmd or 'edit'

if not env.NVIM then
	return
end

local _, chan = pcall(vim.fn.sockconnect, 'pipe', env.NVIM, { rpc = true })

if not chan or chan == 0 then
	vim.notify('Failed to connect to parent', vim.log.levels.ERROR)
	vim.cmd('quitall!')
end

api.nvim_create_autocmd('VimEnter', {
	callback = function()
		local bufname = api.nvim_buf_get_name(0)
		vim.rpcnotify(chan, 'nvim_command', ("%s %s"):format(g.nonest_edit_cmd, bufname))
		local parent_buf = vim.rpcrequest(chan, 'nvim_call_function', 'bufnr', { bufname })
		vim.rpcnotify(chan, 'nvim_create_autocmd', { 'WinClosed', 'BufDelete', 'BufWipeOut', 'TabClosed' }, {
			buffer = parent_buf,
			command = ([[ call rpcnotify(sockconnect('pipe', '%s', #{ rpc: v:true }), 'nvim_command', 'quitall!') ]])
				:format(v.servername),
			once = true
		})
	end,
})
