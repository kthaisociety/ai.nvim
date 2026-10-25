local M = {}

---Replace the marked region with an agent's output.
---@param lines string[] Agent output, split on newlines
---@param buffer integer The buffer the selection came from
---@param mark vim.api.keyset.get_extmark_item_by_id Result of nvim_buf_get_extmark_by_id
---@param mode "v"|"V"|"\22" Visual mode captured at request time
---@return boolean ok True if the replacement was applied
function M.set_lines(lines, buffer, mark, mode)
  if mode == "v" then
    vim.api.nvim_buf_set_text(buffer, mark[1], mark[2], mark[3].end_row, mark[3].end_col, lines)
  elseif mode == "V" then
    vim.api.nvim_buf_set_lines(buffer, mark[1], mark[3].end_row + 1, false, lines)
  else -- visual block
    local line_ranges = vim.fn.getregionpos({ buffer, mark[1] + 1, mark[2] + 1, 0 },
      { buffer, mark[3].end_row + 1, mark[3].end_col, 0 }, { type = mode })
    if #line_ranges ~= #lines then
      -- TODO: How do we handle these cases?
      -- What do we call our plugin? KTHAIS-nvim-plugin? ai-nvim?
      vim.notify("KTHAIS.set_lines: Number of lines set does not match number of lines in selection", vim.log.levels
        .WARN)
      return false
    end
    for i = 1, math.min(#line_ranges, #lines) do -- Min of selected text rows and agent returned rows
      local start_col = line_ranges[i][1][3] - 1
      local end_col = line_ranges[i][2][3]
      local row = line_ranges[i][1][2] - 1
      vim.api.nvim_buf_set_text(buffer, row, start_col, row, end_col, { lines[i] })
    end
  end
  return true
end

return M
