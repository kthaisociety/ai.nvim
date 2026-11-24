local M = {}

---@param buf integer buffer id
---@return integer win_width Current window's text area width or minimum text area width
---for windows associated with buf
function M.text_area_width(buf)
	local cur = vim.api.nvim_get_current_win()
	local min
	for _, winfo in ipairs(vim.fn.getwininfo()) do
		if winfo.bufnr == buf then
			local width = winfo.width - winfo.textoff
			if winfo.winid == cur then
				-- If current window active, use it's width
				return width
			end
			min = min and math.min(min, width) or width
		end
	end
	if min then
		-- Use narrowest window width
		return min
	end
	-- Fallback
	local preferred_line_length = vim.bo[buf].textwidth
	if preferred_line_length > 0 then
		return preferred_line_length
	end
	return vim.o.columns -- screen width
end

---Wrap the text to lines of specified width
---Words use the visual width of characters (vim.api.nvim_strwidth).
---If any word is longer than width, it gets its own line
---Newlines in the text stay line breaks, blank lines included
---@param text string
---@param width integer
---@param max_lines integer?
---@return string[]
function M.wrap_to_lines(text, width, max_lines)
	width = math.max(width, 1)
	local lines = {}
	for _, paragraph in ipairs(vim.split(text, "\r?\n")) do
		local curr_width = 0
		for word in paragraph:gmatch("%S+") do
			if max_lines and #lines >= max_lines then
				return lines
			end
			local word_len = vim.api.nvim_strwidth(word)
			-- + 1 for the space between the two words
			if curr_width > 0 and curr_width + 1 + word_len <= width then
				lines[#lines] = lines[#lines] .. " " .. word
				curr_width = curr_width + 1 + word_len
			else
				-- the first word on a line goes on whatever its length
				table.insert(lines, word)
				curr_width = word_len
			end
		end
		if curr_width == 0 then
			-- a blank line in the text stays a blank line
			table.insert(lines, "")
		end
	end
	return lines
end

return M
