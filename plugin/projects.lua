local projects_completion = function(arglead)
	local project_list = require('projects').get_projects_info()
	local completion_list = {}
	for _, project in pairs(project_list) do
		if project.path:find(arglead) then
			table.insert(completion_list, project.path)
		end
	end
	return completion_list
end

vim.api.nvim_create_user_command('ProjectOpen', function(args)
	require('projects').open(args.args)
end, { nargs = 1, complete = projects_completion })

vim.api.nvim_create_user_command('ProjectClose', function(_)
	require('projects').close()
end, { nargs = 0 })

vim.api.nvim_create_user_command('ProjectCreate', function(_)
	require('projects').create()
end, { nargs = 0 })

vim.api.nvim_create_user_command('ProjectEdit', function(args)
	require('projects').edit(args.args)
end, { nargs = 1, complete = projects_completion })

vim.api.nvim_create_user_command('ProjectDelete', function(args)
	require('projects').delete(args.args)
end, { nargs = 1, complete = projects_completion })
