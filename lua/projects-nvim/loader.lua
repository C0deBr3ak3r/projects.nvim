require('projects-nvim.types')
local utils = require('projects-nvim.utils')

local M = {}

---@type table<string, ProjectConfig>
M.db = {}

---@class ProjectLoaded
---@field config	ProjectConfig
---@field info		ProjectInfo
---@field buffers	integer[] Buffer numbers associated with project
M.current_project = {}

---Get info about projects inside the database
---@return table<path, ProjectInfo>
function M.get_projects_info()
	local info = {}

	for path, _ in pairs(M.db) do
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
---@param projects ProjectConfig[]
function M.add_projects(projects)
	for _, project in ipairs(projects) do
		local path = vim.fn.fnamemodify(project.path, ':p')
		if not M.db[path] then
			M.db[path] = project
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
	utils.notify('TODO: load project at path: ' .. project, vim.log.levels.WARN)

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
	utils.notify('TODO: unload project at path: ' .. project, vim.log.levels.WARN)

	utils.log('Unloading project at path: ' .. project)

	vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectUnloadPost', data = project })
end

return M
