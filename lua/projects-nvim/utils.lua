local M = {}

local levels = {
	[0] = 'TRACE',
	[1] = 'DEBUG',
	[2] = 'INFO',
	[3] = 'WARN',
	[4] = 'ERROR',
	[5] = 'OFF',
}

---@type file*
local log_file = nil

function M.set_log_file(path)
	if log_file then
		vim.notify("Cannot set a new log file after it's already open", vim.log.levels.ERROR)
		return
	end

	local file, err = io.open(path, 'a+')

	if not file then
		vim.notify(string.format('Cannot open project.nvim log file: %s', err))
		return
	end

	log_file = file
end

---@param msg	string
---@param level	integer? One of the values of vim.log.levels
function M.log(msg, level)
	level = level or vim.log.levels.TRACE
	if level < (vim.g.projects_nvim_config.log_level or vim.log.levels.WARN) then
		return
	end

	if level >= (vim.g.projects_nvim_config.notify_level or vim.log.levels.INFO) then
		vim.notify(msg, level)
		return
	end

	log_file:write(
		string.format('%s - [%s] %s\n', vim.fn.strftime('%d-%m %H:%M:%S'), levels[level], msg)
	)
	log_file:flush()
end

return M
