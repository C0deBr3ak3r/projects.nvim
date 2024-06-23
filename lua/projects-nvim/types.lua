---@class ProjectOpts
---@field projects ProjectConfig[]
---@field log_file string Absolute path to log file
---@field log_level integer Minimum level to write into log, one of vim.log.levels
---@field detect_git boolean? Detect when is inside a git repo and prompt to add the project
---@field template? ProjectInfo Template for a new project

---@class ProjectConfig
---@field path string Path to project root directory
---@field on_unload? fun(buffers: integer[]) Function to load onUnload
---@field enable_tasks? boolean Need overseer.nvim
---@field use_sessions? boolean Need ressesion.nvim
---@field always_trust? boolean Insecure feature

---@class ProjectInfo
---@field name string
---@field author string
---@field repo string
---@field license string
---@field description string

---@class ProjectSpec
---@field config ProjectConfig
---@field info ProjectInfo
