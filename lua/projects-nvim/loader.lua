require('projects-nvim.types')
local utils = require('projects-nvim.utils')

local M = {}

---@alias path string Absolute path to project root directory
---@type table<path, ProjectSpec>
M.db = {}

---@class LoadedProjects
---@field project ProjectSpec
---@field buffers integer[] Buffer numbers associated with project
M.current_project = {}

---@param info ProjectInfo
local function normalize_db(info)
	local result = {
		name = info.name or 'COPILOT+ YOUR MAMMA',
		description = info.description or 'DEVELOPERS DEVELOPERS DEVELOPERS',
		author = info.author or 'The Illuminati',
		repo = info.repo or 'MegaHard',
		license = info.name or 'proprietary bullshit',
	}
	return result
end

--- Add projects to database
---@param projects ProjectConfig[]
function M.add_projects(projects)
	for _, project in ipairs(projects) do
		local path = vim.fs.normalize(vim.fn.fnamemodify(project.path, ':p'))
		if not M.db[path] then
			utils.log('Adding project at path `' .. path .. '` to database')
			local file, erropen = io.open(path .. '/.nvim/project.json', 'r')

			if erropen or not file then
				utils.log('Error while opening project.json: ' .. erropen)
				return
			end

			M.db[path] = {
				config = project,
				info = normalize_db(vim.json.decode(file:read('*a') or '{}', {
					luanil = {
						object = true,
						array = true,
					},
				})),
			}

			file:close()
		end
	end
end

---@param project path
function M.load_project(project)
	if not project then
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

---@param project path
function M.unload_project(project)
	if not project or not M.current_project[project] then
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
