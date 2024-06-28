local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values

local actions = require('telescope._extensions.projects.actions')

local function generate_entries()
	-- Be sure to add entries to the db in case of lazy loading
	require('projects.loader').add_projects(vim.g.projects_nvim_config.projects or {})

	local entries = {}

	for path, spec in pairs(require('projects.loader').get_projects_info()) do
		table.insert(entries, {
			path = vim.fs.normalize(path, {}),
			info = spec,
		})
	end

	return entries
end

local config = {}
local defaults = {
	mappings = {
		i = {
			['<CR>'] = actions.open_project,
		},
		n = {
			['<CR>'] = actions.open_project,
			['gx'] = actions.open_project_repo,
			['ge'] = actions.edit_project,
			['d'] = actions.delete_project,
		},
	},
}

vim.api.nvim_set_hl(0, 'ProjectTitle', {
	default = true,
	link = '@markup.heading.1',
})
vim.api.nvim_set_hl(0, 'ProjectDescription', {
	default = true,
	link = '@markup.quote',
})
vim.api.nvim_set_hl(0, 'ProjectRepo', {
	default = true,
	link = '@markup.link',
})
vim.api.nvim_set_hl(0, 'ProjectAuthor', {
	default = true,
	link = '@markup.label',
})
vim.api.nvim_set_hl(0, 'ProjectLicense', {
	default = true,
	link = '@markup.label',
})

local function projects(opts)
	opts = vim.tbl_deep_extend('force', config, opts or {})
	pickers
		.new(opts, {
			prompt_title = 'Find Projects',
			results_title = 'Projects',
			finder = finders.new_table({
				results = generate_entries(),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.info.name .. ': ' .. vim.fn.fnamemodify(entry.path, ':~'),
						ordinal = entry.info.name .. ' ' .. entry.path .. ' ' .. entry.info.description,
					}
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = 'Project Information',
				---@param entry ProjectsTelescopeEntry
				define_preview = function(self, entry)
					local preview = {
						entry.value.info.name,
						'',
						'Made by: ' .. entry.value.info.author,
						'Distributed under: ' .. entry.value.info.license,
						'At: ' .. entry.value.info.repo,
						'',
					}
					local description = vim.split(entry.value.info.description, '\n')
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, preview)
					vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, description)

					local ns = vim.api.nvim_create_namespace('')
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, 'ProjectTitle', 0, 0, -1)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, 'ProjectAuthor', 2, 9, -1)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, 'ProjectLicense', 3, 19, -1)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, 'ProjectRepo', 4, 4, -1)
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 6, 0, {
						end_line = 7 + #description,
						hl_group = 'ProjectDescription',
					})
				end,
			}),
			attach_mappings = function(_, map)
				for _, mode in pairs({ 'i', 'n' }) do
					for key, action in pairs(opts.mappings[mode] or {}) do
						map(mode, key, action)
					end
				end
				return true
			end,
			sorter = conf.generic_sorter(opts),
		})
		:find()
end

return telescope.register_extension({
	setup = function(ext_conf, _)
		config = vim.tbl_deep_extend('force', defaults, ext_conf)
	end,
	exports = {
		projects = projects,
	},
})
