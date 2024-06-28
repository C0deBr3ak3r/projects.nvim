---@class ProjectsOpts
---@field projects		ProjectsConfig[]
---@field log_file?		string		 Absolute path to log file
---@field log_level?	integer		 Minimum level to write into log, one of vim.log.levels
---@field notify_level?	integer		 Minimum level to call vim.notify
---@field template?		ProjectsInfo Template for a new project

---@class ProjectsConfig
---@field path			string						 Path to project root directory
---@field files?		string[]					 Files to load when project is loaded
---@field on_load?		ProjectsLoadFunc | boolean	 Function to call when loading a project, set to false to disable it
---@field on_unload?	ProjectsUnloadFunc | boolean Function to call when unloading a project, set to false to disable it

---@alias ProjectsLoadFunc fun(config: ProjectsConfig, info:ProjectsInfo):boolean, any
---@alias ProjectsUnloadFunc fun(project:ProjectsLoaded):boolean

---@class ProjectsInfo
---@field name			string
---@field description	string
---@field author		string
---@field repo			string
---@field license		string
