require('projects.types')
local utils = require('projects.utils')
local actions = require('projects.actions')

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
		projects = { [project_path] = db[vim.fs.normalize(project_path)] or {} }
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
	local project = vim.fs.normalize(project_path)

	if current_project then
		if vim.fs.normalize(current_project.config.path) == project then
			utils.log('Project at path `' .. project .. '` is already loaded', vim.log.levels.INFO)
			return
		end
		utils.log('current_project is not empty, unloading it', vim.log.levels.INFO)

		M.unload_project(project)
	end

	utils.log('Loading project at path: ' .. project, vim.log.levels.DEBUG)

	if type(db[project].on_load) == 'function' then
		local config = db[project]
		local info = M.get_projects_info(project)[project]
		local ok, data = db[project].on_load(config, info)

		if not ok then
			utils.log('Error on `on_load` function', vim.log.levels.ERROR)
		end

		current_project = {
			config = config,
			info = info,
			data = data,
		}
		return
	end

	utils.log('TODO: load project at path: ' .. project, vim.log.levels.WARN)

	vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectLoadPost', data = project })
end

---@param project_path string
function M.unload_project(project_path)
	if not current_project then
		return
	end

	local project = vim.fs.normalize(project_path)

	if current_project.config.path ~= project then
		utils.log('Project at path ' .. project .. ' is not loaded', vim.log.levels.ERROR)
		return
	end

	utils.log('Unloading project at path: ' .. project, vim.log.levels.DEBUG)

	if
		type(current_project.config.on_unload) == 'function'
		and not current_project.config.on_unload(current_project)
	then
		utils.log('Error on `on_load` function', vim.log.levels.ERROR)
		return
	end
	current_project = nil

	utils.log('TODO: unload project at path: ' .. project, vim.log.levels.WARN)

	vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectUnloadPost', data = project })
end

return M
