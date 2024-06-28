require('projects-nvim.types')
local utils = require('projects-nvim.utils')

local M = {}

---@type table<string, ProjectsConfig>
local db = {}

---@class ProjectsLoaded
---@field config	ProjectsConfig
---@field info		ProjectsInfo
---@field data?		any			Can be use to store anything you want to pass to on_unload

---@type ProjectsLoaded | nil
local current_project = nil

---@return ProjectsLoaded
function M.get_current_project()
	return vim.deepcopy(current_project or {}, true)
end

---@return table<string, ProjectsConfig>
function M.get_db()
	return vim.deepcopy(db, true)
end

---Get info about projects inside the database
---@param project_path? string
---@return table<string, ProjectsInfo>
function M.get_projects_info(project_path)
	local projects = db

	if project_path then
		projects = db[vim.fs.normalize(project_path)] or {}
	end

	local info = {}

	for path, _ in pairs(projects) do
		local file, erropen = io.open(path .. '/.nvim/project.json', 'r')

		if erropen or not file then
			utils.log('Error while opening project.json: ' .. erropen)
			goto continue
		end

		info[path] = vim.tbl_extend(
			'force',
			vim.g.projects_nvim_config.template,
			vim.json.decode(file:read('*a') or '{}', {
				luanil = {
					object = true,
					array = true,
				},
			})
		)

		file:close()

		::continue::
	end

	return info
end

--- Add projects to database
---@param projects ProjectsConfig[]
function M.add_projects(projects)
	for _, project in ipairs(projects) do
		local path = vim.fs.normalize(vim.fn.fnamemodify(project.path, ':p'))
		if not db[path] then
			db[path] = vim.tbl_extend('force', {
				on_load = actions.default_loader,
				on_unload = actions.default_unloader,
			}, project, { path = path })
		end
	end
end

---@param project_path string
function M.load_project(project_path)
		return
	end

	if M.current_project == vim.empty_dict and M.current_project.project.config.path == project then
		utils.log('Project at path `' .. project .. '` is already loaded', vim.log.levels.INFO)
		utils.notify('Project is already loaded', vim.log.levels.INFO)
		return
	end

	utils.log('TODO: load project at path: ' .. project, vim.log.levels.WARN)

	vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectLoadPost', data = project })
end

---@param project_path string
function M.unload_project(project_path)
		return
	end

	if type(M.loaded[project].project.config.on_unload) == 'function' then
		utils.log('Running `on_unload` function for project at path: ' .. project)
		M.loaded[project].project.config.on_unload(M.loaded.buffers)
	end
	M.loaded[project] = nil

	utils.log('TODO: unload project at path: ' .. project, vim.log.levels.WARN)

	vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectUnloadPost', data = project })
end

return M
