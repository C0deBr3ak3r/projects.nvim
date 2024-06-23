local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local state = require('telescope.state')
local telescope_actions = require('telescope.actions')
local telescope_actions_state = require('telescope.actions.state')
local conf = require('telescope.config').values

local actions = require('telescope._extensions.projects.actions')

local function generate_entries()
	require('projects-nvim.loader').add_projects(vim.g.projects_nvim_config.projects or {})

	local entries = {}

	for path, spec in pairs(require('projects-nvim.loader').db) do
		table.insert(entries, {
			path = path,
			info = spec.info,
		})
	end

	return entries
end

local default_mappings = {
	i = {
		['<CR>'] = actions.open_project,
	},
	v = {
		['<CR>'] = actions.open_project,
		['gx'] = actions.open_project_repo,
		['ge'] = actions.edit_project,
		['d'] = actions.delete_project,
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
						ordinal = entry.info.name
							.. ' '
							.. entry.path
							.. ' '
							.. entry.info.description,
					}
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = 'Project Information',
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
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 0, 0, {
						end_col = #preview[1],
						hl_group = 'ProjectTitle',
					})
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 2, 8, {
						end_col = #preview[3],
						hl_group = 'ProjectAuthor',
					})
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 3, 18, {
						end_col = #preview[4],
						hl_group = 'ProjectLicense',
					})
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 4, 4, {
						end_col = #preview[5],
						hl_group = 'ProjectRepo',
					})
					vim.api.nvim_buf_set_extmark(self.state.bufnr, ns, 6, 0, {
						end_line = 7 + #description,
						hl_group = 'ProjectDescription',
					})
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				opts.mappings = opts.mappings or {}
				for _, mode in pairs({ 'i', 'n' }) do
					for key, action in pairs(default_mappings[mode] or {}) do
						map(mode, key, action(prompt_bufnr))
					end
					for key, action in pairs(opts.mappings[mode] or {}) do
						map(mode, key, action(prompt_bufnr))
					end
				end
				return true
			end,
			sorter = conf.generic_sorter(opts),
		})
		:find()
end

return telescope.register_extension({
	exports = {
		projects = projects,
	},
})
