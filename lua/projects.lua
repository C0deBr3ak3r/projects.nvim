---@class ProjectsOpts
---@field projects_file?   string  Where projects.json is stored
---@field log_file?        string  Absolute path to log file
---@field log_level?       integer Minimum level to write into log, one of vim.log.levels
---@field notify_level?    integer Minimum level to call vim.notify
---@field licenses_folder? string  Where licenses are stored

---@class ProjectsInfo
---@field name         string Name of the project
---@field description  string Description of the project
---@field author       string Name of the author
---@field repo         string URL to repo
---@field license      string Name of the license in use
---@field path         string Absolute path to project

local M = {}

local join_abspath = function(...)
	return vim.fs.normalize(vim.fs.abspath(vim.fs.joinpath(...)))
end

---@type ProjectsOpts
local default_options = {
	log_file = vim.fs.joinpath(vim.fn.stdpath('log'), 'projects.log'),
	log_level = vim.log.levels.WARN,
	notify_level = vim.log.levels.INFO,
	licenses_folder = nil,
	projects_file = vim.fs.joinpath(vim.fn.stdpath('data'), 'projects.json'),
}
local opts = vim.tbl_extend('keep', vim.g.projects_nvim_config or {}, default_options)

local levels = {
	[0] = 'TRACE',
	[1] = 'DEBUG',
	[2] = 'INFO',
	[3] = 'WARN',
	[4] = 'ERROR',
	[5] = 'OFF',
}

---@type file*
local log_file, err = io.open(opts.log_file, 'a+')
if not log_file then
	error("Couldn't open log file", err)
end

---@param msg	string
---@param level	integer? One of the values of vim.log.levels
local log = function(msg, level)
	level = level or vim.log.levels.TRACE

	if level >= opts.notify_level then
		vim.notify(msg, level)
	end

	if level < opts.log_level then
		return
	end

	log_file:write(
		string.format('%s - [%s] %s\n', vim.fn.strftime('%d-%m %H:%M:%S'), levels[level], msg)
	)
	log_file:flush()
end

---@type ProjectsInfo[] | nil
projects = nil

---@type ProjectsInfo | nil
current_project = nil

local listdir = function(dir)
	local files = {}
	local dir_fd, err = vim.uv.fs_opendir(dir, nil, 69420)
	if not dir_fd then
		log(
			string.format('LISTDIR: Error while trying to open dir "%s" %s', dir, err),
			vim.log.levels.ERROR
		)
		return {}
	end
	local entries
	repeat
		entries = vim.uv.fs_readdir(dir_fd, nil)
		if not entries then
			break
		end
		for _, entry in pairs(entries or {}) do
			if entry.type == 'file' then
				table.insert(files, entry.name)
			end
		end
	until true
	local ok
	ok, err = vim.uv.fs_closedir(dir_fd, nil)
	if not ok then
		log(
			string.format('LISTDIR: Error while trying to close dir "%s" %s', dir, err),
			vim.log.levels.ERROR
		)
	end
	return files
end

local get_project_data = function(current_data, cb)
	local bufnr = vim.api.nvim_create_buf(true, true)
	if bufnr == 0 then
		log("GET_PROJECT_DATA: Failed to create buffer to get project's info", vim.log.levels.ERROR)
		return
	end
	vim.api.nvim_buf_set_name(bufnr, 'projects-nvim://get_data#' .. bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, {
		'Multiline arguments are disallowed',
		'',
		'Path: ' .. (current_data[1] or ''),
		'Name: ' .. (current_data[2] or ''),
		'Description: ' .. (current_data[3] or ''),
		'License: ' .. (current_data[4] or ''),
		'Author: ' .. (current_data[5] or ''),
		'Repo: ' .. (current_data[6] or ''),
	})
	vim.cmd.sbuffer(bufnr)
	vim.api.nvim_win_set_cursor(0, { 3, 6 })
	vim.bo[bufnr].modified = false
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].buftype = 'acwrite'
	vim.bo[bufnr].filetype = 'projects-nvim'
	write_aucmd_id = vim.api.nvim_create_autocmd('BufWriteCmd', {
		buffer = bufnr,
		callback = function(_)
			text = vim.api.nvim_buf_get_lines(bufnr, 2, 8, false)

			local path = string.match(text[1] or '', '^Path:%s*(.-)%s*$')
			if not path or #path == 0 then
				log('GET_PROJECT_DATA: Path is missing', vim.log.levels.WARN)
				return
			end

			local name = string.match(text[2] or '', '^Name:%s*(.-)%s*$')
			if not name or #name == 0 then
				log('GET_PROJECT_DATA: Name is missing', vim.log.levels.WARN)
				return
			end

			local description = string.match(text[3] or '', '^Description:%s*(.-)%s*$')
			if not description or #description == 0 then
				log('GET_PROJECT_DATA: Description is missing', vim.log.levels.WARN)
				return
			end

			local license = string.match(text[4] or '', '^License:%s*(.-)%s*$')
			if not license or #license == 0 then
				log('GET_PROJECT_DATA: License is missing', vim.log.levels.WARN)
				return
			end

			local author = string.match(text[5] or '', '^Author:%s*(.-)%s*$')
			if not author or #author == 0 then
				log('GET_PROJECT_DATA: Author is missing', vim.log.levels.WARN)
				return
			end

			local repo = string.match(text[6] or '', '^Repo:%s*(.-)%s*$')
			if not repo or #repo == 0 then
				log('GET_PROJECT_DATA: Repo is missing', vim.log.levels.WARN)
				return
			end

			vim.schedule_wrap(cb)({
				name = name,
				description = description,
				author = author,
				repo = repo,
				license = license,
				path = join_abspath(path),
			})

			vim.api.nvim_buf_delete(bufnr, { force = true })
		end,
	})

	vim.api.nvim_create_autocmd('BufDelete', {
		buffer = bufnr,
		once = true,
		callback = function(_)
			vim.api.nvim_del_autocmd(write_aucmd_id)
		end,
	})
end

function M.open(project_path)
	local path = join_abspath(project_path)
	if not projects then
		local projects_file = io.open(opts.projects_file, 'r')
		if not projects_file then
			log(
				string.format('OPEN: Could not open file "%s" %s', opts.projects_file, err),
				vim.log.levels.ERROR
			)
			return
		end
		projects = vim.json.decode(projects_file:read() or '[]')
		projects_file:close()
	end

	for _, project_info in pairs(projects) do
		if project_info.path == path then
			log(string.format('OPEN: Opening project at "%s"', path), vim.log.levels.TRACE)

			local load_script_path = join_abspath(path, '.nvim', 'load.lua')
			vim.cmd.cd(path)
			if vim.secure.read(load_script_path) then
				vim.cmd.source(load_script_path)
			end
			current_project = project_info
			return
		end
	end

	log(string.format('OPEN: Project at "%s" doesn\'t exist', path), vim.log.levels.ERROR)
end

function M.close()
	if not current_project then
		log("CLOSE: There's no project loaded", vim.log.levels.INFO)
		return
	end

	path = current_project.path
	log(string.format('CLOSE: Closing project at "%s"', path), vim.log.levels.TRACE)

	unload_script_path = join_abspath(path, '.nvim', 'unload.lua')
	if vim.secure.read(unload_script_path) then
		vim.cmd.source(unload_script_path)
	end
	current_project = nil
end

function M.edit(project_path)
	path = join_abspath(project_path)

	if not projects then
		local projects_file, err = io.open(opts.projects_file, 'r')
		if not projects_file then
			log(
				string.format('EDIT: Could not open file "%s" %s', opts.projects_file, err),
				vim.log.levels.ERROR
			)
			return
		end
		projects = vim.json.decode(projects_file:read() or '[]')
		projects_file:close()
	end

	for i, project_info in ipairs(projects) do
		if project_info.path == project_path then
			get_project_data({
				project_path,
				project_info.name,
				project_info.description,
				project_info.license,
				project_info.author,
				project_info.repo,
			}, function(info)
				projects[i] = info
				local projects_file, err = io.open(opts.projects_file, 'w')
				if not projects_file then
					log(
						string.format('EDIT: Could not open file "%s" "%s"', opts.projects_file, err),
						vim.log.levels.ERROR
					)
					return
				end
				log(string.format('EDIT: project at "%s" was edited', info.path), vim.log.levels.INFO)
				projects_file:write(vim.json.encode(projects))
				projects_file:close()
			end)
			return
		end
	end

	log(string.format('EDIT: Project at path "%s" does not exist', path), vim.log.levels.ERROR)
end

function M.delete(project_path)
	path = join_abspath(project_path)

	if not projects then
		local projects_file, err = io.open(opts.projects_file, 'r')
		if not projects_file then
			log(
				string.format('DELETE: Could not open file "%s" %s', opts.projects_file, err),
				vim.log.levels.ERROR
			)
			return
		end
		projects = vim.json.decode(projects_file:read() or '[]')
		projects_file:close()
	end

	for i, project_info in ipairs(projects) do
		if project_info.path == path then
			projects[i] = nil
		end
	end

	local projects_file, err = io.open(opts.projects_file, 'w')
	if not projects_file then
		log(
			string.format('DELETE: Could not open file "%s" %s', opts.projects_file, err),
			vim.log.levels.ERROR
		)
		return
	end
	projects_file:write(vim.json.encode(projects))
	projects_file:close()

	local projects_file, err = io.open(opts.projects_file, 'r')
	if not projects_file then
		log(
			string.format('DELETE: Could not open file "%s" %s', opts.projects_file, err),
			vim.log.levels.ERROR
		)
		return
	end
	projects = vim.json.decode(projects_file:read() or '[]')
	projects_file:close()
end

function M.create()
	if not projects then
		local projects_file, err = io.open(opts.projects_file, 'r+')
		if not projects_file then
			log(
				string.format('CREATE: Could not open file "%s" %s', opts.projects_file, err),
				vim.log.levels.ERROR
			)
			return
		end
		projects = vim.json.decode(projects_file:read() or '[]')
		projects_file:close()
	end

	get_project_data({}, function(info)
		for i, project_info in ipairs(projects) do
			if project_info.path == info.path then
				log(
					string.format('CREATE: project at "%s" already exist, editing it instead', info.path),
					vim.log.levels.INFO
				)
				projects[i] = info
				goto write
			end
		end
		table.insert(projects, info)
		log(string.format('CREATE: project at "%s" was added', info.path), vim.log.levels.INFO)

		::write::
		local projects_file, err = io.open(opts.projects_file, 'w')
		if not projects_file then
			log(
				string.format('EDIT: Could not open file "%s" "%s"', opts.projects_file, err),
				vim.log.levels.ERROR
			)
			return
		end
		projects_file:write(vim.json.encode(projects))
		projects_file:close()
	end)
end

function M.get_projects_info()
	if not projects then
		local projects_file, err = io.open(opts.projects_file, 'r')
		if not projects_file then
			log(
				string.format(
					'GET_PROJECTS_INFO: Could not open file "%s" %s',
					opts.projects_file,
					error
				),
				vim.log.levels.ERROR
			)
			return {}
		end
		projects = vim.json.decode(projects_file:read() or '[]')
		projects_file:close()
	end
	return projects
end

function M.load_new_config()
	vim.tbl_extend('keep', vim.g.projects_nvim_config or {}, default_options)
end

-- Taken from oil.nvim(https://www.github.com/stevearc/oil.nvim)
-- licensed under MIT
return M
