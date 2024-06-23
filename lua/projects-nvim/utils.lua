local M = {}

---@param msg string
---@param log_level? integer One of vim.log.levels
---@param opts? table
function M.notify(msg, log_level, opts)
	vim.schedule(function()
		vim.notify(msg, log_level, opts)
	end)
end

vim.g.projects_nvim_config = vim.g.projects_nvim_config or {}

local levels = {
	[0] = 'TRACE',
	[1] = 'DEBUG',
	[2] = 'INFO',
	[3] = 'WARN',
	[4] = 'ERROR',
	[5] = 'OFF',
}

local minimun_level = vim.g.projects_nvim_config.log_level or vim.log.levels.WARN

---@type file*
local log_file = nil

local function open_log_file()
	local path = vim.g.projects_nvim_config.log_file or vim.fn.stdpath('log') .. '/projects.log'

	local file, err = io.open(path, 'a+')

	if not file then
		M.notify(string.format('Cannot open project.nvim log file: %s', err))
		return
	end

	if log_file then
		log_file:close()
	end

	log_file = file
end

---@param msg string
---@param level integer? One of the values of vim.log.levels
function M.log(msg, level)
	level = level or vim.log.levels.DEBUG
	if level < minimun_level then
		return
	end

	if not log_file then
		open_log_file()
	end

	log_file:write(
		string.format('%s - [%s] %s\n', vim.fn.strftime('%d-%m %H:%M:%S'), levels[level], msg)
	)
	log_file:flush()
end

return M
