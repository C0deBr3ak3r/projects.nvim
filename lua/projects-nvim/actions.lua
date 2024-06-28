local M = {}
local utils = require('projects-nvim.utils')
---Default project loader
---@param config ProjectsConfig
---@param info ProjectsInfo
---@return boolean, any
function M.default_loader(config, info)
	local cur_dir = vim.fn.getcwd()

	local data = {
		cur_dir = cur_dir,
		session_opts = vim.api.nvim_get_option_value('sessionoptions', {
			scope = 'local',
		}),
		session_file_path = string.format(
			'/tmp/project-sessions/%s-%s.vim',
			vim.fn.fnamemodify(cur_dir, ':t'),
			vim.fn.strftime('%H-%M-%S')
		),
	}
	vim.api.nvim_set_option_value('sessionoptions', 'globals,options', {
		scope = 'local',
	})

	vim.uv.fs_mkdir('/tmp/project-sessions/', 0x1C0)
	vim.cmd('mksession! ' .. data.session_file_path)
	if not vim.uv.fs_stat(data.session_file_path) then
		utils.log('Fail to save session, cannot load project', vim.log.levels.ERROR)
		return false
	end

	vim.cmd.cd(vim.fs.normalize(config.path))

	if config.files then
		for _, file in pairs(config.files) do
			vim.secure.read(vim.fs.joinpath(config.path, '.nvim', file))
		end
	end

	return true, data
end

---Default project unloader
---@param project ProjectsLoaded
---@return boolean
function M.default_unloader(project)
	if
		not project.data
		or not project.data.cur_dir
		or not project.data.session_opts
		or not project.data.session_file_path
	then
		utils.log('Incompatible data field, cannot unload project', vim.log.levels.ERROR)
		return false
	end

	if not vim.uv.fs_stat(project.data.session_file_path) then
		utils.log('Sessions file does not exist, cannot unload project', vim.log.levels.ERROR)
		return false
	end

	vim.cmd('augroup DefaultProjectsGroup | autocmd! | augroup END')

	vim.cmd.cd(project.data.cur_dir)
	vim.cmd.so(project.data.session_file_path)
	return true
end

return M
