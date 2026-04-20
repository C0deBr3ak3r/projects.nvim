local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')

local projects = require('projects')

local M = {}

---@class ProjectsTelescopeEntry
---@field display string
---@field index	  integer
---@field ordinal string
---@field value   {info: ProjectsInfo, path: string}

---@param prompt_bufnr integer
function M.open_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	actions.close(prompt_bufnr)
	projects.open(entry.value.path)
end

function M.open_project_repo()
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	actions.close(prompt_bufnr)
	vim.ui.open(entry.value.info.repo)
end

---@param prompt_bufnr integer
function M.edit_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	projects.edit(entry.value.path)
end

---@param prompt_bufnr integer
function M.delete_project(prompt_bufnr)
	---@type ProjectsTelescopeEntry | nil
	local entry = actions_state.get_selected_entry()

	if entry == nil then
		return
	end

	actions.close(prompt_bufnr)
	projects.delete(entry.value.path)
end

---@param prompt_bufnr integer
function M.create_project(prompt_bufnr)
	vim.ui.input({
		prompt = 'Project path: ',
		completion = 'dir',
	}, function(input)
		if not input then
			return
		end

		actions.close(prompt_bufnr)
		projects.create()
	end)
end

return M
