local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')

local projects_loader = require('projects-nvim.loader')
local projects_utils = require('projects-nvim.utils')

local M = {}

---@param prompt_bufnr integer
function M.open_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	projects_loader.load_project(entry.value.path)
	actions.close(prompt_bufnr)
end

function M.open_project_repo()
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	vim.ui.open(entry.value.info.repo)
	projects_utils.log(string.format('Opening `%s`', entry.value.info.repo), vim.log.levels.INFO)
end

---@param prompt_bufnr integer
function M.edit_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	actions.close(prompt_bufnr)
	vim.cmd.edit(vim.fs.joinpath(entry.value.path, '.nvim/project.json'))
end

---@param prompt_bufnr integer
function M.delete_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	local choice = vim.fn.confirm(
		string.format(
			'Delete directory `%s`',
			vim.fn.fnamemodify(vim.fs.joinpath(entry.value.path, '.nvim/'), ':~')
		),
		'&Yes\n&No',
		2
	)
	if choice == 1 then
		vim.fn.delete(vim.fs.joinpath(entry.value.path, '.nvim'), 'rf')
		projects_utils.log('Deleting ' .. vim.fs.joinpath(entry.value.path, '.nvim'))
		actions.close(prompt_bufnr)
		require('telescope').extensions.projects.projects()
	end
end

return M
