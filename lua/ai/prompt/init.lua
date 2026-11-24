local M = {}

function M.coalesce(clauses)
	local ret = {}
	for i = 1, #clauses do
		local s = clauses[i]
		if type(s) == "string" and s ~= "" then
			ret[#ret + 1] = vim.trim(s)
		end
	end
	return table.concat(ret, "\n\n")
end

function M.clause(title, content)
	title = vim.trim(title or "")
	content = vim.trim(content or "")
	return ("<%s>\n%s\n</%s>"):format(title, content, title)
end

return M
