require('projects-nvim.types')
local utils = require('projects-nvim.utils')
local loader = require('projects-nvim.loader')

local M = {}

---@type ProjectsOpts
local default_options = {
	log_file = vim.fn.stdpath('log') .. '/projects.log',
	log_level = vim.log.levels.WARN,
	notify_level = vim.log.levels.INFO,
	template = {
		name = 'NO NAME',
		description = 'NO DESCRIPTION',
		author = 'NO AUTHOR',
		repo = 'NO REPO',
		license = 'NO LICENSE',
	},
	projects = {},
}

---@param opts ProjectsOpts
function M.setup(opts)
	vim.g.projects_nvim_config = vim.tbl_deep_extend('force', default_options, opts)

	utils.set_log_file(vim.g.projects_nvim_config.log_file)
	loader.add_projects(vim.g.projects_nvim_config.projects)
end

return M
